import SwiftUI
import CoreText

/// Twin Design System — colors & type (from colors_and_type.css)
enum Theme {
    // Raw palette
    static let brand = Color(hex: 0x5500ff)        // Twin purple (chosen accent)
    static let background = Color.white
    static let altBackground = Color(hex: 0xf7f9fa)
    static let lines = Color(hex: 0xe9ecf0)
    static let outlines = Color(hex: 0xc5ced6)
    static let disabled = Color(hex: 0x7a8a99)     // also "description"
    static let text = Color(hex: 0x1f2933)
    static let positive = Color(hex: 0x1dc239)
    static let negative = Color(hex: 0xeb5252)
    static let supportHover = Color.black.opacity(0.04)

    static let accent = brand                       // tweak: Accent = paars

    static let cardRadius: CGFloat = 16
    static let panelWidth: CGFloat = 300            // tweak: Dichtheid = ruim

    /// IBM Plex Sans, self-hosted. Registered at launch.
    static func plex(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "IBMPlexSans-Medium"
        case .semibold: name = "IBMPlexSans-SemiBold"
        case .bold: name = "IBMPlexSans-Bold"
        default: name = "IBMPlexSans"
        }
        return .custom(name, size: size)
    }

    static func registerFonts() {
        guard let dir = Bundle.module.url(forResource: "fonts", withExtension: nil) else { return }
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "ttf" } ?? []
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}
