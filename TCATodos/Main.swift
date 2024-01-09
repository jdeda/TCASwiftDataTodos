import SwiftUI
import ComposableArchitecture

@main
struct Main: App {
  var body: some Scene {
    WindowGroup {
      if _XCTIsTesting {
        Text("_XCTIsTesting")
      }
      else {
        AppView(store: .init(
          initialState: AppReducer.State(),
          reducer: AppReducer.init
        ))
      }
    }
  }
}
