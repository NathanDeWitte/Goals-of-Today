import Foundation
import Combine

struct Goal: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var done = false
}

/// App state with JSON persistence in ~/Library/Application Support/GoalsOfToday/
final class GoalsStore: ObservableObject {
    @Published var mains: [Goal]   // always at least one
    @Published var sides: [Goal]
    @Published var streak: Int
    @Published var collapsed: Bool

    private struct Snapshot: Codable {
        var mains: [Goal]?
        var main: Goal?   // legacy single-main format
        var sides: [Goal]
        var streak: Int
        var collapsed: Bool
    }

    private static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GoalsOfToday", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("state.json")
    }()

    private var saveCancellable: AnyCancellable?

    init() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            let migrated = snap.mains ?? snap.main.map { [$0] } ?? []
            mains = migrated.isEmpty ? [Goal(text: "Finish the Q3 board deck")] : migrated
            sides = snap.sides
            streak = snap.streak
            collapsed = snap.collapsed
        } else {
            // Seed, same as the prototype
            mains = [Goal(text: "Finish the Q3 board deck")]
            sides = [
                Goal(text: "Review 2 design specs", done: true),
                Goal(text: "Call with Maria · 15:00"),
                Goal(text: "Inbox to zero"),
            ]
            streak = 12
            collapsed = false
        }

        saveCancellable = objectWillChange
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
    }

    var all: [Goal] { mains + sides }
    var doneCount: Int { all.filter(\.done).count }
    var total: Int { all.count }
    var allDone: Bool { doneCount == total }
    var progress: Double { total == 0 ? 0 : Double(doneCount) / Double(total) }

    /// What the collapsed pill shows: the first open main goal.
    var pillText: String { mains.first(where: { !$0.done })?.text ?? mains.first?.text ?? "" }

    func toggle(_ id: UUID) {
        if let i = mains.firstIndex(where: { $0.id == id }) {
            mains[i].done.toggle()
        } else if let i = sides.firstIndex(where: { $0.id == id }) {
            sides[i].done.toggle()
        }
    }

    /// Commit an inline edit. Empty text deletes the goal — except the last
    /// main goal, which keeps its old text (there is always one main focus).
    func commit(_ id: UUID, text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let i = mains.firstIndex(where: { $0.id == id }) {
            if !t.isEmpty {
                mains[i].text = t
            } else if mains.count > 1 {
                mains.remove(at: i)
            }
            return
        }
        guard let i = sides.firstIndex(where: { $0.id == id }) else { return }
        if t.isEmpty { sides.remove(at: i) } else { sides[i].text = t }
    }

    func delete(_ id: UUID) {
        if mains.contains(where: { $0.id == id }) {
            guard mains.count > 1 else { return } // always keep one main focus
            mains.removeAll { $0.id == id }
        } else {
            sides.removeAll { $0.id == id }
        }
    }

    func addMain(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        mains.append(Goal(text: t))
    }

    func addSide(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        sides.append(Goal(text: t))
    }

    private func save() {
        let snap = Snapshot(mains: mains, main: nil, sides: sides, streak: streak, collapsed: collapsed)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }
}

/// "Wed 3 Jun" — short date, like the prototype's fmtDate()
func shortDate(_ date: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.dateFormat = "EEE d MMM"
    return f.string(from: date).replacingOccurrences(of: ".", with: "")
}
