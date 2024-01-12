import XCTest
@testable import TCATodos
import ComposableArchitecture

/// Tests AppReducer actions and integration tests with child Todo reducer.
/// Tests are structured as:
///   1. Create mock data
///   2. Create test database and initialize with mock data
///   3. Create test store and initialize with mock data
///   4. Send store actions and assert state mutations, and always assert database and store have same todos
@MainActor
final class AppReducerTests: XCTestCase {
  
  func testTask() async {
    let todoA = Todo(id: .init(), isComplete: true, description: "A")
    let todoB = Todo(id: .init(), isComplete: true, description: "B")
    let todoC = Todo(id: .init(), isComplete: true, description: "C")
    let todos = [todoA, todoB, todoC]
    
    // No actions should be recieved nor should the DB be called.
    // (loadStatus == .didLoad)
    let store1 = TestStore(
      initialState: AppReducer.State(loadStatus: .didLoad),
      reducer: AppReducer.init
    )
    await store1.send(.view(.task))
    await store1.finish(timeout: .milliseconds(1))
    
    // No actions should be recieved nor should the DB be called.
    // (loadStatus == .isLoading)
    let store2 = TestStore(
      initialState: AppReducer.State(loadStatus: .isLoading),
      reducer: AppReducer.init
    )
    await store2.send(.view(.task))
    await store2.finish(timeout: .milliseconds(1))
    
    // Should be initializing DB and recieve success.
    let store3 = TestStore(
      initialState: AppReducer.State(loadStatus: .didNotLoad),
      reducer: AppReducer.init,
      withDependencies: {
        $0.database.initializeDatabase = {
          // Do nothing.
        }
        $0.database.retrieveTodos = {
          todos
        }
      }
    )
    await store3.send(.view(.task)) {
      $0.loadStatus = .isLoading
    }
    await store3.receive(.loadTodosSuccess(todos)) {
      $0.todos = todos.mapIdentifiable({.init(todo: $0)})
      $0.loadStatus = .didLoad
    }
  }
  
