import SwiftUI
import ComposableArchitecture

@ViewAction(for: TodoReducer.self)
struct TodoView: View {
  @Bindable var store: StoreOf<TodoReducer>
  
  var body: some View {
    HStack {
      Button {
        send(.isCompletedToggled, animation: .default)
      } label: {
        Image(systemName: store.todo.isComplete ? "checkmark.square" : "square")
      }
      .buttonStyle(.plain)
      TextField("...", text: $store.todo.description)
      Spacer()
    }
    .foregroundColor(store.todo.isComplete ? .secondary : .primary)
  }
}

#Preview {
  TodoView(store: .init(initialState: TodoReducer.State(todo: .mockTodo), reducer: TodoReducer.init))
}
