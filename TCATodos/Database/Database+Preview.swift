import ComposableArchitecture
import Foundation

// Represents the XCode preview / simulator version of the database.
// This implementation always makes sure to initializeDatabase at any
// endpoint so don't have to call initializeDatabase in the every preview
extension Database {
  static let preview: Self = {
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))!
    return Database(
      initializeDatabase: {
        await sdc.initializeDatabase()
      },
      retrieveTodos: {
        await sdc.initializeDatabase()
        return await sdc.retrieveAllTodos()
      },
      createTodo: { todo in
        await sdc.initializeDatabase()
        await sdc.createTodo(todo)
      },
      retrieveTodo: { todoID in
        await sdc.initializeDatabase()
        return await sdc.retrieveTodo(todoID)
      },
      updateTodo: { todo in
        await sdc.initializeDatabase()
        await sdc.updateTodo(todo)
      },
      deleteTodo: { todoID in
        await sdc.initializeDatabase()
        await sdc.deleteTodo(todoID)
      }
    )
  }()
}
