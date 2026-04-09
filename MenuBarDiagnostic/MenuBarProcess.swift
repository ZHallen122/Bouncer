import AppKit
import SwiftUI

struct MenuBarProcess: Identifiable {
    var id: pid_t { pid }
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?
    let cpuFraction: Double
    let cpuHistory: [Double]      // rolling buffer of last 20 CPU fraction samples
    let residentMemoryBytes: UInt64
    let thermalState: ProcessInfo.ThermalState
    let launchDate: Date?

    var cpuString: String {
        String(format: "%.1f%%", cpuFraction * 100)
    }

    var cpuColor: Color {
        switch cpuFraction {
        case ..<0.05: return .primary
        case ..<0.25: return .orange
        default:      return .red
        }
    }

    var memoryString: String {
        let mb = Double(residentMemoryBytes) / 1_048_576
        if mb < 1_000 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1_024)
        }
    }
}
