// DeviceCapability.swift
// MudBug watchOS Client
//
// Detects premium hardware features for Ultra 2/3 and Watch Series 10/11.
// Unlocks easter-egg Liquid Glass effects on newest devices.

import WatchKit

enum DeviceCapability {
    /// True on Apple Watch Ultra 2/3 and Series 10/11 — newest hardware
    static var isPremiumDevice: Bool {
        let name = WKInterfaceDevice.current().name.lowercased()
        let model = WKInterfaceDevice.current().model.lowercased()

        // Ultra models
        if name.contains("ultra") || model.contains("ultra") { return true }

        // Series 10, 11
        let premiumKeywords = ["series 10", "series 11", "watch10", "watch11"]
        for kw in premiumKeywords {
            if name.contains(kw) || model.contains(kw) { return true }
        }

        // Fallback: check screen size — Ultra has 49mm (≥410pt width)
        // Series 10/11 46mm ≥ 396pt width
        let bounds = WKInterfaceDevice.current().screenBounds
        if bounds.width >= 176 { return true } // 44mm+ retina

        return false
    }

    /// True if the device has an always-on display (Series 5+, Ultra)
    static var hasAlwaysOn: Bool {
        // AOD is available on Series 5+ which is all modern watches
        return true
    }

    /// Screen diagonal category for layout scaling
    static var screenTier: ScreenTier {
        let w = WKInterfaceDevice.current().screenBounds.width
        if w >= 205 { return .ultra }   // 49mm Ultra
        if w >= 198 { return .large }   // 46mm
        if w >= 176 { return .medium }  // 42-44mm
        return .compact                  // 40-41mm
    }

    enum ScreenTier {
        case compact, medium, large, ultra
    }
}
