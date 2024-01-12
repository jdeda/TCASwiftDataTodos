import XCTest
@testable import TCATodos
import ComposableArchitecture

@MainActor
final class SDClientTests: XCTestCase {
  
  
  func testInit() async throws {
    // Note, difficult to test the default initializer because it writes to a real location.
    // and will affect actual production database!
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    await XCTAssertTodosEqual(sdc, [])
  }
  
  func testInitializeDatabase1() async throws {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    let todo = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    
    await sdc.initializeDatabase([todo])
    await XCTAssertTodosEqual(sdc, [todo])
    
    await sdc.initializeDatabase([])
    await XCTAssertTodosEqual(sdc, [todo])
  }
    
  func testRetrieveAllTodos() async {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    await XCTAssertTodosEqual(sdc, [])
    
    let todo1 = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    let todo2 = Todo(id: .init(), isComplete: false, description: "Do Homework", orderIndex: 0)

    await sdc.createTodo(todo1)
    await XCTAssertTodosEqual(sdc, [todo1])

    await sdc.createTodo(todo2)
    await XCTAssertTodosEqual(sdc, [todo1, todo2])
  }
  
  func testCreateTodo() async {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    let todo = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    await sdc.createTodo(todo)
    await XCTAssertTodosEqual(sdc, [todo])
  }
  
  func testRetrieveTodo() async {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    let todo = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    await sdc.createTodo(todo)
    let retrievedTodo = await sdc.retrieveTodo(todo.id)
    XCTAssertEqual(retrievedTodo, todo)
    
    let retrievedTodo1 = await sdc.retrieveTodo(.init())
    XCTAssertNil(retrievedTodo1)
  }
  
  func testUpdateTodo() async {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    var todo = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    await sdc.createTodo(todo)
    await XCTAssertTodosEqual(sdc, [todo])

    todo.isComplete = false
    todo.description = "Do Homework"
    await sdc.updateTodo(todo)
    await XCTAssertTodosEqual(sdc, [todo])
    
    await sdc.updateTodo(.init(id: .init()))
    await XCTAssertTodosEqual(sdc, [todo])
  }
  
  func testDeleteTodo() async {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    var todo = Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 0)
    await sdc.createTodo(todo)
    await XCTAssertTodosEqual(sdc, [todo])

    await sdc.deleteTodo(todo.id)
    await XCTAssertTodosEqual(sdc, [])
    
    await sdc.deleteTodo(.init())
    await XCTAssertTodosEqual(sdc, [])
    
    await sdc.deleteTodo(todo.id)
    await XCTAssertTodosEqual(sdc, [])
  }
  
  private func XCTAssertTodosEqual(_ sdc: SDClient, _ todos: [Todo]) async {
    let fetchedTodos = await sdc.retrieveAllTodos()
    XCTAssertEqual(fetchedTodos, todos)
  }
}
