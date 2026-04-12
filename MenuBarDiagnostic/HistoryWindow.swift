import AppKit
import SwiftUI

/// Standalone window hosting the History leaderboard view.
/// Use `HistoryWindow.makeWindow(dataStore:)` to create; AppDelegate holds a strong ref
/// and reuses the instance (makeKeyAndOrderFront) on subsequent opens.
final class HistoryWindow: NSWindow {

    static func makeWindow(dataStore: DataStore) -> HistoryWindow {
        let view = HistoryView(dataStore: dataStore)
        let vc = NSHostingController(rootView: view)
        let window = HistoryWindow(contentViewController: vc)
        window.title = "History"
        window.setContentSize(NSSize(width: 600, height: 500))
        window.minSize = NSSize(width: 480, height: 360)
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
