import SwiftUI

extension Color {
    static let theme = ColorTheme()
    
    struct ColorTheme {
        // Berdasarkan hex di image_8745dd.png
        let primaryGreen = Color(hex: "#4AB855")
        let lightGreen   = Color(hex: "#E8FBCB")
        let black        = Color(hex: "#000000")
        let white        = Color(hex: "#FFFFFF")
        
        // Semantic colors untuk kemudahan navigasi
        let background   = Color(hex: "#F5F5F5") // Warna abu-abu soft di background HP
        let accent       = Color(hex: "#4AB855")
    }
}

// Helper untuk menggunakan Hex Code
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
