import SwiftUI
import AppKit

// MARK: - HUDView (root)

struct HUDView: View {
    @ObservedObject var monitor: ProcessMonitor
    @ObservedObject var prefs: PreferencesManager
    @State private var gradientRotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ThermalHeaderView(
                thermalState: currentThermalState,
                systemCPUFraction: monitor.systemCPUFraction,
                systemRAMUsedBytes: monitor.systemRAMUsedBytes,
                systemRAMTotalBytes: monitor.systemRAMTotalBytes
            )
            Divider().opacity(0.4)
            processListView
        }
        .frame(width: 360, height: 500)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .cyan, .purple, .blue]),
                        center: .center,
                        angle: .degrees(gradientRotation)
                    ),
                    lineWidth: 2
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }

    private var currentThermalState: ProcessInfo.ThermalState {
        monitor.processes.first?.thermalState ?? ProcessInfo.processInfo.thermalState
    }

    @ViewBuilder
    private var processListView: some View {
        if monitor.processes.isEmpty {
            Text("No menu bar processes found")
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(monitor.processes) { process in
                        HUDProcessRow(
                            process: process,
                            cpuAlertThreshold: prefs.cpuAlertThreshold,
                            ramAlertThresholdMB: prefs.ramAlertThresholdMB
                        )
                        .id(process.pid)
                        Divider().opacity(0.25)
                    }
                }
            }
        }
    }
}
