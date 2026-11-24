import SwiftUI

struct ContentView: View {

    @EnvironmentObject var vpn: VPNManager

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 60)

                Spacer()

                powerCard

                Spacer()

                infoCard
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                Color(hex: "0a0a1a"),
                Color(hex: "0d1b3e"),
                Color(hex: "0a0a1a")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(starField)
    }

    private var starField: some View {
        GeometryReader { geo in
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat(i * 47 % Int(geo.size.width)),
                        y: CGFloat(i * 83 % Int(geo.size.height))
                    )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("⭐️ STAR VPN ⭐️")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "FFD700"), .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("PUBG • BGMI • KR FIREWALL")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "FFD700").opacity(0.7))
                .tracking(2)
        }
    }

    // MARK: - Power card

    private var powerCard: some View {
        VStack(spacing: 28) {

            // Status label
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor, radius: 4)

                Text(vpn.status.label)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor)
            }

            // Power button
            Button(action: { vpn.toggle() }) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: vpn.status.isActive
                                    ? [Color(hex: "00ff88"), Color(hex: "00cc66")]
                                    : [Color(hex: "334466"), Color(hex: "223355")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)
                        .shadow(
                            color: vpn.status.isActive ? Color(hex: "00ff88").opacity(0.5) : .clear,
                            radius: 20
                        )

                    // Inner circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: vpn.status.isActive ? "0d2b1f" : "111827"),
                                    Color(hex: vpn.status.isActive ? "091a12" : "0a0f1a")
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 148, height: 148)

                    // Power icon
                    Image(systemName: "power")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: vpn.status.isActive
                                    ? [Color(hex: "00ff88"), Color(hex: "00cc66")]
                                    : [Color(hex: "4a6080"), Color(hex: "2a3a50")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: vpn.status.isActive ? Color(hex: "00ff88").opacity(0.8) : .clear,
                            radius: 12
                        )
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(vpn.status == .connecting ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatWhile(vpn.status == .connecting, autoreverses: true), value: vpn.status)

            // Action button
            Button(action: { vpn.toggle() }) {
                Text(vpn.status.isActive ? "Turn Off" : "Turn On")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(vpn.status.isActive ? Color(hex: "00ff88") : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                vpn.status.isActive
                                    ? Color(hex: "00ff88").opacity(0.15)
                                    : Color(hex: "1a3a6e")
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        vpn.status.isActive
                                            ? Color(hex: "00ff88").opacity(0.4)
                                            : Color(hex: "2a4a8e").opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .buttonStyle(.plain)

            if let error = vpn.lastError {
                Text(error)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "ff4444"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to use")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "FFD700"))

            VStack(alignment: .leading, spacing: 8) {
                infoRow("1", "Tap Turn On")
                infoRow("2", "Allow VPN configuration if prompted")
                infoRow("3", "Wait for Connected")
                infoRow("4", "Open PUBG / BGMI")
            }

            Divider().overlay(Color.white.opacity(0.1))

            Text("Filters PUBG Mobile · BGMI · KR — blocks anti-cheat telemetry, allows game servers.")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func infoRow(_ num: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(num)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "FFD700"))
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color(hex: "FFD700").opacity(0.15)))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.7))
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch vpn.status {
        case .connected:     return Color(hex: "00ff88")
        case .connecting:    return Color(hex: "FFD700")
        case .disconnecting: return Color(hex: "ff8800")
        case .off:           return Color(hex: "445566")
        }
    }
}

// MARK: - Hex color init

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Animation repeat helper

extension Animation {
    func repeatWhile(_ condition: Bool, autoreverses: Bool = true) -> Animation {
        condition ? self.repeatForever(autoreverses: autoreverses) : self
    }
}
