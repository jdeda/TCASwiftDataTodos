import SwiftUI
import ComposableArchitecture

@ViewAction(for: AppReducer.self)
struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  @FocusState var focus: AppReducer.State.Focus?
  var body: some View {
    NavigationStack {
      // TODO: Whenever I delete I cannot select an unselected one for some reason until I click one that is selected?
      // TODO: Test this fancy delete logic
      List(selection: $store.selectedTodos) {
        ForEach(store.scope(state: \.todos, action: \.todos)) { todoStore in
          TodoView(store: todoStore)
            .tag(todoStore.todo.id)
            .swipeActions {
              Button(role: .destructive) {
                send(.todoSwipedToDelete(todoStore.id), animation: .default)
              } label: {
                Image(systemName: "trash")
              }
            }
        }
        .onMove { send(.todoMoved($0, $1), animation: .default) }
        .disabled(store.isEditingTodos)
      }
      .alert($store.scope(state: \.alert, action: \.alert))
      .toolbar { toolbar(store: store) }
      .navigationTitle("Todos")
      .synchronize($store.focus, $focus)
      .environment(\.editMode, .constant(store.isEditingTodos ? .active : .inactive))
      .task { await send(.task, animation: .default).finish() }
    }
  }
}

extension AppView {
  @ToolbarContentBuilder
  func toolbar(store: StoreOf<AppReducer>) -> some ToolbarContent {
    ToolbarItemGroup(placement: .navigationBarLeading) {
      if store.isEditingTodos {
        Button {
          send(.selectAllTodosButtonTapped) // Don't use animation looks weird.
        } label: {
          Text(store.hasSelectedAll ? "Deselect All" : "Select All")
        }
      }
    }
    ToolbarItemGroup(placement: .primaryAction) {
      if store.isEditingTodos {
        Button {
          send(.editTodosDoneButtonTapped, animation: .default)
        } label: {
          Text("Done")
        }
      }
      else {
        Menu {
          Button {
            send(.addTodoButtonTapped, animation: .default)
          } label: {
            Label("Add", systemImage: "plus")
          }
          Button {
            send(.editTodosButtonTapped, animation: .default)
          } label: {
            Label("Edit", systemImage: "pencil")
          }
          Button(role: .destructive) {
            send(.deleteCompletedTodosButtonTapped, animation: .default)
          } label: {
            Label("Delete Completed", systemImage: "trash")
          }
          .disabled(store.disabledDeleteCompletedTodosButton)
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    
    ToolbarItemGroup(placement: .bottomBar) {
      if store.isEditingTodos {
        Spacer()
        Text("\(store.todos.count) todos")
        Spacer()
        Button(role: .destructive) {
          send(.deleteSelectedTodosButtonTapped, animation: .default)
        } label: {
          Text("Delete")
        }
        .disabled(store.disabledDeleteSelectedTodosButton)
      }
      else {
        Text("\(store.todos.count) todos")
      }
    }
  }
}

extension View {
  func synchronize<Value: Equatable>(
    _ first: Binding<Value>,
    _ second: Binding<Value>
  ) -> some View {
    self
      .onChange(of: first.wrappedValue) { old, new in
        second.wrappedValue = new
      }
      .onChange(of: second.wrappedValue) {
        old, new in first.wrappedValue = new
      }
  }
  
  func synchronize<Value: Equatable>(
    _ first: Binding<Value>,
    _ second: FocusState<Value>.Binding
  ) -> some View {
    self
      .onChange(of: first.wrappedValue) { old, new in
        second.wrappedValue = new
      }
      .onChange(of: second.wrappedValue) {
        old, new in first.wrappedValue = new
      }
  }
}

#Preview {
  AppView(store: .init(
    initialState: AppReducer.State(todos: Array.mockTodos.mapIdentifiable({.init(todo: $0)})),
    reducer: AppReducer.init
  ))
}
