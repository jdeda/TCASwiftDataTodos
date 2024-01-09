import ComposableArchitecture
import Foundation

// Represents the live production version of the database.
extension Database {
  static let live: Self = {
    let sdc = SDClient()!
    return Database(
      initializeDatabase: {
        await sdc.initializeDatabase()
      },
      retrieveTodos: {
        await sdc.retrieveAllTodos()
      },
      createTodo: { todo in
        await sdc.createTodo(todo)
      },
      retrieveTodo: { todoID in
        await sdc.retrieveTodo(todoID)
      },
      updateTodo: { todo in
        await sdc.updateTodo(todo)
      },
      deleteTodo: { todo in
        await sdc.deleteTodo(todo)
      }
    )
  }()
}
