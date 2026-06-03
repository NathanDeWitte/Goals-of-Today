import SwiftUI

/// The floating "Goals of today" panel — mix of prototype variants A (bold main
/// focus + eyebrow) and G (compact density), with the locked tweaks:
/// purple accent, progress footer, roomy density, top-right.
struct GoalsPanelView: View {
    @ObservedObject var store: GoalsStore
    @State private var editingID: UUID?
    @State private var adding = false

    var body: some View {
        Group {
            if store.collapsed {
                pill
            } else {
                panel
            }
        }
        .environment(\.colorScheme, .light)
    }

    // MARK: - Expanded panel

    private var panel: some View {
        VStack(spacing: 0) {
            titleBar
            body_
            footer
        }
        .frame(width: Theme.panelWidth)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.lines, lineWidth: 2)
        )
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
            Text("Goals of today")
                .font(Theme.plex(13, .semibold))
                .tracking(-0.13)
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            Text(dutchShortDate())
                .font(Theme.plex(12, .medium))
                .foregroundStyle(Theme.disabled)
                .padding(.trailing, 2)
            IconButton(systemName: "chevron.up", help: "Inklappen") {
                withAnimation(.easeOut(duration: 0.15)) { store.collapsed = true }
            }
        }
        .padding(EdgeInsets(top: 11, leading: 14, bottom: 9, trailing: 12))
    }

    private var body_: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Main focus", color: Theme.accent)
                .padding(.top, 4)

            mainRow

            sectionHeader("Side goals", color: Theme.disabled)
                .padding(.top, 11)

            ForEach(store.sides) { goal in
                SideRow(
                    goal: goal,
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

            addRow
                .padding(.top, 2)
        }
        .padding(EdgeInsets(top: 0, leading: 6, bottom: 10, trailing: 6))
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title.uppercased())
            .font(Theme.plex(10.5, .semibold))
            .tracking(0.55)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.bottom, 1)
    }

    private var mainRow: some View {
        HoverRow { hovering in
            HStack(alignment: .center, spacing: 11) {
                CheckBox(done: store.main.done, large: true, allDone: store.allDone) {
                    store.toggleMain()
                }
                EditableText(
                    text: store.main.text,
                    font: Theme.plex(15, .semibold),
                    lineSpacing: 3,
                    done: store.main.done,
                    editing: editingID == store.main.id,
                    onStart: { editingID = store.main.id },
                    onCommit: { text in
                        editingID = nil
                        store.commit(store.main.id, text: text)
                    }
                )
            }
            .padding(EdgeInsets(top: 4, leading: 6, bottom: 6, trailing: 6))
            .background(hovering ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var addRow: some View {
        Group {
            if adding {
                AddField { text in
                    adding = false
                    store.add(text)
                }
            } else {
                HoverRow { hovering in
                    Button {
                        adding = true
                    } label: {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Theme.outlines, style: StrokeStyle(lineWidth: 2, dash: [3, 2.5]))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .bold))
                                )
                            Text("Voeg een doel toe")
                                .font(Theme.plex(13))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(hovering ? Theme.text : Theme.disabled)
                        .padding(EdgeInsets(top: 7, leading: 6, bottom: 7, trailing: 6))
                        .background(hovering ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if store.allDone {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Alles klaar. Mooi werk.")
                        .font(Theme.plex(12.5, .semibold))
                }
                .foregroundStyle(Theme.positive)
                Spacer(minLength: 0)
                Text("\(store.streak + 1)-daagse reeks")
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

    // MARK: - Collapsed pill

    private var pill: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { store.collapsed = false }
        } label: {
            HStack(spacing: 10) {
                Circle().fill(Theme.accent).frame(width: 9, height: 9)
                Text(store.allDone ? "Alles klaar voor vandaag" : store.main.text)
                    .font(Theme.plex(13, .semibold))
                    .tracking(-0.13)
                    .foregroundStyle(store.allDone ? Theme.positive : Theme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 160, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false)
                ProgressBar(progress: store.progress)
                    .frame(width: 38)
                Text("\(store.doneCount)/\(store.total)")
                    .font(Theme.plex(12, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.disabled)
            }
            .padding(EdgeInsets(top: 9, leading: 13, bottom: 9, trailing: 15))
            .background(Theme.background, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.lines, lineWidth: 2))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Klik om uit te klappen")
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

private struct SideRow: View {
    let goal: Goal
    let allDone: Bool
    let editing: Bool
    let onToggle: () -> Void
    let onStartEdit: () -> Void
    let onCommit: (String) -> Void
    let onDelete: () -> Void
    @State private var hoveringDelete = false

    var body: some View {
        HoverRow { hovering in
            HStack(alignment: .top, spacing: 10) {
                CheckBox(done: goal.done, allDone: allDone, action: onToggle)
                EditableText(
                    text: goal.text,
                    font: Theme.plex(13),
                    lineSpacing: 2.5,
                    done: goal.done,
                    editing: editing,
                    onStart: onStartEdit,
                    onCommit: onCommit
                )
                .padding(.top, 1)
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
                .help("Verwijder")
            }
            .padding(6)
            .background(hovering ? Theme.supportHover : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
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
                        focused = true
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
                    .help("Klik om te bewerken")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AddField: View {
    let onCommit: (String) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.outlines, lineWidth: 2)
                .frame(width: 20, height: 20)
            TextField("Nieuw doel, druk op enter", text: $draft)
                .textFieldStyle(.plain)
                .font(Theme.plex(13))
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
        .onAppear { focused = true }
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
