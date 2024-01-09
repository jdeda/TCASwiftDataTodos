import SwiftData
import Foundation
import Tagged
import IdentifiedCollections

/// Model Reference type representing Todo used for SwiftData persistence.
/// This type should never be used outside of the database.
@Model
class SDTodo: Identifiable {
  let id: UUID
  var isComplete: Bool
  var description_: String
  var orderIndex: Int
  
  init(ID: UUID, isComplete: Bool, description_: String, orderIndex: Int) {
    self.id = ID
    self.isComplete = isComplete
    self.description_ = description_
    self.orderIndex = orderIndex
  }
  
  convenience init(_ todo: Todo) {
    self.init(
      ID: todo.id.rawValue,
      isComplete: todo.isComplete,
      description_: todo.description,
      orderIndex: todo.orderIndex
    )
  }
}


/// Value type representing a Todo used in application domain logic.
/// Use this type for Todos outside the database.
struct Todo: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  let id: ID
  var isComplete: Bool
  var description: String
  var orderIndex: Int
  
  init(
    id: ID,
    isComplete: Bool = false,
    description: String = "",
    orderIndex: Int = 0
  ) {
    self.id = id
    self.isComplete = isComplete
    self.description = description
    self.orderIndex = orderIndex
  }
  
  init(_ sdTodo: SDTodo) {
    self.id = .init(rawValue: sdTodo.id)
    self.isComplete = sdTodo.isComplete
    self.description = sdTodo.description_
    self.orderIndex = sdTodo.orderIndex
  }
}

extension Todo {
  static let mockTodo = Todo(id: .init(), isComplete: false, description: "Write some Swift")
}

extension Array where Element == Todo {
  static let mockTodos: Self = [
    .init(id: .init(), isComplete: true, description: "Wakeup"),
    .init(id: .init(), isComplete: false, description: "Homework"),
    .init(id: .init(), isComplete: true, description: "Play Videogames"),
    .init(id: .init(), isComplete: true, description: "Do Keto"),
    .init(id: .init(), isComplete: false, description: "Go to Bed")
  ]
}

extension Array where Element: Identifiable {
  func mapIdentifiable<NewElement: Identifiable>(_ transform: (Element) -> NewElement) -> IdentifiedArrayOf<NewElement> {
    .init(uniqueElements: self.map(transform))
  }
}
