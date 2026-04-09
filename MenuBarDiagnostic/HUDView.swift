import SwiftUI
import AppKit
import Darwin

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

// MARK: - Thermal Header

struct ThermalHeaderView: View {
    let thermalState: ProcessInfo.ThermalState
    let systemCPUFraction: Double
    let systemRAMUsedBytes: UInt64
    let systemRAMTotalBytes: UInt64

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [thermalColor.opacity(0.55), thermalColor.opacity(0.15)]),
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu Bar Diagnostic")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Label(thermalLabel, systemImage: thermalIcon)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    // Thermal heatmap block
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(thermalColor)
                            .shadow(color: thermalColor.opacity(0.6), radius: 8)
                        Text(thermalLabel)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .frame(width: 62, height: 28)
                }
                SystemSummaryRow(
                    cpuFraction: systemCPUFraction,
                    ramUsedBytes: systemRAMUsedBytes,
                    ramTotalBytes: systemRAMTotalBytes
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    // MARK: - System Summary Row

    struct SystemSummaryRow: View {
        let cpuFraction: Double
        let ramUsedBytes: UInt64
        let ramTotalBytes: UInt64

        var body: some View {
            HStack {
                Text(String(format: "CPU: %.1f%%", cpuFraction * 100))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text(ramString)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.9))
            }
        }

        private var ramString: String {
            let usedGB = Double(ramUsedBytes) / 1_073_741_824
            let totalGB = Double(ramTotalBytes) / 1_073_741_824
            if totalGB > 0 {
                return String(format: "RAM: %.1f / %.0f GB", usedGB, totalGB)
            }
            return String(format: "RAM: %.1f GB", usedGB)
        }
    }

    private var thermalLabel: String {
        switch thermalState {
        case .nominal:   return "Nominal"
        case .fair:      return "Fair"
        case .serious:   return "Serious"
        case .critical:  return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalIcon: String {
        switch thermalState {
        case .nominal:   return "thermometer.low"
        case .fair:      return "thermometer.medium"
        case .serious:   return "thermometer.high"
        case .critical:  return "thermometer.sun.fill"
        @unknown default: return "thermometer"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case .nominal:   return .green
        case .fair:      return .yellow
        case .serious:   return .orange
        case .critical:  return .red
        @unknown default: return .secondary
        }
    }
}

// MARK: - HUD Process Row

struct HUDProcessRow: View {
    let process: MenuBarProcess
    var cpuAlertThreshold: Double = 0.05
    var ramAlertThresholdMB: Double = 200.0

    @State private var pulse = false
    @State private var showDetail = false

    private var isHogging: Bool {
        process.cpuFraction > cpuAlertThreshold ||
        process.residentMemoryBytes > UInt64(ramAlertThresholdMB * 1024 * 1024)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top: icon + name + chevron + CPU%
            HStack(spacing: 8) {
                iconView
                Text(process.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(isHogging ? .white : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(cpuString)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(isHogging ? .white : cpuTextColor)
            }

            // Sparkline: last 20 CPU samples
            SparklineView(values: process.cpuHistory)
                .frame(height: 22)
                .animation(.easeInOut(duration: 0.35), value: process.cpuHistory)

            // RAM bar
            RAMBarView(bytes: process.residentMemoryBytes, maxBytes: 500 * 1024 * 1024)
                .frame(height: 4)

            // RAM label
            Text(memoryString)
                .font(.caption2.monospacedDigit())
                .foregroundColor(isHogging ? .white.opacity(0.85) : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(rowBackground)
        .shadow(
            color: .red.opacity(isHogging ? (pulse ? 0.75 : 0.15) : 0),
            radius: isHogging ? (pulse ? 14 : 3) : 0
        )
        .onAppear {
            if isHogging {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            ProcessDetailSheet(process: process)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon = process.icon {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: "app.fill")
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isHogging {
            Color.red.opacity(0.30)
        } else {
            Color.clear
        }
    }

    private var cpuString: String {
        String(format: "%.1f%%", process.cpuFraction * 100)
    }

    private var cpuTextColor: Color {
        switch process.cpuFraction {
        case ..<0.05: return .primary
        case ..<0.25: return .orange
        default:      return .red
        }
    }

    private var memoryString: String {
        let mb = Double(process.residentMemoryBytes) / 1_048_576
        if mb < 1_000 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1_024)
        }
    }
}

// MARK: - Process Detail Sheet

struct ProcessDetailSheet: View {
    let process: MenuBarProcess
    @Environment(\.dismiss) var dismiss
    @State private var openFileCount: Int? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if let icon = process.icon {
                    Image(nsImage: icon).resizable().frame(width: 48, height: 48)
                }
                VStack(alignment: .leading) {
                    Text(process.name).font(.title2.bold())
                    Text("PID: \(process.pid)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            Divider()
            // Stats grid
            VStack(alignment: .leading, spacing: 8) {
                if let date = process.launchDate {
                    LabeledContent("Launch Time", value: date, format: .dateTime.hour().minute().second())
                }
                LabeledContent("CPU", value: String(format: "%.1f%%", process.cpuFraction * 100))
                let mb = Double(process.residentMemoryBytes) / 1_048_576
                LabeledContent("RAM", value: String(format: "%.0f MB", mb))
                if let fds = openFileCount {
                    LabeledContent("Open Files", value: "\(fds)")
                } else {
                    LabeledContent("Open Files", value: "loading…")
                }
            }
            Divider()
            // Kill button
            Button(role: .destructive) {
                kill(process.pid, SIGTERM)
                dismiss()
            } label: {
                Label("Kill Process", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(20)
        .frame(width: 320)
        .onAppear {
            let pid = process.pid
            DispatchQueue.global().async {
                let size = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
                let count = size > 0 ? Int(size) / MemoryLayout<proc_fdinfo>.size : 0
                DispatchQueue.main.async { openFileCount = count }
            }
        }
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background fill
                if values.count >= 2 {
                    fillPath(in: geo.size)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    linePath(in: geo.size)
                        .stroke(Color.blue.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.08))
                        .cornerRadius(2)
                }
            }
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        let maxVal = max(values.max() ?? 0.01, 0.01)
        let step = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { i, val in
            CGPoint(
                x: CGFloat(i) * step,
                y: size.height - CGFloat(val / maxVal) * size.height
            )
        }
    }

    private func linePath(in size: CGSize) -> Path {
        var path = Path()
        let pts = points(in: size)
        guard let first = pts.first else { return path }
        path.move(to: first)
        pts.dropFirst().forEach { path.addLine(to: $0) }
        return path
    }

    private func fillPath(in size: CGSize) -> Path {
        var path = Path()
        let pts = points(in: size)
        guard let first = pts.first else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        pts.dropFirst().forEach { path.addLine(to: $0) }
        if let last = pts.last {
            path.addLine(to: CGPoint(x: last.x, y: size.height))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - RAM Bar

struct RAMBarView: View {
    let bytes: UInt64
    let maxBytes: UInt64

    private var fraction: Double {
        min(Double(bytes) / Double(maxBytes), 1.0)
    }

    private var barColor: Color {
        switch fraction {
        case ..<0.4:  return .green
        case ..<0.7:  return .yellow
        case ..<0.9:  return .orange
        default:      return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(barColor)
                    .frame(width: max(geo.size.width * fraction, 2))
            }
        }
    }
}
