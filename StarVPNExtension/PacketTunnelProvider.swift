import NetworkExtension
import Foundation

// MARK: - Packet Tunnel Provider

final class PacketTunnelProvider: NEPacketTunnelProvider {

    private var packetLoop: Task<Void, Never>?

    // MARK: Start

    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let settings = buildTunnelSettings()

        setTunnelNetworkSettings(settings) { error in
            if let error {
                completionHandler(error)
                return
            }
            self.packetLoop = Task { await self.readPackets() }
            completionHandler(nil)
        }
    }

    // MARK: Stop

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        packetLoop?.cancel()
        packetLoop = nil
        completionHandler()
    }

    // MARK: Tunnel network settings

    private func buildTunnelSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        // Fake TUN interface — we don't actually route through a remote server
        let ipv4 = NEIPv4Settings(addresses: ["192.168.99.1"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4

        let ipv6 = NEIPv6Settings(addresses: ["fd00::1"], networkPrefixLengths: [64])
        ipv6.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6

        // DNS passthrough — use device's default
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])

        // No MTU override — let the OS pick
        return settings
    }

    // MARK: Packet read loop

    private func readPackets() async {
        while !Task.isCancelled {
            await withCheckedContinuation { continuation in
                packetFlow.readPackets { dataArray, protocolArray in
                    var outbound: [Data] = []
                    var outboundProto: [NSNumber] = []

                    for (data, proto) in zip(dataArray, protocolArray) {
                        if self.shouldAllow(packet: data, protocol: proto.int32Value) {
                            outbound.append(data)
                            outboundProto.append(proto)
                        }
                        // Dropped packets are simply not forwarded — deny effect
                    }

                    if !outbound.isEmpty {
                        self.packetFlow.writePackets(outbound, withProtocols: outboundProto)
                    }

                    continuation.resume()
                }
            }
        }
    }

    // MARK: Packet inspection

    private func shouldAllow(packet: Data, protocol proto: Int32) -> Bool {
        guard packet.count >= 20 else { return true }

        // AF_INET = 2, AF_INET6 = 30
        let isIPv4 = (proto == AF_INET)
        let isIPv6 = (proto == AF_INET6)

        guard isIPv4 || isIPv6 else { return true }

        let destPort: Int
        let destHost: String

        if isIPv4 {
            guard let (host, port) = extractIPv4(packet: packet) else { return true }
            destHost = host
            destPort = port
        } else {
            guard let (host, port) = extractIPv6(packet: packet) else { return true }
            destHost = host
            destPort = port
        }

        let decision = RuleEngine.evaluate(host: destHost, port: destPort)
        return decision == .allow
    }

    // MARK: IPv4 header parsing

    private func extractIPv4(packet: Data) -> (String, Int)? {
        guard packet.count >= 20 else { return nil }

        let ihl = Int(packet[0] & 0x0F) * 4
        let proto = packet[9]

        // TCP = 6, UDP = 17
        guard proto == 6 || proto == 17 else { return nil }
        guard packet.count >= ihl + 4 else { return nil }

        // Destination IP
        let d0 = packet[16], d1 = packet[17], d2 = packet[18], d3 = packet[19]
        let destIP = "\(d0).\(d1).\(d2).\(d3)"

        // Destination port (bytes 2-3 of transport header)
        let portHi = Int(packet[ihl + 2])
        let portLo = Int(packet[ihl + 3])
        let destPort = (portHi << 8) | portLo

        return (destIP, destPort)
    }

    // MARK: IPv6 header parsing

    private func extractIPv6(packet: Data) -> (String, Int)? {
        guard packet.count >= 40 else { return nil }

        let nextHeader = packet[6]
        // TCP = 6, UDP = 17
        guard nextHeader == 6 || nextHeader == 17 else { return nil }
        guard packet.count >= 44 else { return nil }

        // Destination address bytes 24-39
        let destBytes = packet[24..<40]
        let groups = stride(from: 0, to: 16, by: 2).map { i -> String in
            String(format: "%02x%02x", destBytes[destBytes.startIndex + i], destBytes[destBytes.startIndex + i + 1])
        }
        let destIP = groups.joined(separator: ":")

        let portHi = Int(packet[42])
        let portLo = Int(packet[43])
        let destPort = (portHi << 8) | portLo

        return (destIP, destPort)
    }
}
