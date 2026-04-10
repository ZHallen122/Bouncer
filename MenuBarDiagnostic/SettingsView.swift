import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: PreferencesManager

    var body: some View {
        Form {
            Section {
                Picker("Sensitivity:", selection: $prefs.sensitivity) {
                    ForEach(Sensitivity.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Alerts")
            } footer: {
                Text("Controls how aggressively Bouncer flags memory anomalies. Higher sensitivity may produce more alerts.")
                    .foregroundColor(.secondary)
            }

            Section {
                TextField("Ignore Apps:", text: $prefs.ignoredBundleIDsRaw, prompt: Text("com.example.App, …"))
                    .font(.caption.monospaced())
            } header: {
                Text("Exclusions")
            } footer: {
                Text("Comma-separated bundle IDs. Matching apps are excluded from anomaly scanning.")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
                Toggle("Show Memory Pressure", isOn: $prefs.showMemoryPressureInMenuBar)
            } header: {
                Text("System")
            } footer: {
                Text("Automatically start Bouncer when you log in. Memory Pressure shows RAM usage % next to the menu bar icon.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420, height: 360)
    }
}