  func testTodoSwipedToDelete() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase =  {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.deleteTodo = { todoID in
        await sdc.deleteTodo(todoID)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodo = { todoID in
        await sdc.retrieveTodo(todoID)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init
    ) {
      $0.database = database
    }
    
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.todoSwipedToDelete(todoA.id))) {
      $0.todos.remove(id: todoA.id)
      $0.todos[id: todoB.id]?.todo.orderIndex = 0
      $0.todos[id: todoC.id]?.todo.orderIndex = 1
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.todoSwipedToDelete(todoB.id))) {
      $0.todos.remove(id: todoB.id)
      $0.todos[id: todoC.id]?.todo.orderIndex = 0
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.todoSwipedToDelete(todoB.id)))
    
    await store.send(.view(.todoSwipedToDelete(todoC.id))) {
      $0.todos = []
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testTodoMoved() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase =  {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init
    ) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.todoMoved(IndexSet(integersIn: 0..<1), 2))) {
      $0.todos = [todoB, todoA, todoC]
      $0.todos = .init(uniqueElements: $0.todos.enumerated().map {
        var todo = $1
        todo.todo.orderIndex = $0
        return todo
      })
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testTodoIsCompleteToggled1() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase =  {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let clock = TestClock()
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init
    ) {
      $0.database = database
      $0.continuousClock = clock
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoA.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoA.id]?.todo.isComplete = false
    }
    await XCTAssertTodosEqual(database, store.state)
    
    
    await clock.advance(by: .milliseconds(500))
    await store.send(.todos(.element(id: todoB.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoB.id]?.todo.isComplete = false
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await clock.advance(by: .milliseconds(500))
    await store.send(.todos(.element(id: todoC.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoC.id]?.todo.isComplete = false
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await clock.advance(by: .milliseconds(500))
    await store.send(.todos(.element(id: todoC.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoC.id]?.todo.isComplete = true
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await clock.advance(by: .milliseconds(500))
    await store.send(.todos(.element(id: todoC.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoC.id]?.todo.isComplete = false
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await clock.advance(by: .milliseconds(1000))
    await store.receive(.sortTodos, timeout: .seconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testTodoIsCompleteToggled2() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase =  {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let clock = TestClock()
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init
    ) {
      $0.database = database
      $0.continuousClock = clock
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoA.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoA.id]?.todo.isComplete = true
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoC.id, action: .view(.isCompletedToggled)))) {
      $0.todos[id: todoC.id]?.todo.isComplete = true
    }
    await XCTAssertTodosEqual(database, store.state)
    await clock.advance(by: .milliseconds(1000))
    await store.receive(.sortTodos, timeout: .seconds(1)) {
      $0.todos = [
        .init(todo: .init(id: todoB.id, isComplete: false, description: "B", orderIndex: 0)),
        .init(todo: .init(id: todoA.id, isComplete: true, description: "A", orderIndex: 1)),
        .init(todo: .init(id: todoC.id, isComplete: true, description: "C", orderIndex: 2)),
      ]
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testTodoDescriptionEdited() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase =  {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init
    ) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoA.id, action: .binding(.set(\.todo.description, "AAA"))))) {
      $0.todos[id: todoA.id]?.todo.description = "AAA"
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoB.id, action: .binding(.set(\.todo.description, "BBB"))))) {
      $0.todos[id: todoB.id]?.todo.description = "BBB"
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoC.id, action: .binding(.set(\.todo.description, "CCC"))))) {
      $0.todos[id: todoC.id]?.todo.description = "CCC"
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoC.id, action: .binding(.set(\.todo.description, "CCC")))))
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoC.id, action: .binding(.set(\.todo.description, "CC"))))) {
      $0.todos[id: todoC.id]?.todo.description = "CC"
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.todos(.element(id: todoC.id, action: .binding(.set(\.todo.description, ""))))) {
      $0.todos[id: todoC.id]?.todo.description = ""
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testAddTodoButtonTapped() async {
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    
    let store = TestStore(
      initialState: AppReducer.State(),
      reducer: AppReducer.init
    ) {
      $0.uuid = .incrementing
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.addTodoButtonTapped)) {
      let todo = Todo(id: .init(rawValue: .init(0)), orderIndex: 0)
      $0.todos.append(.init(todo: todo))
      $0.focus = .todo(todo.id)
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.addTodoButtonTapped)) {
      let todo = Todo(id: .init(rawValue: .init(1)), orderIndex: 1)
      $0.todos.append(.init(todo: todo))
      $0.focus = .todo(todo.id)
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.addTodoButtonTapped)) {
      let todo = Todo(id: .init(rawValue: .init(2)), orderIndex: 2)
      $0.todos.append(.init(todo: todo))
      $0.focus = .todo(todo.id)
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testDeleteCompletedTodosButtonTapped1() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase = {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.deleteTodo = { todoID in
        await sdc.deleteTodo(todoID)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.deleteCompletedTodosButtonTapped)) {
      $0.alert = .deleteCompletedTodos
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.alert(.dismiss)) {
      $0.alert = nil
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.deleteCompletedTodosButtonTapped)) {
      $0.alert = .deleteCompletedTodos
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.alert(.presented(.acceptDeleteCompletedTodosButtonTapped))) {
      $0.alert = nil
      $0.selectedTodos = []
      $0.todos = []
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testDeleteCompletedTodosButtonTapped2() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "C", orderIndex: 2))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase = {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.deleteTodo = { todoID in
        await sdc.deleteTodo(todoID)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.deleteCompletedTodosButtonTapped))
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testDeleteCompletedTodosButtonTapped3() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "A", orderIndex: 0))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B", orderIndex: 1))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: false, description: "C", orderIndex: 2))

    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase = {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.deleteTodo = { todoID in
        await sdc.deleteTodo(todoID)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.deleteCompletedTodosButtonTapped)) {
      $0.alert = .deleteCompletedTodos
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.alert(.presented(.acceptDeleteCompletedTodosButtonTapped))) {
      $0.alert = nil
      $0.selectedTodos = []
      $0.todos.remove(id: todoB.id)
      $0.todos[id: todoA.id]?.todo.orderIndex = 0
      $0.todos[id: todoC.id]?.todo.orderIndex = 1
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  func testDeleteSelectedTodos() async {
    let todoA = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "A"))
    let todoB = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "B"))
    let todoC = TodoReducer.State(todo: Todo(id: .init(), isComplete: true, description: "C"))
    let database: Database = {
      var database = Database()
      let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
      database.initializeDatabase = {
        await sdc.initializeDatabase([todoA.todo, todoB.todo, todoC.todo])
      }
      database.createTodo = { todo in
        await sdc.createTodo(todo)
      }
      database.updateTodo = { todo in
        await sdc.updateTodo(todo)
      }
      database.deleteTodo = { todoID in
        await sdc.deleteTodo(todoID)
      }
      database.retrieveTodos = {
        await sdc.retrieveAllTodos()
      }
      return database
    }()
    await database.initializeDatabase()
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init) {
      $0.database = database
    }
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.view(.editTodosButtonTapped)) {
      $0.isEditingTodos = true
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.deleteSelectedTodosButtonTapped))
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.selectAllTodosButtonTapped)) {
      $0.selectedTodos = .init($0.todos.map(\.id))
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.selectAllTodosButtonTapped)) {
      $0.selectedTodos = []
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.binding(.set(\.selectedTodos, [todoA.id]))) {
      $0.selectedTodos = [todoA.id]
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.selectAllTodosButtonTapped)) {
      $0.selectedTodos = [todoA.id, todoB.id, todoC.id]
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.binding(.set(\.selectedTodos, [todoA.id]))) {
      $0.selectedTodos = [todoA.id]
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.deleteSelectedTodosButtonTapped)) {
      $0.alert = .deleteSelectedTodos
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.alert(.dismiss)) {
      $0.alert = nil
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.deleteSelectedTodosButtonTapped)) {
      $0.alert = .deleteSelectedTodos
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    await store.send(.alert(.presented(.acceptDeleteSelectedTodosButtonTapped))) {
      $0.alert = nil
      $0.todos.remove(id: todoA.id)
      $0.todos[id: todoB.id]?.todo.orderIndex = 0
      $0.todos[id: todoC.id]?.todo.orderIndex = 1
      $0.selectedTodos = []
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.editTodosDoneButtonTapped)) {
      $0.isEditingTodos = false
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.editTodosButtonTapped)) {
      $0.isEditingTodos = true
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.binding(.set(\.selectedTodos, [todoB.id, todoC.id]))) {
      $0.selectedTodos = [todoB.id, todoC.id]
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.editTodosDoneButtonTapped)) {
      $0.isEditingTodos = false
      $0.selectedTodos = []
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.binding(.set(\.focus, .todo(todoC.id)))) {
      $0.focus = .todo(todoC.id)
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.editTodosButtonTapped)) {
      $0.isEditingTodos = true
      $0.focus = nil
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
    
    
    await store.send(.view(.editTodosDoneButtonTapped)) {
      $0.isEditingTodos = false
    }
    await store.finish(timeout: .milliseconds(1))
    await XCTAssertTodosEqual(database, store.state)
  }
  
  private func XCTAssertTodosEqual(_ database: Database, _ state: AppReducer.State) async {
    let fetchedTodos = await database.retrieveTodos()
    XCTAssertEqual(fetchedTodos, state.todos.map(\.todo))
  }
}

// TODO: Make something built into the assert that automatically asserts DB is in sync!
