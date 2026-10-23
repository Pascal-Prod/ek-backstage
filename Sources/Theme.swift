import AppKit
import SwiftUI

/// Couleurs de la charte Ema Krusi 2026.
enum Theme {
    static let brunChocolat = Color(hex: 0x2A211D)
    static let creme = Color(hex: 0xF6EFE4)
    static let ivoire = Color(hex: 0xFCF8F1)
    static let saumon = Color(hex: 0xE8A98E)

    /// Monogramme EK crème (Design System Ema Krusi 2026), embarqué dans l'app.
    static let monogramme: NSImage? = Bundle.main
        .url(forResource: "monogramme-creme", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0) }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
