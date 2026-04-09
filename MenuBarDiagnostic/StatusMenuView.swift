import SwiftUI

/// SwiftUI view used as the popover/content for the status menu.
/// Currently reserved for future use — the live menu is built in AppDelegate.
struct StatusMenuView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Bar Diagnostic")
                .font(.headline)
            Divider()
            Text("Running")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 220)
    }
}

#Preview {
    StatusMenuView()
}
