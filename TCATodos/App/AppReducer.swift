import ComposableArchitecture
import Foundation

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var loadStatus: LoadStatus = .didNotLoad
    var todos = IdentifiedArrayOf<TodoReducer.State>()
    var selectedTodos = Set<Todo.ID>()
    var isEditingTodos = false
    
    var focus = Focus?.none
    @CasePathable
    @dynamicMemberLookup
    enum Focus: Equatable, Hashable {
      case todo(Todo.ID)
    }
    
    @Presents var alert: AlertState<Action.AlertAction>?
    
    var hasSelectedAll: Bool {
      self.selectedTodos.count == self.todos.count
    }
    
    var disabledDeleteCompletedTodosButton: Bool {
      !self.todos.contains(where: { $0.todo.isComplete })
    }
    
    var disabledDeleteSelectedTodosButton: Bool {
      self.selectedTodos.isEmpty
    }
  }
  
  enum Action: Equatable, BindableAction, ViewAction {
    case view(ViewAction)
    enum ViewAction: Equatable {
      case task
      case todoSwipedToDelete(Todo.ID)
      case todoMoved(IndexSet, Int)
      case addTodoButtonTapped
      case deleteCompletedTodosButtonTapped
      case editTodosButtonTapped
      case editTodosDoneButtonTapped
      case selectAllTodosButtonTapped
      case deleteSelectedTodosButtonTapped
    }
    
    case loadTodosSuccess([Todo])
    case sortTodos
    case todos(IdentifiedActionOf<TodoReducer>)
    case binding(BindingAction<State>)
    case alert(PresentationAction<AlertAction>)
    enum AlertAction: Equatable {
      case acceptDeleteSelectedTodosButtonTapped
      case acceptDeleteCompletedTodosButtonTapped
    }
  }
  
  @Dependency(\.uuid) var uuid
  @Dependency(\.continuousClock) var clock
  @Dependency(\.database) var database
  
  enum SortEffectID: Hashable { case cancel }
  
  var body: some Reducer<AppReducer.State, AppReducer.Action> {
    BindingReducer()
    Reduce<AppReducer.State, AppReducer.Action> { state, action in
      switch action {
      case .view(.task):
        guard state.loadStatus == .didNotLoad else { return .none }
        state.loadStatus = .isLoading
        return .run { send in
          await self.database.initializeDatabase()
          let todos = await self.database.retrieveTodos()
          await send(.loadTodosSuccess(todos), animation: .default)
        }
        
      case let .view(.todoSwipedToDelete(id)):
        let todo = state.todos[id: id]!
        state.todos.remove(id: id)
        return .run { send in
          await self.database.deleteTodo(todo.id)
        }
        .concatenate(with: self.setTodosOrderIndicies(&state))
        
      case let .view(.todoMoved(source, destination)):
        state.todos.move(fromOffsets: source, toOffset: destination)
        return self.setTodosOrderIndicies(&state)
        
      case .view(.addTodoButtonTapped):
        let todo = Todo(id: .init(rawValue: uuid()), orderIndex: state.todos.count)
        state.todos.append(.init(todo: todo))
        state.focus = .todo(todo.id)
        return .run { _ in await self.database.createTodo(todo) }
          .concatenate(with: self.setTodosOrderIndicies(&state))

      case .view(.deleteCompletedTodosButtonTapped):
        guard !state.disabledDeleteCompletedTodosButton else { return .none }
        state.alert = .deleteCompletedTodos
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
        guard !state.disabledDeleteSelectedTodosButton else { return .none }
        state.alert = .deleteSelectedTodos
        return .none
        
      case let .loadTodosSuccess(todos):
        state.todos = todos.mapIdentifiable({ .init(todo: $0)})
        state.loadStatus = .didLoad
        return .none
        
      case .sortTodos:
        state.todos.sort { $1.todo.isComplete && !$0.todo.isComplete }
        return self.setTodosOrderIndicies(&state)
        
      case let .todos(.element(id: id, action: .view(.isCompletedToggled))):
        let todo = state.todos[id: id]!.todo
        return .run { send in
          await self.database.updateTodo(todo)
          try await self.clock.sleep(for: .seconds(1))
          await send(.sortTodos, animation: .default)
        }
        .cancellable(id: SortEffectID.cancel, cancelInFlight: true)
        
      case let .todos(.element(id: id, _)):
        let todo = state.todos[id: id]!.todo
        return .run { _ in await self.database.updateTodo(todo) }
        
      case .binding:
        return .none
        
      case let .alert(.presented(action)):
        switch action {
        case .acceptDeleteSelectedTodosButtonTapped:
          let ids = state.selectedTodos
          state.todos = state.todos.filter { !state.selectedTodos.contains($0.id) }
          state.selectedTodos = []
          state.alert = nil
          return .run { _ in
            for id in ids { await self.database.deleteTodo(id) }
          }
          .concatenate(with: self.setTodosOrderIndicies(&state))

          
        case .acceptDeleteCompletedTodosButtonTapped:
          let ids = state.todos.filter({ $0.todo.isComplete }).ids
          state.todos = state.todos.filter { !$0.todo.isComplete }
          state.alert = nil
          return .run { _ in
            for id in ids { await self.database.deleteTodo(id) }
          }
          .concatenate(with: self.setTodosOrderIndicies(&state))

        }
        
      case .alert(.dismiss):
        state.alert = nil
        return .none
      }
    }
    .ifLet(\.alert, action: \.alert) // TODO: ??? Needed????
    .forEach(\.todos, action: \.todos) {
      TodoReducer()
    }
  }
  
  // Sets each Todo order index via ascending order then persists these updates.
  func setTodosOrderIndicies(_ state: inout AppReducer.State) -> EffectOf<AppReducer> {
    state.todos.ids.enumerated().forEach({ index, id in
      state.todos[id: id]?.todo.orderIndex = index
    })
    let todos = state.todos.map(\.todo)
    return .run { _ in
      for todo in todos {
        await self.database.updateTodo(todo)
      }
    }
  }
}

extension AlertState where Action == AppReducer.Action.AlertAction {
  static let deleteSelectedTodos = Self(
    title: { TextState(verbatim: "Delete Selected Todos")},
    actions: {
      ButtonState(role: .destructive, action: .send(.acceptDeleteSelectedTodosButtonTapped, animation: .default)) {
        TextState(verbatim: "Confirm")
      }
    },
    message: { TextState(verbatim: "Are you sure you want to delete the selected todos?")}
  )
  
  static let deleteCompletedTodos = Self(
    title: { TextState(verbatim: "Delete Completed Todos")},
    actions: {
      ButtonState(role: .destructive, action: .send(.acceptDeleteCompletedTodosButtonTapped, animation: .default)) {
        TextState(verbatim: "Confirm")
      }
    },
    message: { TextState(verbatim: "Are you sure you want to delete the completed todos?")}
  )
}


enum LoadStatus: Equatable {
  case didLoad
  case didNotLoad
  case isLoading
}
