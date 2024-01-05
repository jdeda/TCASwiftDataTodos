import ComposableArchitecture
import Foundation

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var todos = IdentifiedArrayOf<TodoReducer.State>()
    var selectedTodos = Set<Todo.ID>()
    var isEditingTodos = false
    
    var focus = Focus?.none
    @CasePathable
    @dynamicMemberLookup
    enum Focus: Equatable, Hashable {
      case todo(Todo.ID)
    }
    
    var hasSelectedAll: Bool {
      self.selectedTodos.count == self.todos.count
    }
  }
  
  enum Action: Equatable, BindableAction, ViewAction {
    case view(ViewAction)
    enum ViewAction: Equatable {
      case todoSwipedToDelete(IndexSet)
      case todoMoved(IndexSet, Int)
      case addTodoButtonTapped
      case deleteCompletedTodosButtonTapped
      case editTodosButtonTapped
      case editTodosDoneButtonTapped
      case selectAllTodosButtonTapped
      case deleteSelectedTodosButtonTapped
    }
    
    case sortTodos
    case todos(IdentifiedActionOf<TodoReducer>)
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  enum SortEffectID: Hashable { case cancel }
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    BindingReducer()
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case let .view(.todoSwipedToDelete(source)):
        state.todos.remove(atOffsets: source)
        return .none
        
      case let .view(.todoMoved(source, destination)):
        state.todos.move(fromOffsets: source, toOffset: destination)
        return .none
        
      case .view(.addTodoButtonTapped):
        let todo = Todo(id: .init(rawValue: uuid()))
        state.todos.append(.init(todo: todo))
        state.focus = .todo(todo.id)
        return .none
        
      case .view(.deleteCompletedTodosButtonTapped):
        state.todos = state.todos.filter { !$0.todo.isComplete }
        return .none
        
      case .view(.editTodosButtonTapped):
        state.focus = nil
        state.isEditingTodos = true
        return .none
        
      case .view(.editTodosDoneButtonTapped):
        state.isEditingTodos = false
        state.selectedTodos = []
        return .none
        
      case .view(.selectAllTodosButtonTapped):
        state.selectedTodos = state.hasSelectedAll ? [] : .init(state.todos.map(\.id))
        return .none
        
      case .view(.deleteSelectedTodosButtonTapped):
        state.todos = state.todos.filter { !state.selectedTodos.contains($0.id) }
        state.selectedTodos = []
        return .none
        
      case .sortTodos:
        state.todos.sort { $1.todo.isComplete && !$0.todo.isComplete }
        return .none
        
      case let .todos(.element(id: id, action: .view(.isCompletedToggled))):
        return .run { send in
          try await self.clock.sleep(for: .seconds(1))
          await send(.sortTodos, animation: .default)
        }
        .cancellable(id: SortEffectID.cancel, cancelInFlight: true)
        
      case let .todos(.element(id: id, action: action)):
        return .none
        
      case .binding:
        return .none
      }
    }
    .forEach(\.todos, action: \.todos) {
      TodoReducer()
    }
  }
}
