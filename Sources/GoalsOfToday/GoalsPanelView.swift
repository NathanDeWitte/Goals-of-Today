import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// The floating "Goals of today" panel — mix of prototype variants A (bold main
/// focus + eyebrow) and G (compact density), with the locked tweaks:
/// purple accent, progress footer, roomy density, top-right.
struct GoalsPanelView: View {
    enum Section { case main, side }

    @ObservedObject var store: GoalsStore
    @State private var editingID: UUID?
    @State private var addingTo: Section?
    @State private var draggingMain: Goal?
    @State private var justCopied = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            if store.collapsed {
                compactBody
            } else {
                body_
                footer   // progress footer only in the expanded view
            }
        }
        .frame(width: Theme.panelWidth)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.lines, lineWidth: 2)
        )
    }

    /// Shared by both modes; only the arrow flips (up = collapse, down = expand).
    private var titleBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
            Text("Goals of today")
                .font(Theme.plex(13, .semibold))
                .tracking(-0.13)
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            Text(shortDate())
                .font(Theme.plex(12, .medium))
                .foregroundStyle(Theme.disabled)
                .padding(.trailing, 2)
            IconButton(
                systemName: justCopied ? "checkmark" : "doc.on.doc",
                help: justCopied ? "Copied — paste into Slack" : "Copy goals to clipboard"
            ) { copyToClipboard() }
            IconButton(systemName: "chevron.up", help: store.collapsed ? "Expand" : "Collapse") {
                withAnimation(.easeOut(duration: 0.15)) { store.collapsed.toggle() }
            }
            .rotationEffect(.degrees(store.collapsed ? 180 : 0))
        }
        .padding(EdgeInsets(top: 11, leading: 14, bottom: 9, trailing: 12))
        .background(Theme.altBackground)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.lines).frame(height: 2) }
    }

    // MARK: - Compact body: all main goals, full row styling, no progress footer.

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.mains) { goal in
                goalRow(goal, prominent: true, deletable: false)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
    }

    private var body_: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Main focus", color: Theme.accent) { addingTo = .main }
                .padding(.top, 4)

            ForEach(store.mains) { goal in
                goalRow(goal, prominent: true, deletable: store.mains.count > 1)
                    // Drag to reorder — only meaningful with more than one main.
                    .opacity(draggingMain?.id == goal.id ? 0.4 : 1)
                    .onDrag {
                        draggingMain = goal
                        return NSItemProvider(object: goal.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: MainDropDelegate(item: goal, dragging: $draggingMain, store: store)
                    )
            }
            if addingTo == .main {
                AddField(prominent: true) { text in
                    addingTo = nil
                    store.addMain(text)
                }
            }

            sectionHeader("Side goals", color: Theme.disabled) { addingTo = .side }
                .padding(.top, 11)

            ForEach(store.sides) { goal in
                goalRow(goal, prominent: false, deletable: true)
            }
            if addingTo == .side {
                AddField(prominent: false) { text in
                    addingTo = nil
                    store.addSide(text)
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 10, trailing: 6))
    }

    private func sectionHeader(_ title: String, color: Color, onAdd: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.plex(10.5, .semibold))
                .tracking(0.55)
                .foregroundStyle(color)
            Spacer(minLength: 0)
            HeaderPlusButton(action: onAdd)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 1)
    }

    private func goalRow(_ goal: Goal, prominent: Bool, deletable: Bool) -> some View {
        GoalRow(
            goal: goal,
            prominent: prominent,
            deletable: deletable,
            allDone: store.allDone,
            editing: editingID == goal.id,
            onToggle: { store.toggle(goal.id) },
            onStartEdit: { editingID = goal.id },
            onCommit: { text in
                editingID = nil
                store.commit(goal.id, text: text)
            },
            onDelete: { store.delete(goal.id) }
        )
    }

    /// Copy today's goals as plain text so they can be pasted into Slack/mail.
    /// The icon flips to a checkmark for ~1.4s as confirmation.
    private func copyToClipboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(store.exportText, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) { justCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.2)) { justCopied = false }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if store.allDone {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("All done. Nice work.")
                        .font(Theme.plex(12.5, .semibold))
                }
                .foregroundStyle(Theme.positive)
                Spacer(minLength: 0)
                Text("\(store.streak + 1)-day streak")
                    .font(Theme.plex(12, .medium))
                    .foregroundStyle(Theme.disabled)
            } else {
                // Tweak: footer = voortgang (progress bar)
                ProgressBar(progress: store.progress)
                Text("\(store.doneCount)/\(store.total)")
                    .font(Theme.plex(12, .medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.disabled)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
        .background(Theme.altBackground)
        .overlay(alignment: .top) { Rectangle().fill(Theme.lines).frame(height: 2) }
    }

}

// MARK: - Pieces

