// Swift example - Task manager with async/await and SwiftUI-like patterns
import Foundation

// MARK: - Models

enum TaskPriority: Int, Comparable, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var priority: TaskPriority
    var isCompleted: Bool
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
        self.isCompleted = false
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Errors

enum TaskError: Error, LocalizedError {
    case notFound
    case invalidTitle
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Task not found"
        case .invalidTitle: return "Title cannot be empty"
        case .persistenceFailed(let reason): return "Failed to save: \(reason)"
        }
    }
}

// MARK: - Protocols

protocol TaskRepository {
    func fetchAll() async throws -> [TaskItem]
    func fetch(by id: UUID) async throws -> TaskItem
    func save(_ task: TaskItem) async throws
    func delete(_ id: UUID) async throws
}

protocol TaskObservable: AnyObject {
    func tasksDidChange(_ tasks: [TaskItem])
}

// MARK: - Repository Implementation

actor FileTaskRepository: TaskRepository {
    private let fileURL: URL
    private var cache: [TaskItem]?

    init(directory: URL) throws {
        self.fileURL = directory.appendingPathComponent("tasks.json")
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory.path) {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        if !fm.fileExists(atPath: fileURL.path) {
            try "[]".write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func fetchAll() async throws -> [TaskItem] {
        if let cached = cache {
            return cached
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let tasks = try decoder.decode([TaskItem].self, from: data)
        cache = tasks
        return tasks
    }

    func fetch(by id: UUID) async throws -> TaskItem {
        let tasks = try await fetchAll()
        guard let task = tasks.first(where: { $0.id == id }) else {
            throw TaskError.notFound
        }
        return task
    }

    func save(_ task: TaskItem) async throws {
        var tasks = try await fetchAll()

        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = task
            updated.updatedAt = Date()
            tasks[index] = updated
        } else {
            tasks.append(task)
        }

        try await write(tasks)
    }

    func delete(_ id: UUID) async throws {
        var tasks = try await fetchAll()
        tasks.removeAll { $0.id == id }
        try await write(tasks)
    }

    private func write(_ tasks: [TaskItem]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(tasks)
        try data.write(to: fileURL, options: .atomic)
        cache = tasks
    }
}

// MARK: - Service Layer

@dynamicMemberLookup
class TaskService {
    private let repository: TaskRepository
    private weak var observer: TaskObservable?

    subscript<T>(dynamicMember keyPath: KeyPath<TaskItem, T>) -> (TaskItem) -> T {
        { task in task[keyPath: keyPath] }
    }

    init(repository: TaskRepository) {
        self.repository = repository
    }

    func setObserver(_ observer: TaskObservable) {
        self.observer = observer
    }

    func loadTasks() async throws -> [TaskItem] {
        let tasks = try await repository.fetchAll()
            .sorted { $0.priority > $1.priority }
        await MainActor.run {
            observer?.tasksDidChange(tasks)
        }
        return tasks
    }

    func createTask(title: String, description: String = "", priority: TaskPriority = .medium, tags: [String] = []) async throws -> TaskItem {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TaskError.invalidTitle
        }

        let task = TaskItem(
            title: title,
            description: description,
            priority: priority,
            tags: tags
        )

        try await repository.save(task)
        _ = try await loadTasks()
        return task
    }

    func toggleCompletion(for id: UUID) async throws -> TaskItem {
        var task = try await repository.fetch(by: id)
        task.isCompleted.toggle()
        task.updatedAt = Date()
        try await repository.save(task)
        _ = try await loadTasks()
        return task
    }

    func deleteTask(_ id: UUID) async throws {
        try await repository.delete(id)
        _ = try await loadTasks()
    }

    func tasksSummary(_ tasks: [TaskItem]) -> String {
        let completed = tasks.filter(\.isCompleted).count
        let total = tasks.count
        let highPriority = tasks.filter { $0.priority >= .high && !$0.isCompleted }.count

        return """
        ┌─────────────────────┐
        │ Tasks: \(String(total).padding(toLength: 12, withPad: " ", startingAt: 0)) │
        │ Completed: \(String(completed).padding(toLength: 9, withPad: " ", startingAt: 0)) │
        │ High Priority: \(String(highPriority).padding(toLength: 5, withPad: " ", startingAt: 0)) │
        └─────────────────────┘
        """
    }
}

// MARK: - Observer

class ConsoleObserver: TaskObservable {
    func tasksDidChange(_ tasks: [TaskItem]) {
        print("\n📋 Tasks updated (\(tasks.count) total):")
        for task in tasks {
            let icon = task.isCompleted ? "✅" : "⬜"
            print("  \(icon) [\(task.priority.label.padding(toLength: 6, withPad: " ", startingAt: 0))] \(task.title)")
        }
    }
}

// MARK: - Extensions

extension String {
    func padding(toLength length: Int, withPad pad: String, startingAt: Int) -> String {
        let current = count
        if current >= length { return self }
        return self + String(repeating: pad, count: length - current)
    }
}

extension Array where Element == TaskItem {
    func filtering(by searchText: String) -> [TaskItem] {
        guard !searchText.isEmpty else { return self }
        return filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    func groupedByPriority() -> [TaskPriority: [TaskItem]] {
        Dictionary(grouping: self) { $0.priority }
    }
}

// MARK: - Main

@main
struct App {
    static func main() async {
        do {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let appDir = documentsDir.appendingPathComponent("DevMediaTasks")

            let repository = try FileTaskRepository(directory: appDir)
            let service = TaskService(repository: repository)
            let observer = ConsoleObserver()
            service.setObserver(observer)

            // Create sample tasks
            try await service.createTask(
                title: "Review pull request",
                priority: .urgent,
                tags: ["work", "review"]
            )
            try await service.createTask(
                title: "Write documentation",
                description: "Update API docs",
                priority: .high,
                tags: ["docs"]
            )
            try await service.createTask(
                title: "Buy groceries",
                priority: .low,
                tags: ["personal"]
            )

            // Load and display
            let tasks = try await service.loadTasks()
            print(service.tasksSummary(tasks))

            // Toggle completion
            if let first = tasks.first {
                try await service.toggleCompletion(for: first.id)
            }

            // Filtered
            print("\n🔍 Filtered by 'docs':")
            let filtered = tasks.filtering(by: "docs")
            for task in filtered {
                print("  • \(task.title)")
            }

            // Grouped
            print("\n📊 Grouped by priority:")
            for (priority, grouped) in tasks.groupedByPriority() {
                print("  \(priority.label): \(grouped.count) tasks")
            }

        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
