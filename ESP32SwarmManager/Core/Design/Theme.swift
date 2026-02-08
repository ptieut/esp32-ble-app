import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: 0x101622)
    static let card = Color(hex: 0x1E293B)
    static let surface = Color(hex: 0x1A2230)
    static let surfaceLight = Color(hex: 0x1C1F27)
    static let primary = Color(hex: 0x135BEC)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x94A3B8)
    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xEAB308)
    static let error = Color(hex: 0xEF4444)
    static let border = Color(hex: 0x3B4354)
    static let borderSubtle = Color.white.opacity(0.05)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner Radii
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Signal Colors
    static func signalColor(rssi: Int) -> Color {
        if rssi > -50 { return success }
        if rssi > -70 { return warning }
        return error
    }

    static func signalIcon(rssi: Int) -> String {
        if rssi > -50 { return "wifi" }
        if rssi > -70 { return "wifi" }
        return "wifi.exclamationmark"
    }

    // MARK: - Status Colors
    static func statusColor(_ status: DeviceStatus) -> Color {
        switch status {
        case .active: return success
        case .idle: return warning
        case .lowBattery: return error
        case .flashing: return Color.orange
        case .success: return success
        case .failed: return error
        case .queued: return textSecondary
        case .transferring: return primary
        }
    }

    // MARK: - Battery
    static func batteryColor(level: Int) -> Color {
        if level > 20 { return success }
        return error
    }

    static func batteryIcon(level: Int) -> String {
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
