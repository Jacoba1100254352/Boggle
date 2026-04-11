import SwiftUI

@main
struct BoggleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(.stack)
        }
    }
}
