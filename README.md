# ⭐️ Star VPN ⭐️

PUBG Mobile · BGMI · KR packet firewall for iOS.  
Built with `NEPacketTunnelProvider`. No server. No data leaves your device.

---

## What it does

- Blocks anti-cheat telemetry ports and domains
- Blocks analytics, crash reporting, tracking hosts
- Allows actual game server ports (17500, 18100, 8013, 8080, 8086, 8088)
- Covers: PUBG Mobile Global, PUBG KR, BGMI

---

## Project structure

```
StarVPN/
├── StarVPN/                  ← Main app target
│   ├── StarVPNApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── StarVPN.entitlements
│
├── StarVPNExtension/         ← NEPacketTunnelProvider target
│   ├── PacketTunnelProvider.swift
│   ├── Info.plist
│   └── StarVPNExtension.entitlements
│
├── Shared/                   ← Shared between both targets
│   ├── FilterRules.swift
│   └── VPNManager.swift
│
├── codemagic.yaml
└── ExportOptions.plist
```

---

## Setup in Xcode (via Codemagic — no Mac needed)

### 1. Create GitHub repo
- Go to github.com on your iPhone browser
- Create new repo: `StarVPN`
- Upload all files keeping the folder structure

### 2. Create Xcode project manually (one-time setup)
You need someone with Xcode to create the `.xcodeproj` once, OR use the
GitHub Actions approach below which uses `xcodegen`.

### 3. Codemagic (free tier)
- Sign up at codemagic.io with GitHub
- Connect your repo
- It will pick up `codemagic.yaml` automatically
- Click Start Build

### 4. Bundle IDs to set
- Main app:  `com.starvpn.app`
- Extension: `com.starvpn.app.tunnel`

Both need the `com.apple.developer.networking.networkextension` entitlement
with `packet-tunnel-provider`.

### 5. Signing with ESign
- Download the unsigned `.ipa` from Codemagic artifacts
- Open ESign → import `.ipa` → sign with your certificate
- Install

---

## Important: NEPacketTunnelProvider entitlement

This entitlement **requires** either:
- An Apple Developer account ($99/yr) — official signing
- OR a certificate that already has this entitlement (enterprise cert, etc.)

If your ESign certificate does not have `packet-tunnel-provider` in its
entitlements, the VPN extension will fail to launch. Check your cert's
entitlements in ESign before building.

---

## Filter logic summary

| Target | Deny ports | Allow ports |
|--------|-----------|-------------|
| PUBG Global | 80,443,20371,18081,15692,8089,9081,10012,8085,9030,17000,19700,1670,19900,14545 | 17500,18100,8013,8080 |
| PUBG KR | same set | 17500 |
| BGMI | 80,443 + 50 additional ports | 17500,18100 |

Plus domain block list: `down.anticheatexpert.com`, `beacon.qq.com`,
`log.tbs.qq.com`, Firebase analytics, Adjust, AppsFlyer, Facebook Graph, etc.
