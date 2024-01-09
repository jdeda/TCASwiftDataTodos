import ComposableArchitecture
import Foundation

@DependencyClient
struct Database: Sendable, DependencyKey {
  static let liveValue = Database.live
  static let previewValue = Database.preview
  static let testValue = Database()

  var initializeDatabase: @Sendable () async -> Void
  var retrieveTodos: @Sendable () async -> [Todo] = { [] }
  var createTodo: @Sendable (Todo) async -> Void
  var retrieveTodo: @Sendable (Todo.ID) async -> Todo? = { _ in nil }
  var updateTodo: @Sendable (Todo) async -> Void
  var deleteTodo: @Sendable (Todo) async -> Void
}

extension DependencyValues {
  var database: Database {
    get { self[Database.self] }
    set { self[Database.self] = newValue }
  }
}
