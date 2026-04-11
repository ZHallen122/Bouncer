import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: PreferencesManager
    var anomalyDetector: AnomalyDetector

    var body: some View {
        Form {
            Section {
                Picker("Sensitivity", selection: $prefs.sensitivity) {
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
                TextField("Ignore Apps", text: $prefs.ignoredBundleIDsRaw, prompt: Text("com.example.App, …"))
                    .font(.caption.monospaced())
            } header: {
                Text("Exclusions")
            } footer: {
                Text("Comma-separated bundle IDs. Matching apps are excluded from anomaly scanning.")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
            } header: {
                Text("System")
            } footer: {
                Text("Starts Bouncer automatically when you log in.")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Show Memory Pressure", isOn: $prefs.showMemoryPressureInMenuBar)
            } footer: {
                Text("Displays RAM usage % next to the menu bar icon.")
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Testing Mode", isOn: $prefs.testingMode)
                if prefs.testingMode {
                    Button("Fire Test Alert Now") {
                        anomalyDetector.fireTestAlert()
                    }
                }
                Button("Reset Learning Period") {
                    prefs.resetLearningPeriod()
                }
                if prefs.isInLearningPeriod {
                    Text("In learning period — \(prefs.learningPeriodRemainingHours) h remaining")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Text("Learning period complete")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("Developer")
            } footer: {
                Text(prefs.testingMode
                     ? "Testing Mode ON: learning period, memory pressure, and time windows are bypassed. Use \"Fire Test Alert Now\" for an instant notification. Turn Testing Mode OFF after resetting to verify that alerts are suppressed during the 3-day window."
                     : "\"Reset Learning Period\" restarts the 3-day window (keep Testing Mode OFF) to verify that no alerts fire while learning is active.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420, height: prefs.testingMode ? 480 : 450)
    }
}
