import SwiftUI

// This is the main entry point for the Boggle app.
// It sets up the app's structure and initial user interface.

@main // Marks this struct as the app's entry point.
struct BoggleApp: App { // Conforms to the App protocol which defines the app's behavior and lifecycle.
    
    // The body property defines the content and behavior of the app scene(s).
    var body: some Scene {
        // WindowGroup manages a group of windows displaying the app's UI.
        // On iOS and other platforms, it typically represents the main app window.
        WindowGroup {
            ContentView() // The initial view displayed when the app launches.
        }
    }
}
