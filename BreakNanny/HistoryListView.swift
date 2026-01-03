//
//  HistoryListView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI

struct ActivityTable: View {
    let activities: [AppActivity]
    let totalActiveMinutes: Int

    private let headerColor = Color.gray

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            // Header row
            GridRow {
                Text("App")
                    .foregroundColor(headerColor)
                Text("Min")
                    .foregroundColor(headerColor)
                    .frame(width: 40, alignment: .leading)
                Text("%")
                    .foregroundColor(headerColor)
                    .frame(width: 40, alignment: .leading)
            }
            .font(.caption)

            Divider()

            // Data rows
            ForEach(activities) { activity in
                GridRow {
                    Text(activity.appName)
                        .lineLimit(1)
                    Text("\(activity.activeMinutes)")
                        .frame(width: 40, alignment: .leading)
                    let pct = totalActiveMinutes > 0 ? (activity.activeMinutes * 100) / totalActiveMinutes : 0
                    Text("\(pct)%")
                        .frame(width: 40, alignment: .leading)
                }
                .font(.callout)
            }
        }
    }
}

private struct DayGroup: Identifiable {
    let id: Date // startOfDay
    let blocks: [CodingBlock]

    var totalActiveMinutes: Int {
        blocks.reduce(0) { $0 + $1.totalActiveMinutes }
    }

    var totalMinutes: Int {
        blocks.reduce(0) { $0 + ($1.actualCodingDuration + $1.actualBreakDuration) / 60 }
    }
}

struct HistoryListView: View {
    let completedBlocks: [CodingBlock]

    @State private var expandedDays: Set<Date> = []
    @State private var initializedExpansion = false

    private let systemTextColor = Color.gray
    private let userTextColor = Color.white
    private let cardBackgroundColor = Color(white: 0.15)

    private var dayGroups: [DayGroup] {
        guard !completedBlocks.isEmpty else { return [] }

        var groups: [DayGroup] = []
        var currentDayStart: Date?
        var currentBlocks: [CodingBlock] = []

        for block in completedBlocks {
            guard let completedAt = block.completedAt else { continue }
            let dayStart = Calendar.current.startOfDay(for: completedAt)

            if dayStart == currentDayStart {
                currentBlocks.append(block)
            } else {
                if let currentDay = currentDayStart, !currentBlocks.isEmpty {
                    groups.append(DayGroup(id: currentDay, blocks: currentBlocks))
                }
                currentDayStart = dayStart
                currentBlocks = [block]
            }
        }

        if let currentDay = currentDayStart, !currentBlocks.isEmpty {
            groups.append(DayGroup(id: currentDay, blocks: currentBlocks))
        }

        return groups
    }

    var body: some View {
        if completedBlocks.isEmpty {
            Text("No completed coding blocks yet")
                .foregroundColor(.gray)
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(dayGroups) { group in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedDays.contains(group.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedDays.insert(group.id)
                                } else {
                                    expandedDays.remove(group.id)
                                }
                            }
                        )
                    ) {
                        VStack(spacing: 12) {
                            ForEach(group.blocks) { block in
                                blockCard(for: block)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Text(formatDayHeader(group.id))
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(group.totalActiveMinutes)m active / \(group.totalMinutes)m total")
                                .foregroundColor(systemTextColor)
                        }
                    }
                }
            }
            .textSelection(.enabled)
            .onAppear {
                if !initializedExpansion {
                    let today = Calendar.current.startOfDay(for: Date())
                    expandedDays.insert(today)
                    initializedExpansion = true
                }
            }
        }
    }

    @ViewBuilder
    private func blockCard(for block: CodingBlock) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: existing text content
            buildBlockText(for: block)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right: activity table (if has data)
            if !block.appActivity.isEmpty {
                ActivityTable(
                    activities: Array(block.appActivity.prefix(5)),
                    totalActiveMinutes: block.totalActiveMinutes
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(12)
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }

    private func buildBlockText(for block: CodingBlock) -> Text {
        var attributedString = AttributedString()

        // Timestamp
        if let completedAt = block.completedAt {
            var timestamp = AttributedString(formatTimestamp(completedAt) + " ")
            timestamp.foregroundColor = systemTextColor
            attributedString.append(timestamp)
        }

        // Intended description
        var intended = AttributedString(block.intendedDescription)
        intended.foregroundColor = userTextColor
        attributedString.append(intended)

        attributedString.append(AttributedString("\n"))

        // Coding duration
        var codingDuration = AttributedString("\(durationString(from: block.actualCodingDuration)) of coding")
        codingDuration.foregroundColor = systemTextColor
        attributedString.append(codingDuration)

        attributedString.append(AttributedString("\n\n"))

        // Actual description
        if !block.actualDescription.isEmpty {
            var actual = AttributedString(block.actualDescription)
            actual.foregroundColor = userTextColor
            attributedString.append(actual)
        } else {
            var placeholder = AttributedString("Coding Block Reflection")
            placeholder.foregroundColor = systemTextColor
            attributedString.append(placeholder)
        }

        attributedString.append(AttributedString("\n"))

        // Break duration
        var breakDuration = AttributedString("\(durationString(from: block.actualBreakDuration)) of break")
        breakDuration.foregroundColor = systemTextColor
        attributedString.append(breakDuration)

        return Text(attributedString)
    }

    private func formatDayHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d h:mma"
        let formatted = formatter.string(from: date)
        return formatted.replacingOccurrences(of: "AM", with: "am")
                        .replacingOccurrences(of: "PM", with: "pm")
    }

    private func durationString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}
