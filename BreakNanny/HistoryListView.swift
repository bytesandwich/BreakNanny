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

    var body: some View {
        Table(activities) {
            TableColumn("App") { activity in
                Text(activity.appName)
                    .lineLimit(1)
            }
            TableColumn("Min") { activity in
                Text("\(activity.activeMinutes)")
            }
            .width(40)
            TableColumn("%") { activity in
                let pct = totalActiveMinutes > 0 ? (activity.activeMinutes * 100) / totalActiveMinutes : 0
                Text("\(pct)%")
            }
            .width(40)
        }
    }
}

struct HistoryListView: View {
    let completedBlocks: [CodingBlock]

    private let systemTextColor = Color.gray
    private let userTextColor = Color.white
    private let cardBackgroundColor = Color(white: 0.15)

    var body: some View {
        if completedBlocks.isEmpty {
            Text("No completed coding blocks yet")
                .foregroundColor(.gray)
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(completedBlocks) { block in
                    HStack(alignment: .top, spacing: 16) {
                        // Left: existing text content
                        buildBlockText(for: block)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Right: activity table (if has data) - 50% width
                        if !block.appActivity.isEmpty {
                            let rowCount = min(block.appActivity.count, 5)
                            let tableHeight = CGFloat(28 + rowCount * 24)  // header + rows
                            ActivityTable(
                                activities: Array(block.appActivity.prefix(5)),
                                totalActiveMinutes: block.totalActiveMinutes
                            )
                            .frame(maxWidth: .infinity, minHeight: tableHeight, maxHeight: tableHeight)
                        }
                    }
                    .padding(12)
                    .background(cardBackgroundColor)
                    .cornerRadius(8)
                }
            }
            .textSelection(.enabled)
        }
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

