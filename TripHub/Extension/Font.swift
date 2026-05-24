import SwiftUI

extension Font {
    // Fungsi custom font Helvetica yang bisa diatur ukurannya
    static func helveticaCustom(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Helvetica", size: size).weight(weight)
    }
    
    // Shortcut untuk gaya yang sering dipakai di image_8745dd.png
    static let headerLarge = helveticaCustom(size: 34, weight: .bold)
    static let cardTitle = helveticaCustom(size: 18, weight: .semibold)
}
