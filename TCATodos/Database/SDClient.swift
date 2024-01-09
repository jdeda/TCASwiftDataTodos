import SwiftData
import Foundation

// Client responsible for all SwiftData operations for the entire app.
// Performs basic CRUD operations on all models.
// Executes all operations on background thread via ModelActor.
// Thread safe (actor).
actor SDClient: ModelActor {
  let modelContainer: ModelContainer
  let modelExecutor: ModelExecutor
  private(set) var didInitStore: Bool
  
  init?() {
    guard let modelContainer = try? ModelContainer(for: SDTodo.self)
    else { return nil }
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  init?(_ url: URL) {
    guard let container = try? ModelContainer(for: SDTodo.self, configurations: .init(url: url))
    else { return nil }
    self.modelContainer = container
    let context = ModelContext(container)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  enum SDError: Equatable, Error {
    case failure
    case notFound
    case duplicate
  }
  
  // Initializes database with default data, assuming
  // the database is empty and we have not already
  // successfully called this method.
  func initializeDatabase() {
    guard !self.didInitStore else { return }
    var fd = FetchDescriptor<SDTodo>()
    fd.fetchLimit = 1
    guard (try? self.modelContext.fetchCount(fd)) == 0 else { return }
    let mockTodos: [Todo] = [
      Todo(id: .init(), isComplete: true, description: "Wakeup"),
      Todo(id: .init(), isComplete: false, description: "Homework"),
      Todo(id: .init(), isComplete: true, description: "Play Videogames"),
      Todo(id: .init(), isComplete: true, description: "Do Keto"),
      Todo(id: .init(), isComplete: false, description: "Go to Bed")
    ]
      .enumerated()
      .map({
        var todo = $1
        todo.orderIndex = $0
        return todo
      })
    mockTodos.forEach(self.createTodo)
    try! self.modelContext.save()
    self.didInitStore = true
  }
  
  func retrieveAllTodos() -> [Todo] {
    var fd = FetchDescriptor<SDTodo>(sortBy: [SortDescriptor<SDTodo>(\.orderIndex)])
    fd.fetchLimit = 100
    let todos = (try? self.modelContext.fetch(fd)) ?? []
    return todos.map(Todo.init)
  }
  
  func createTodo(_ todo: Todo) {
    let sdTodo = SDTodo(todo)
    self.modelContext.insert(sdTodo)
    try! self.modelContext.save()
  }
  
  func retrieveTodo(_ id: Todo.ID) -> Todo? {
    guard let sdTodo = self._retrieveSDTodo(id.rawValue) else { return nil }
    return Todo(sdTodo)
  }
  
  func updateTodo(_ todo: Todo) {
    guard let sdTodo = self._retrieveSDTodo(todo.id.rawValue) else { return }
    sdTodo.isComplete = todo.isComplete
    sdTodo.description_ = todo.description
    sdTodo.orderIndex = todo.orderIndex
    try! self.modelContext.save()
  }
  
  func deleteTodo(_ id: Todo.ID) {
    guard let sdTodo = self._retrieveSDTodo(id.rawValue) else { return }
    self.modelContext.delete(sdTodo)
    try! self.modelContext.save()
  }
  
  func _retrieveSDTodo(_ id: UUID) -> SDTodo? {
    var fd = FetchDescriptor<SDTodo>(predicate: #Predicate<SDTodo> { $0.id == id })
    fd.fetchLimit = 1
    return try? self.modelContext.fetch(fd).first
  }
}
