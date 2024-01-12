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
  
  init() {
    let modelContainer = try! ModelContainer(for: SDTodo.self)
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  init(_ url: URL) {
    let container = try! ModelContainer(for: SDTodo.self, configurations: .init(url: url))
    self.modelContainer = container
    let context = ModelContext(container)
    context.autosaveEnabled = false
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    self.didInitStore = false
  }
  
  // Initializes database with given todos, assuming
  // the database is empty and we have not already
  // successfully called this method.
  func initializeDatabase(_ todos: [Todo]) {
    guard !self.didInitStore else { return }
    var fd = FetchDescriptor<SDTodo>()
    fd.fetchLimit = 1
    guard (try? self.modelContext.fetchCount(fd)) == 0 else { return }
    todos.forEach(self.createTodo)
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
