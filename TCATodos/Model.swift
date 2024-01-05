import Foundation
import Tagged

struct Todo: Identifiable, Equatable {
  typealias ID = Tagged<Self, UUID>
  let id: ID
  var isComplete: Bool = false
  var description: String = ""
  
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
