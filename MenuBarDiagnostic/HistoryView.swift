import SwiftUI
import AppKit

// MARK: - Period Toggle

enum HistoryPeriod: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"

    var interval: TimeInterval {
        switch self {
        case .sevenDays:  return 7  * 86400
        case .thirtyDays: return 30 * 86400
        }
    }
}

// MARK: - Root View

struct HistoryView: View {
    let dataStore: DataStore

    @State private var period: HistoryPeriod = .sevenDays
    @State private var offenders: [OffenderRecord] = []
    @State private var selectedOffender: OffenderRecord? = nil

    var body: some View {
        if let selected = selectedOffender {
            TimelineDetailView(
                offender: selected,
                dataStore: dataStore,
                since: sinceDate,
                onBack: { selectedOffender = nil }
            )
        } else {
            LeaderboardView(
                offenders: offenders,
                period: $period,
                onSelect: { selectedOffender = $0 }
            )
            .onAppear { loadOffenders() }
            .onChange(of: period) { _ in loadOffenders() }
        }
    }

    private var sinceDate: Date {
        Date().addingTimeInterval(-period.interval)
    }

    private func loadOffenders() {
        let since = sinceDate
        DispatchQueue.global(qos: .userInitiated).async {
            let results = dataStore.topOffenders(since: since)
            DispatchQueue.main.async { offenders = results }
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    let offenders: [OffenderRecord]
    @Binding var period: HistoryPeriod
    let onSelect: (OffenderRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Top Offenders")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Picker("Period", selection: $period) {
                    ForEach(HistoryPeriod.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Insight card
            if let top = offenders.first {
                InsightCardView(offender: top, period: period)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            Divider()

            if offenders.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No alerts in the last \(period.rawValue.lowercased()).")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(Array(offenders.enumerated()), id: \.element.id) { index, offender in
                        OffenderRow(rank: index + 1, offender: offender)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(offender) }
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Insight Card

struct InsightCardView: View {
    let offender: OffenderRecord
    let period: HistoryPeriod

    private var insightText: String {
        let avgMin = Int((offender.avgDurationSeconds / 60).rounded())
        let periodLabel = period == .sevenDays ? "this week" : "this month"
        var text = "\(offender.appName) triggered \(offender.alertCount) alert\(offender.alertCount == 1 ? "" : "s") \(periodLabel)"
        if avgMin > 1 {
            text += ", averaging \(avgMin) minute\(avgMin == 1 ? "" : "s") each"
        } else if offender.avgDurationSeconds >= 60 {
            text += ", averaging about a minute each"
        }
        text += "."
        if offender.restartCount == 0 && offender.quitCount == 0 {
            text += " Consider restarting it when memory gets high."
        } else if offender.restartCount > 0 {
            text += " You've restarted it \(offender.restartCount) time\(offender.restartCount == 1 ? "" : "s") — quitting it when not in use may help."
        }
        return text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 14))
                .padding(.top, 1)
            Text(insightText)
                .font(.callout)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Offender Row

struct OffenderRow: View {
    let rank: Int
    let offender: OffenderRecord

    private var appIcon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: offender.bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(forFile: "")
    }

    private var avgDurationText: String {
        let secs = offender.avgDurationSeconds
        guard secs > 0 else { return "" }
        if secs < 60 { return String(format: "%.0f sec avg", secs) }
        let mins = secs / 60
        if mins < 60 { return String(format: "%.0f min avg", mins) }
        return String(format: "%.1f hr avg", mins / 60)
    }

    private var lastAlertText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: offender.lastAlertAt, relativeTo: Date())
    }

    private var actionSummary: String {
        var parts: [String] = []
        if offender.restartCount > 0 { parts.append("Restarted \(offender.restartCount)×") }
        if offender.quitCount    > 0 { parts.append("Quit \(offender.quitCount)×") }
        if offender.ignoreCount  > 0 { parts.append("Ignored \(offender.ignoreCount)×") }
        return parts.isEmpty ? "No action taken" : parts.joined(separator: "  ")
    }

    var body: some View {
        HStack(spacing: 10) {
            // Rank
            Text("#\(rank)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)

            // App icon
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: 24, height: 24)

            // Name + action summary
            VStack(alignment: .leading, spacing: 2) {
                Text(offender.appName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(actionSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Metrics
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(offender.alertCount) alert\(offender.alertCount == 1 ? "" : "s")")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(offender.alertCount >= 5 ? .orange : .primary)
                if !avgDurationText.isEmpty {
                    Text(avgDurationText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(lastAlertText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Timeline Detail View

struct TimelineDetailView: View {
    let offender: OffenderRecord
    let dataStore: DataStore
    let since: Date
    let onBack: () -> Void

    @State private var entries: [AlertTimelineEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                HStack(spacing: 6) {
                    let icon = appIcon
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(offender.appName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Balance the back button width
                Text("Back")
                    .font(.callout)
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if entries.isEmpty {
                Spacer()
                Text("No events recorded for this period.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                List(entries) { entry in
                    TimelineEntryRow(entry: entry)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                }
                .listStyle(.plain)
            }
        }
        .onAppear { loadEntries() }
    }

    private var appIcon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: offender.bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(forFile: "")
    }

    private func loadEntries() {
        DispatchQueue.global(qos: .userInitiated).async {
            let results = dataStore.alertTimeline(bundleID: offender.bundleID, since: since)
            DispatchQueue.main.async { entries = results }
        }
    }
}

// MARK: - Timeline Entry Row

struct TimelineEntryRow: View {
    let entry: AlertTimelineEntry

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.startedAt)
    }

    private var durationText: String? {
        guard let ended = entry.endedAt else { return nil }
        let secs = ended.timeIntervalSince(entry.startedAt)
        if secs < 60 { return String(format: "%.0f sec", secs) }
        let mins = secs / 60
        if mins < 60 { return String(format: "%.0f min", mins) }
        return String(format: "%.1f hr", mins / 60)
    }

    private var memoryText: String {
        if entry.peakMemoryMB >= 1024 {
            return String(format: "%.1f GB peak", entry.peakMemoryMB / 1024)
        }
        return String(format: "%.0f MB peak", entry.peakMemoryMB)
    }

    private var actionLabel: String {
        guard let action = entry.userAction, !action.isEmpty else { return "No action" }
        switch action.lowercased() {
        case "restarted": return "You restarted"
        case "quit":      return "You quit"
        case "ignored":   return "You ignored"
        default:          return action.capitalized
        }
    }

    private var resolutionLabel: String {
        guard let duration = durationText else { return "Still active" }
        let action = entry.userAction?.lowercased() ?? ""
        if action.isEmpty {
            return "Self-resolved after \(duration)"
        }
        return "Resolved in \(duration)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timestampText)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(memoryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 170, alignment: .leading)

            Divider()
                .frame(height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(actionLabel)
                    .font(.callout)
                Text(resolutionLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
