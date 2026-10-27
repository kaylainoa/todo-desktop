import Foundation

struct Subtask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done = false
}
struct Todo: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done = false
    var subtasks: [Subtask] = []
}

extension Todo {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        done = try c.decode(Bool.self, forKey: .done)
        subtasks = try c.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
    }
}

/// Keeps todos in memory and mirrors them to
/// ~/Library/Application Support/FloatingTodo/todos.json
final class TodoStore: ObservableObject {
    @Published var todos: [Todo] = [] {
        didSet { save() }
    }

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FloatingTodo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("todos.json")

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Todo].self, from: data) {
            todos = saved
        }
    }

    var remaining: Int { todos.filter { !$0.done }.count }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todos.append(Todo(title: trimmed))
    }

    func toggle(_ todo: Todo) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i].done.toggle()
    }

    func delete(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
    }

    func clearDone() {
        todos.removeAll { $0.done }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(todos) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func addSubtask(to todo: Todo, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i].subtasks.append(Subtask(title: trimmed))
    }

    func toggleSubtask(_ subtask: Subtask, in todo: Todo) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        guard let j = todos[i].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }
        todos[i].subtasks[j].done.toggle()
    }

    func deleteSubtask(_ subtask: Subtask, in todo: Todo) {
        guard let i = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[i].subtasks.removeAll { $0.id == subtask.id }
    }
}
