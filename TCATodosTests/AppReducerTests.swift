import XCTest
@testable import TCATodos
import ComposableArchitecture


@MainActor
final class AppReducerTests: XCTestCase {
  
  func testTodoIsCompleteToggled() async {
    let todoA = Todo(id: .init(), isComplete: true, description: "A")
    let todoB = Todo(id: .init(), isComplete: true, description: "B")
    let todoC = Todo(id: .init(), isComplete: true, description: "C")
    let store = TestStore(initialState: AppReducer.State(todos: [todoA, todoB, todoC]), reducer: AppReducer.init)
    
    await store.send(.todoIsCompletedToggled(todoA.id)) {
      $0.todos[id: todoA.id]?.isComplete = false
    }
    await store.send(.todoIsCompletedToggled(todoB.id)) {
      $0.todos[id: todoB.id]?.isComplete = false
    }
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = false
    }
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = true
    }
    await store.send(.todoIsCompletedToggled(todoC.id)) {
      $0.todos[id: todoC.id]?.isComplete = false
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
      $0.todos.append(.init(id: .init(rawValue: .init(0))))
    }
    await store.send(.addTodoButtonTapped) {
      $0.todos.append(.init(id: .init(rawValue: .init(1))))
    }
    await store.send(.addTodoButtonTapped) {
      $0.todos.append(.init(id: .init(rawValue: .init(2))))
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
