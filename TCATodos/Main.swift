import SwiftUI

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      AppView(store: .init(
        initialState: AppReducer.State(todos: .init(uniqueElements: Array.mockTodos)),
        reducer: AppReducer.init
      ))
    }
  }
}
