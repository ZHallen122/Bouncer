import SwiftUI

@main
struct MenuBarDiagnosticApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — menu bar agent only
        Settings { EmptyView() }
    }
}
