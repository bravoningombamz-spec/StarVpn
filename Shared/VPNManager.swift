import Foundation
import NetworkExtension

// MARK: - VPN tunnel configuration constants

enum VPNConfig {
    static let tunnelBundleID = "com.starvpn.app.tunnel"
    static let displayName    = "⭐️ Star VPN"
    static let serverAddress  = "127.0.0.1"
}

// MARK: - VPN status wrapper

enum VPNStatus {
    case off, connecting, connected, disconnecting

    init(_ ne: NEVPNStatus) {
        switch ne {
        case .connected:      self = .connected
        case .connecting:     self = .connecting
        case .disconnecting:  self = .disconnecting
        default:              self = .off
        }
    }

    var label: String {
        switch self {
        case .off:           return "VPN OFF"
        case .connecting:    return "Connecting..."
        case .connected:     return "Connected"
        case .disconnecting: return "Disconnecting..."
        }
    }

    var isActive: Bool { self == .connected || self == .connecting }
}

// MARK: - Manager

@MainActor
final class VPNManager: ObservableObject {

    static let shared = VPNManager()

    @Published var status: VPNStatus = .off
    @Published var lastError: String?

    private var manager: NETunnelProviderManager?
    private var observer: NSObjectProtocol?

    private init() {
        Task { await load() }
    }

    // MARK: Load / create tunnel config

    func load() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            manager = managers.first ?? NETunnelProviderManager()
            updateStatus()
            observe()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: Toggle

    func toggle() {
        Task {
            if status.isActive {
                stop()
            } else {
                await start()
            }
        }
    }

    // MARK: Start

    private func start() async {
        do {
            try await configure()
            try manager?.connection.startVPNTunnel()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: Stop

    func stop() {
        manager?.connection.stopVPNTunnel()
    }

    // MARK: Configure tunnel provider

    private func configure() async throws {
        guard let mgr = manager else { return }

        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = VPNConfig.tunnelBundleID
        proto.serverAddress = VPNConfig.serverAddress
        proto.providerConfiguration = [:]

        mgr.protocolConfiguration = proto
        mgr.localizedDescription = VPNConfig.displayName
        mgr.isEnabled = true

        try await mgr.saveToPreferences()
        try await mgr.loadFromPreferences()
    }

    // MARK: Status update

    private func updateStatus() {
        guard let conn = manager?.connection else {
            status = .off
            return
        }
        status = VPNStatus(conn.status)
    }

    private func observe() {
        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateStatus() }
        }
    }
}
