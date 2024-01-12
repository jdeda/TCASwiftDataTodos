import ComposableArchitecture
import Foundation

// Represents the XCode preview / simulator version of the database.
// This implementation always makes sure to initializeDatabase at any
// endpoint so we don't have to call initializeDatabase in the every preview
extension Database {
  static let preview: Self = {
    let defaultTodos = [
      Todo(id: .init(), isComplete: true, description: "Wakeup", orderIndex: 0),
      Todo(id: .init(), isComplete: false, description: "Homework", orderIndex: 1),
      Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 2),
      Todo(id: .init(), isComplete: true, description: "Do Keto", orderIndex: 3),
      Todo(id: .init(), isComplete: false, description: "Go to Bed", orderIndex: 4),
    ]
    let sdc = SDClient(URL(fileURLWithPath: "dev/null"))
    return Database(
      initializeDatabase: {
        await sdc.initializeDatabase(defaultTodos)
      },
      retrieveTodos: {
        await sdc.initializeDatabase(defaultTodos)
        return await sdc.retrieveAllTodos()
      },
      createTodo: { todo in
        await sdc.initializeDatabase(defaultTodos)
        await sdc.createTodo(todo)
      },
      retrieveTodo: { todoID in
        await sdc.initializeDatabase(defaultTodos)
        return await sdc.retrieveTodo(todoID)
      },
      updateTodo: { todo in
        await sdc.initializeDatabase(defaultTodos)
        await sdc.updateTodo(todo)
      },
      deleteTodo: { todoID in
        await sdc.initializeDatabase(defaultTodos)
        await sdc.deleteTodo(todoID)
      }
    )
  }()
}
