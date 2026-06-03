import AppKit
import SwiftUI

/// Borderless floating panel that can take keyboard focus (for inline editing)
/// without stealing it from other apps when you just click checkboxes.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var panel: FloatingPanel!
    private var statusItem: NSStatusItem!
    private let store = GoalsStore()
    /// The pinned corner — the panel grows/shrinks down-left from here.
    private var topRight: NSPoint = .zero

    func applicationDidFinishLaunching(_ notification: Notification) {
        Theme.registerFonts()
        NSApp.setActivationPolicy(.accessory) // no Dock icon — it's a widget

        let root = GoalsPanelView(store: store)
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { [weak self] size in
                self?.contentSizeChanged(to: size)
            }
        let hosting = NSHostingView(rootView: AnyView(root))

        panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isFloatingPanel = true
        panel.level = .floating                       // over je andere apps heen
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.delegate = self

        // Pin top-right: 22px from the right edge, 16px under the menu bar
        // (the prototype's top: 44px / right: 22px with a 28px menu bar).
        if let screen = NSScreen.main {
            let vis = screen.visibleFrame
            topRight = NSPoint(x: vis.maxX - 22, y: vis.maxY - 16)
        }
        repositionToPin()
        panel.orderFrontRegardless()

        setUpStatusItem()
    }

    /// Keep the top-right corner fixed while the content height/width changes
    /// (collapse to pill, rows added/removed).
    private func contentSizeChanged(to size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        panel.setFrame(
            NSRect(x: topRight.x - size.width, y: topRight.y - size.height,
                   width: size.width, height: size.height),
            display: true
        )
    }

    func windowDidMove(_ notification: Notification) {
        // User dragged the panel: adopt the new pin point.
        guard !panel.inLiveResize else { return }
        let f = panel.frame
        let expected = NSPoint(x: topRight.x - f.width, y: topRight.y - f.height)
        if abs(f.origin.x - expected.x) > 1 || abs(f.origin.y - expected.y) > 1 {
            topRight = NSPoint(x: f.maxX, y: f.maxY)
        }
    }

    private func repositionToPin() {
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: topRight.x - size.width, y: topRight.y - size.height))
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "checklist", accessibilityDescription: "Goals of today")

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Toon / verberg paneel", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Stop Goals of today", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            repositionToPin()
            panel.orderFrontRegardless()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
