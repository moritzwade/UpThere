import SwiftUI

@main
struct UpThereApp: App {
    @State private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
    }
}
