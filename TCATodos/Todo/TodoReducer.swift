import Foundation
import ComposableArchitecture

@Reducer
struct TodoReducer {
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: Todo.ID { self.todo.id }
    var todo: Todo
  }
  
  enum Action: Equatable, BindableAction, ViewAction {
    case view(ViewAction)
    enum ViewAction: Equatable {
      case isCompletedToggled
    }
    
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.isCompletedToggled):
        state.todo.isComplete.toggle()
        return .none
        
      case .binding:
        return .none
      }
    }
  }
}
