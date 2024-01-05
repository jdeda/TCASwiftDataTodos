import XCTest
@testable import TCATodos
import ComposableArchitecture


@MainActor
final class AppReducerTests: XCTestCase {
  
  func testTodoIsCompleteToggled1() async {
    let todoA = Todo(id: .init(), isComplete: true, description: "A")
    let todoB = Todo(id: .init(), isComplete: true, description: "B")
    let todoC = Todo(id: .init(), isComplete: true, description: "C")
    let clock = TestClock()
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    
    await store.send(.todoIsCompletedToggled(todoA.id)) {
      $0.todos[id: todoA.id]?.isComplete = false
    }
    await clock.advance(by: .milliseconds(500))
    await store.send(.todoIsCompletedToggled(todoB.id)) {
      $0.todos[id: todoB.id]?.isComplete = false
    }
    await clock.advance(by: .milliseconds(500))
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = false
    }
    await clock.advance(by: .milliseconds(500))
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = true
    }
    await clock.advance(by: .milliseconds(500))
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = false
    }
    await clock.advance(by: .milliseconds(1000))
    await store.receive(.sortTodos, timeout: .seconds(1))
  }
  
  func testTodoIsCompleteToggled2() async {
    let todoA = Todo(id: .init(), isComplete: false, description: "A")
    let todoB = Todo(id: .init(), isComplete: false, description: "B")
    let todoC = Todo(id: .init(), isComplete: false, description: "C")
    let clock = TestClock()
    let store = TestStore(
      initialState: AppReducer.State(todos: [todoA, todoB, todoC]),
      reducer: AppReducer.init,
      withDependencies: {
        $0.continuousClock = clock
      }
    )
    
    await store.send(.todoIsCompletedToggled(todoA.id)) {
      $0.todos[id: todoA.id]?.isComplete = true
    }
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = true
    }
    await clock.advance(by: .milliseconds(1000))
    await store.receive(.sortTodos, timeout: .seconds(1)) {
      $0.todos = [
        Todo(id: todoB.id, isComplete: false, description: "B"),
        Todo(id: todoA.id, isComplete: true, description: "A"),
        Todo(id: todoC.id, isComplete: true, description: "C")
      ]
    }
  }
  
  func testTodoDescriptionEdited() async {
    let todoA = Todo(id: .init(), isComplete: true, description: "A")
    let todoB = Todo(id: .init(), isComplete: true, description: "B")
    let todoC = Todo(id: .init(), isComplete: true, description: "C")
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init)
    
    await store.send(.todoDescriptionEdited(todoA.id, "AAA")) {
      $0.todos[id: todoA.id]?.description = "AAA"
    }
    await store.send(.todoDescriptionEdited(todoB.id, "BBB")) {
      $0.todos[id: todoB.id]?.description = "BBB"
    }
    await store.send(.todoDescriptionEdited(todoC.id, "CCC")) {
      $0.todos[id: todoC.id]?.description = "CCC"
    }
    await store.send(.todoDescriptionEdited(todoC.id, "CCC"))
    await store.send(.todoDescriptionEdited(todoC.id, "CC")) {
      $0.todos[id: todoC.id]?.description = "CC"
    }
    await store.send(.todoDescriptionEdited(todoC.id, "")) {
      $0.todos[id: todoC.id]?.description = ""
    }
  }
  
  func testAddTodoButtonTapped() async {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer.init, withDependencies: {
      $0.uuid = .incrementing
    })
    
    await store.send(.addTodoButtonTapped) {
      let todo = Todo(id: .init(rawValue: .init(0)))
      $0.todos.append(todo)
      $0.focus = .todo(todo.id)
    }
    await store.send(.addTodoButtonTapped) {
      let todo = Todo(id: .init(rawValue: .init(1)))
      $0.todos.append(todo)
      $0.focus = .todo(todo.id)
    }
    await store.send(.addTodoButtonTapped) {
      let todo = Todo(id: .init(rawValue: .init(2)))
      $0.todos.append(todo)
      $0.focus = .todo(todo.id)
    }
  }
  
  func testDeleteCompletedTodosButtonTapped() async {
    let todoA = Todo(id: .init(), isComplete: true, description: "A")
    let todoB = Todo(id: .init(), isComplete: true, description: "B")
    let todoC = Todo(id: .init(), isComplete: true, description: "C")
    var store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init)
    
    await store.send(.deleteCompletedTodosButtonTapped) {
      $0.todos = []
    }
    
    store = TestStore(
      initialState: AppReducer.State(todos: [
        .init(id: todoA.id, isComplete: false, description: todoA.description),
        .init(id: todoB.id, isComplete: false, description: todoB.description),
        .init(id: todoC.id, isComplete: false, description: todoC.description),
      ]),
      reducer: AppReducer.init
    )
    await store.send(.deleteCompletedTodosButtonTapped)
    
    store = TestStore(
      initialState: AppReducer.State(todos: [
        .init(id: todoA.id, isComplete: false, description: todoA.description),
        .init(id: todoB.id, isComplete: true, description: todoB.description),
        .init(id: todoC.id, isComplete: false, description: todoC.description),
        
      ]),
      reducer: AppReducer.init
    )
    await store.send(.deleteCompletedTodosButtonTapped) {
      $0.todos.remove(id: todoB.id)
    }
  }
}
