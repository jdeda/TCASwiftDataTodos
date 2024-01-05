import Foundation
import Tagged
import IdentifiedCollections

struct Todo: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  let id: ID
  var isComplete: Bool = false
  var description: String = ""
  
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
