import SwiftUI

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      AppView(store: .init(
        initialState: AppReducer.State(todos: Array.mockTodos.mapIdentifiable({.init(todo: $0)})),
        reducer: AppReducer.init
      ))
    }
  }
}
