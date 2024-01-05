import SwiftUI
import ComposableArchitecture

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  @FocusState var focus: AppReducer.State.Focus?
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.todos) { todo in
          HStack {
            Button {
              store.send(.todoIsCompletedToggled(todo.id), animation: .default)
            } label: {
              Image(systemName: todo.isComplete ? "checkmark.square" : "square")
            }
            .buttonStyle(.plain)
            TextField("...", text: .init(
              get: { todo.description },
              set: { store.send(.todoDescriptionEdited(todo.id, $0), animation: .default)})
            )
            .focused($focus, equals: .todo(todo.id))
            Spacer()
          }
          .foregroundColor(todo.isComplete ? .secondary : .primary)
        }
        .onDelete { store.send(.todoSwipedToDelete($0), animation: .default) }
        .onMove { store.send(.todoMoved($0, $1), animation: .default) }
      }
      .navigationTitle("Todos")
      .synchronize($store.focus, $focus)
      .toolbar { toolbar(store: store) }
    }
  }
}

extension AppView {
  @ToolbarContentBuilder
  func toolbar(store: StoreOf<AppReducer>) -> some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Menu {
        Button {
          store.send(.addTodoButtonTapped, animation: .default)
        } label: {
          Label("Add", systemImage: "plus")
        }
        Button {
          // TODO: ...
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) {
          store.send(.deleteCompletedTodosButtonTapped, animation: .default)
        } label: {
          Label("Delete Completed", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
    }
    
    ToolbarItemGroup(placement: .bottomBar) {
      Text("\(store.todos.count) todos")
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
    initialState: AppReducer.State(todos: .init(uniqueElements: Array.mockTodos)),
    reducer: AppReducer.init
  ))
}
