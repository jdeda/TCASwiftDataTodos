import ComposableArchitecture
import Foundation

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var todos = IdentifiedArrayOf<Todo>()
  }
  
  enum Action: Equatable {
    case todoDescriptionEdited(Todo.ID, String)
    case todoIsCompletedToggled(Todo.ID)
    case todoSwipedToDelete(IndexSet)
    case todoMoved(IndexSet, Int)
    case addTodoButtonTapped
    case deleteCompletedTodosButtonTapped
  }
  
  @Dependency(\.uuid) var uuid
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .todoDescriptionEdited(id, description):
        state.todos[id: id]?.description = description
        return .none
        
      case let .todoIsCompletedToggled(id):
        state.todos[id: id]?.isComplete.toggle()
        return .none
        
      case let .todoSwipedToDelete(source):
        state.todos.remove(atOffsets: source)
        return .none
        
      case let .todoMoved(source, destination):
        state.todos.move(fromOffsets: source, toOffset: destination)
        return .none
        
      case .addTodoButtonTapped:
        state.todos.append(.init(id: .init(rawValue: uuid())))
        return .none
        
      case .deleteCompletedTodosButtonTapped:
        state.todos = state.todos.filter { !$0.isComplete }
        return .none
      }
    }
  }
}
