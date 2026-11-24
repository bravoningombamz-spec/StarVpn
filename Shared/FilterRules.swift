import Foundation

// MARK: - Rule action

enum RuleAction: String, Codable {
    case allow
    case deny
    case none
}

// MARK: - Filter rule

struct FilterRule {
    let host: String?       // nil means wildcard (*)
    let port: Int?          // nil means any (-1 in JSON)
    let proto: String
    let action: RuleAction
}

// MARK: - Hard-coded PUBG / BGMI / KR ruleset parsed from RYNOX filter

struct FirewallRules {

    // Ports to DENY for PUBG Mobile (com.tencent.ig) and KR (com.pubg.krmobile)
    static let pubgDenyPorts: Set<Int> = [
        80, 443, 20371, 18081, 15692, 8089, 9081, 10012,
        8085, 9030, 17000, 19700, 1670, 19900, 14545,
        8088, 8086, 8080, 8013, 18100, 17500,
        // KR variant
        8080, 8013, 8085, 18081, 15692, 20371, 8088, 8086, 10012
    ]

    // Ports to ALLOW for PUBG Mobile
    static let pubgAllowPorts: Set<Int> = [8088, 8086, 17500, 8080, 8013, 18100]

    // Domains to DENY regardless of port
    static let pubgDenyHosts: Set<String> = [
        "down.anticheatexpert.com",
        "log.tbs.qq.com",
        "otheve.beacon.qq.com",
        "beacon.qq.com",
        "stat.game.qq.com",
        "mi.gdt.qq.com",
        "gcloud.pstatp.com",
        "ssl.pstatp.com",
        "log.snssdk.com",
        "analytics.mintegral.com",
        "log.upstream.im",
        "api2.branch.io",
        "cdn.branch.io",
        "device.branch.io",
        "graph.facebook.com",
        "crashlogs.pstatp.com",
        "metrics.itunes.apple.com",
        "xp.apple.com",
        "fcmtoken.googleapis.com",
        "clientmetrics-pa.googleapis.com",
        "app-measurement.com",
        "app.adjust.com",
        "impression.appsflyer.com"
    ]

    // BGMI (com.pubg.imobile) deny ports
    static let bgmiDenyPorts: Set<Int> = [
        80, 443, 8080, 8013, 8085, 8086, 8088, 8089,
        9030, 9081, 10001, 10002, 10005, 10012, 10015,
        10020, 10032, 10050, 10080, 10100, 10112, 10240,
        10300, 10443, 10500, 10880, 11000, 11443, 12000,
        12080, 13000, 14545, 15692, 15693, 17000, 17001,
        17002, 18080, 18081, 18082, 18085, 19000, 19700,
        19900, 20003, 20004, 20005, 20371, 20372, 29900,
        30000, 31114, 35000, 65010, 65050, 1670
    ]

    // BGMI allow ports
    static let bgmiAllowPorts: Set<Int> = [17500, 18100]

    // Bundle IDs we care about (iOS uses bundle ID, not Android pkg)
    static let pubgBundleIDs: Set<String> = [
        "com.tencent.ig",           // PUBG Mobile Global
        "com.pubg.krmobile",        // PUBG KR
        "com.pubg.imobile"          // BGMI
    ]
}

// MARK: - Decision engine

enum TrafficDecision {
    case allow
    case deny
}

struct RuleEngine {

    /// Evaluate whether a flow should be allowed or denied.
    /// On iOS NEFilterDataProvider we get the remote hostname and port.
    static func evaluate(host: String, port: Int) -> TrafficDecision {

        // Block known anti-cheat / telemetry domains globally
        for denied in FirewallRules.pubgDenyHosts {
            // Strip port suffix if present in stored host
            let storedHost = denied.components(separatedBy: "/").first ?? denied
            if host.hasSuffix(storedHost) { return .deny }
        }

        // Port 17500 and 18100 are game server — always allow
        if FirewallRules.pubgAllowPorts.contains(port) ||
           FirewallRules.bgmiAllowPorts.contains(port) {
            return .allow
        }

        // Deny known bad ports
        if FirewallRules.pubgDenyPorts.contains(port) ||
           FirewallRules.bgmiDenyPorts.contains(port) {
            return .deny
        }

        return .allow
    }
}
