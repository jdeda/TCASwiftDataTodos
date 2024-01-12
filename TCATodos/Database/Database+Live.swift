import ComposableArchitecture
import Foundation

// Represents the live production version of the database.
extension Database {
  static let live: Self = {
    let sdc = SDClient()
    return Database(
      initializeDatabase: {
        await sdc.initializeDatabase([
          Todo(id: .init(), isComplete: true, description: "Wakeup", orderIndex: 0),
          Todo(id: .init(), isComplete: false, description: "Homework", orderIndex: 1),
          Todo(id: .init(), isComplete: true, description: "Play Videogames", orderIndex: 2),
          Todo(id: .init(), isComplete: true, description: "Do Keto", orderIndex: 3),
          Todo(id: .init(), isComplete: false, description: "Go to Bed", orderIndex: 4),
        ])
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
      deleteTodo: { todoID in
        await sdc.deleteTodo(todoID)
      }
    )
  }()
}
