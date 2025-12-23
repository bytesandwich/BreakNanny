//
//  HistoryListView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI

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
                    VStack(spacing: 0) {
                        buildBlockText(for: block)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
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

