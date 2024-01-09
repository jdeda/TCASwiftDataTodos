import XCTest
@testable import TCATodos
import ComposableArchitecture

@MainActor
final class TodoReducerTests: XCTestCase {
  func testTodoIsCompleteToggled1() async {
    let todo = Todo(id: .init(), isComplete: true, description: "A")
    let store = TestStore(
      initialState: TodoReducer.State(todo: todo),
      reducer: TodoReducer.init
    )
    
    await store.send(.view(.isCompletedToggled)) {
      $0.todo.isComplete = false
    }
    await store.send(.view(.isCompletedToggled)) {
      $0.todo.isComplete = true
    }
    await store.send(.view(.isCompletedToggled)) {
      $0.todo.isComplete = false
    }
  }
  
  func testTodoDescriptionEdited() async {
    let todo = Todo(id: .init(), isComplete: true, description: "A")
    let store = TestStore(
      initialState: TodoReducer.State(todo: todo),
      reducer: TodoReducer.init
    )
    
    await store.send(.binding(.set(\.todo.description, "AAA"))) {
      $0.todo.description = "AAA"
    }
    await store.send(.binding(.set(\.todo.description, "BBB"))) {
      $0.todo.description = "BBB"
    }
    await store.send(.binding(.set(\.todo.description, "CCC"))) {
      $0.todo.description = "CCC"
    }
    await store.send(.binding(.set(\.todo.description, "CCC")))
    await store.send(.binding(.set(\.todo.description, "CC"))) {
      $0.todo.description = "CC"
    }
    await store.send(.binding(.set(\.todo.description, ""))) {
      $0.todo.description = ""
    }
  }
}
