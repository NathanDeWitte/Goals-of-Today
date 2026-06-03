import Foundation
import Combine

struct Goal: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var done = false
}

/// App state with JSON persistence in ~/Library/Application Support/GoalsOfToday/
final class GoalsStore: ObservableObject {
    @Published var main: Goal
    @Published var sides: [Goal]
    @Published var streak: Int
    @Published var collapsed: Bool

    private struct Snapshot: Codable {
        var main: Goal
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
            main = snap.main
            sides = snap.sides
            streak = snap.streak
            collapsed = snap.collapsed
        } else {
            // Seed, same as the prototype
            main = Goal(text: "Finish the Q3 board deck")
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

    var all: [Goal] { [main] + sides }
    var doneCount: Int { all.filter(\.done).count }
    var total: Int { all.count }
    var allDone: Bool { doneCount == total }
    var progress: Double { total == 0 ? 0 : Double(doneCount) / Double(total) }

    func toggleMain() { main.done.toggle() }

    func toggle(_ id: UUID) {
        guard let i = sides.firstIndex(where: { $0.id == id }) else { return }
        sides[i].done.toggle()
    }

    /// Commit an inline edit. Empty text on a side goal deletes it (prototype behavior).
    func commit(_ id: UUID, text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if id == main.id {
            if !t.isEmpty { main.text = t }
            return
        }
        guard let i = sides.firstIndex(where: { $0.id == id }) else { return }
        if t.isEmpty { sides.remove(at: i) } else { sides[i].text = t }
    }

    func delete(_ id: UUID) { sides.removeAll { $0.id == id } }

    func add(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        sides.append(Goal(text: t))
    }

    private func save() {
        let snap = Snapshot(main: main, sides: sides, streak: streak, collapsed: collapsed)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }
}

/// "wo 3 jun" — Dutch short date, like the prototype's fmtDate()
func dutchShortDate(_ date: Date = Date()) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "nl_NL")
    f.dateFormat = "EEE d MMM"
    return f.string(from: date).replacingOccurrences(of: ".", with: "")
}
