import AppKit
import SwiftUI
import CoreText

/// Twin Design System — colors & type (from colors_and_type.css).
/// Every color has a light and a dark variant; the panel follows the
/// system appearance.
enum Theme {
    // Raw palette: (light, dark)
    static let brand = dynamic(0x5500ff, 0x7c3bff)        // Twin purple, brightened on dark
    static let background = dynamic(0xffffff, 0x222c35)
    static let altBackground = dynamic(0xf7f9fa, 0x1d252d)
    static let lines = dynamic(0xe9ecf0, 0x32404b)
    static let outlines = dynamic(0xc5ced6, 0x4a5a66)
    static let disabled = dynamic(0x7a8a99, 0x8d9dab)     // also "description"
    static let text = dynamic(0x1f2933, 0xf2f5f7)
    static let positive = dynamic(0x1dc239, 0x2bd148)
    static let negative = dynamic(0xeb5252, 0xf26666)
    static let supportHover = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.isDark
            ? NSColor.white.withAlphaComponent(0.07)
            : NSColor.black.withAlphaComponent(0.04)
    })

    static let accent = brand                       // tweak: Accent = paars

    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            NSColor(hex: appearance.isDark ? dark : light)
        })
    }

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

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}

extension NSAppearance {
    var isDark: Bool { bestMatch(from: [.aqua, .darkAqua]) == .darkAqua }
}
