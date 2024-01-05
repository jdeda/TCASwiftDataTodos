import ComposableArchitecture
import Foundation

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var todos = IdentifiedArrayOf<Todo>()
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
  
  enum Action: Equatable, BindableAction {
    case todoDescriptionEdited(Todo.ID, String)
    case todoIsCompletedToggled(Todo.ID)
    case todoSwipedToDelete(IndexSet)
    case todoMoved(IndexSet, Int)
    case addTodoButtonTapped
    case deleteCompletedTodosButtonTapped
    case sortTodos
    case editTodosButtonTapped
    case editTodosDoneButtonTapped
    case selectAllTodosButtonTapped
    case deleteSelectedTodosButtonTapped
    case binding(BindingAction<State>)
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  
  enum SortEffectID: Hashable { case cancel }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case let .todoDescriptionEdited(id, description):
        state.todos[id: id]?.description = description
        return .none
        
      case let .todoIsCompletedToggled(id):
        state.todos[id: id]?.isComplete.toggle()
        return .run { send in
          try await self.clock.sleep(for: .seconds(1))
          await send(.sortTodos, animation: .default)
        }
        .cancellable(id: SortEffectID.cancel, cancelInFlight: true)
        
      case let .todoSwipedToDelete(source):
        state.todos.remove(atOffsets: source)
        return .none
        
      case let .todoMoved(source, destination):
        state.todos.move(fromOffsets: source, toOffset: destination)
        return .none
        
      case .addTodoButtonTapped:
        let todo = Todo(id: .init(rawValue: uuid()))
        state.todos.append(todo)
        state.focus = .todo(todo.id)
        return .none
        
      case .deleteCompletedTodosButtonTapped:
        state.todos = state.todos.filter { !$0.isComplete }
        return .none
        
      case .sortTodos:
        state.todos.sort { $1.isComplete && !$0.isComplete }
        return .none
        
      case .editTodosButtonTapped:
        state.focus = nil
        state.isEditingTodos = true
        return .none
        
      case .editTodosDoneButtonTapped:
        state.isEditingTodos = false
        state.selectedTodos = []
        return .none
        
      case .selectAllTodosButtonTapped:
        state.selectedTodos = state.hasSelectedAll ? [] : .init(state.todos.map(\.id))
        return .none
        
      case .deleteSelectedTodosButtonTapped:
        state.todos = state.todos.filter { !state.selectedTodos.contains($0.id) }
        state.selectedTodos = []
        return .none
        
      case .binding:
        return .none
      }
    }
  }
}