private struct CheckBox: View {
    let done: Bool
    var large = false
    var allDone = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        let size: CGFloat = large ? 25 : 20
        let radius: CGFloat = large ? 7 : 6
        let fill = allDone ? Theme.positive : Theme.accent
        Button(action: action) {
            RoundedRectangle(cornerRadius: radius)
                .fill(done ? fill : Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .strokeBorder(done ? fill : (hovering ? Theme.disabled : Theme.outlines), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: large ? 12 : 10, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(done ? 1 : 0)
                        .scaleEffect(done ? 1 : 0.5)
                )
                .frame(width: size, height: size)
                .animation(.easeOut(duration: 0.12), value: done)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct GoalRow: View {
    let goal: Goal
    var prominent = false      // main focus: large checkbox, bold text
    var deletable = true       // false for the last remaining main focus
    let allDone: Bool
    let editing: Bool
    let onToggle: () -> Void
    let onStartEdit: () -> Void
    let onCommit: (String) -> Void
    let onDelete: () -> Void
    @State private var hoveringDelete = false

    var body: some View {
        HoverRow { hovering in
            HStack(alignment: .center, spacing: prominent ? 11 : 10) {
                CheckBox(done: goal.done, large: prominent, allDone: allDone, action: onToggle)
                EditableText(
                    text: goal.text,
                    font: prominent ? Theme.plex(15, .semibold) : Theme.plex(13),
                    lineSpacing: prominent ? 3 : 2.5,
                    done: goal.done,
                    editing: editing,
                    onStart: onStartEdit,
                    onCommit: onCommit
                )
                if deletable {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(hoveringDelete ? Theme.negative : Theme.disabled)
                            .frame(width: 22, height: 22)
                            .background(hoveringDelete ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .opacity(hovering || hoveringDelete ? 1 : 0)
                    .onHover { hoveringDelete = $0 }
                    .help("Delete")
                }
            }
            .padding(EdgeInsets(top: prominent ? 4 : 6, leading: 6, bottom: 6, trailing: 6))
            .background(hovering ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// Live-reorder drop target for main goals: as the dragged row hovers over
/// another main, it slides into that slot. `performDrop` just clears the drag
/// state — the reordering already happened in `dropEntered`.
private struct MainDropDelegate: DropDelegate {
    let item: Goal
    @Binding var dragging: Goal?
    let store: GoalsStore

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging.id != item.id,
              let from = store.mains.firstIndex(where: { $0.id == dragging.id }),
              let to = store.mains.firstIndex(where: { $0.id == item.id })
        else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            store.mains.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

/// Click-to-edit text — the SwiftUI equivalent of the prototype's contenteditable.
private struct EditableText: View {
    let text: String
    let font: Font
    let lineSpacing: CGFloat
    let done: Bool
    let editing: Bool
    let onStart: () -> Void
    let onCommit: (String) -> Void

    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if editing {
                TextField("", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(font)
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .onAppear {
                        draft = text
                        DispatchQueue.main.async { focused = true }
                    }
                    .onSubmit { onCommit(draft) }
                    .onExitCommand { onCommit(text) }
                    .onChange(of: focused) { _, isFocused in
                        if !isFocused { onCommit(draft) }
                    }
                    .padding(.horizontal, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Theme.accent, lineWidth: 2)
                            .padding(-1)
                    )
                    .padding(.horizontal, -3)
            } else {
                Text(text)
                    .font(font)
                    .lineSpacing(lineSpacing)
                    .strikethrough(done, color: Theme.disabled)
                    .foregroundStyle(done ? Theme.disabled : Theme.text)
                    .fixedSize(horizontal: false, vertical: true) // wrap long goals
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onStart)
                    .help("Click to edit")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AddField: View {
    var prominent = false
    let onCommit: (String) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: prominent ? 11 : 10) {
            RoundedRectangle(cornerRadius: prominent ? 7 : 6)
                .strokeBorder(Theme.outlines, lineWidth: 2)
                .frame(width: prominent ? 25 : 20, height: prominent ? 25 : 20)
            TextField("New goal, press enter", text: $draft)
                .textFieldStyle(.plain)
                .font(prominent ? Theme.plex(15, .semibold) : Theme.plex(13))
                .foregroundStyle(Theme.text)
                .focused($focused)
                .onSubmit { onCommit(draft) }
                .onExitCommand { onCommit("") }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { onCommit(draft) }
                }
        }
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.accent, lineWidth: 2)
        )
        .background(MakeWindowKey())
        .onAppear {
            // Defer one runloop: focus set synchronously in onAppear is
            // dropped while the field is still being inserted.
            DispatchQueue.main.async { focused = true }
        }
    }
}

/// The panel is a non-activating NSPanel: clicking the + button doesn't make
/// it key, so a freshly added text field can't receive keystrokes. This makes
/// the window key the moment the add-field appears.
private struct MakeWindowKey: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.makeKey()
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Add button at the far right of a section header: white + on a purple circle.
private struct HeaderPlusButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Theme.accent, in: Circle())
                .opacity(hovering ? 1 : 0.85)
                .scaleEffect(hovering ? 1.1 : 1)
                .animation(.easeOut(duration: 0.12), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Add a goal")
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.lines)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(0, geo.size.width * progress))
                    .animation(.easeOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity)
    }
}

private struct IconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(hovering ? Theme.text : Theme.disabled)
                .frame(width: 24, height: 24)
                .background(hovering ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
    }
}

/// Row wrapper that tracks hover state.
private struct HoverRow<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content
    @State private var hovering = false

    var body: some View {
        content(hovering)
            .onHover { hovering = $0 }
    }
}
