import SwiftUI
import ComposableArchitecture

struct AppView: View {
  let store: StoreOf<AppReducer>
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
            Spacer()
          }
          .foregroundColor(todo.isComplete ? .secondary : .primary)
        }
        .onDelete { store.send(.todoSwipedToDelete($0), animation: .default) }
        .onMove { store.send(.todoMoved($0, $1), animation: .default) }
      }
      .navigationTitle("Todos")
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
  }
}

#Preview {
  AppView(store: .init(
    initialState: AppReducer.State(todos: .init(uniqueElements: Array.mockTodos)),
    reducer: AppReducer.init
  ))
}
