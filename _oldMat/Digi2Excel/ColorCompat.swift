import SwiftUI
import AppKit

/// macOS 10.15-safe color from NSColor
func systemColor(_ nsColor: NSColor) -> Color {
    if #available(macOS 12.0, *) {
        return Color(nsColor)
    } else {
        // Fallback: convert NSColor to RGBA components
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return Color.white
        }
        return Color(
            red: Double(rgbColor.redComponent),
            green: Double(rgbColor.greenComponent),
            blue: Double(rgbColor.blueComponent),
            opacity: Double(rgbColor.alphaComponent)
        )
    }
}
