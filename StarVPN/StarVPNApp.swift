import SwiftUI

@main
struct StarVPNApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(VPNManager.shared)
        }
    }
}
