import SwiftUI

extension ProcessInfo.ThermalState {
    var thermalLabel: String {
        switch self {
        case .nominal:    return "Nominal"
        case .fair:       return "Fair"
        case .serious:    return "Serious"
        case .critical:   return "Critical"
        @unknown default: return "Unknown"
        }
    }

    var thermalIcon: String {
        switch self {
        case .nominal:    return "thermometer.low"
        case .fair:       return "thermometer.medium"
        case .serious:    return "thermometer.high"
        case .critical:   return "thermometer.sun.fill"
        @unknown default: return "thermometer"
        }
    }

    var thermalColor: Color {
        switch self {
        case .nominal:    return .green
        case .fair:       return .yellow
        case .serious:    return .orange
        case .critical:   return .red
        @unknown default: return .secondary
        }
    }
}
