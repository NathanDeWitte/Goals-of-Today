import AppKit
import ServiceManagement
import SwiftUI

/// Borderless floating panel that can take keyboard focus (for inline editing)
/// without stealing it from other apps when you just click checkboxes.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
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
        setUpMainMenu()
        autoRegisterLoginItem()
    }

    /// The app has no visible menu bar (LSUIElement), but keyboard shortcuts
    /// are routed through the main menu — without an Edit menu, ⌘C/⌘V/⌘X/⌘A
    /// and undo/redo do nothing in the text fields.
    private func setUpMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Goals of today",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        mainMenu.addItem(editItem)

        NSApp.mainMenu = mainMenu
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
        menu.delegate = self
        let toggleItem = NSMenuItem(title: "Show / hide panel", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        if isBundled {
            let loginItem = NSMenuItem(title: "Start at login", action: #selector(toggleLoginItem), keyEquivalent: "")
            loginItem.target = self
            menu.addItem(loginItem)
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Goals of today", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    // MARK: - Login item (requires a real .app bundle, see `make bundle`)

    /// True when running from a proper bundle (not `swift run`).
    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    /// Register as login item once, on the first launch from a bundle.
    /// After that the user is in control (menu toggle / System Settings).
    private func autoRegisterLoginItem() {
        guard isBundled else { return }
        let status = SMAppService.mainApp.status
        NSLog("GoalsOfToday login item status: \(status.rawValue)") // 0=notRegistered 1=enabled 2=requiresApproval 3=notFound
        let didOffer = "didAutoRegisterLoginItem"
        guard !UserDefaults.standard.bool(forKey: didOffer) else { return }
        UserDefaults.standard.set(true, forKey: didOffer)
        // An unregistered main app reports .notFound, not .notRegistered.
        if status != .enabled && status != .requiresApproval {
            do {
                try SMAppService.mainApp.register()
                NSLog("GoalsOfToday registered as login item")
            } catch {
                NSLog("GoalsOfToday login item registration failed: \(error)")
            }
        }
    }

    /// Reflect the current login-item status as a checkmark when the menu opens.
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard isBundled,
              let item = menu.items.first(where: { $0.action == #selector(toggleLoginItem) })
        else { return }
        item.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Login item toggle failed: \(error)")
        }
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
