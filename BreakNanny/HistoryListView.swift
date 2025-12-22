//
//  HistoryListView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI

struct HistoryListView: View {
    let completedBlocks: [CodingBlock]

    var body: some View {
        VStack(spacing: 12) {
            if completedBlocks.isEmpty {
                Text("No completed coding blocks yet")
                    .foregroundColor(.gray)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(completedBlocks) { block in
                    HistoricalBlockCard(block: block)
                }
            }
        }
    }
}

struct HistoricalBlockCard: View {
    let block: CodingBlock

    private let systemTextColor = Color.gray
    private let userTextColor = Color.white
    private let cardBackgroundColor = Color(white: 0.15)

    var body: some View {
        VStack(spacing: 0) {
            // Top Section: Coding Info
            VStack(alignment: .leading, spacing: 8) {
                Text(block.intendedDescription)
                    .foregroundColor(userTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("\(durationString(from: block.actualCodingDuration)) of coding")
                        .foregroundColor(systemTextColor)
                }
            }
            .padding(12)

            // Divider with vertical padding
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 12)
                Divider()
                    .background(systemTextColor.opacity(0.3))
                Spacer()
                    .frame(height: 12)
            }
            .padding(.horizontal, 12)

            // Bottom Section: Break Info
            VStack(alignment: .leading, spacing: 8) {
                if !block.actualDescription.isEmpty {
                    Text(block.actualDescription)
                        .foregroundColor(userTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Coding Block Reflection")
                        .foregroundColor(systemTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Text("\(durationString(from: block.actualBreakDuration)) of break")
                        .foregroundColor(systemTextColor)
                }
            }
            .padding(12)
        }
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }

    private func durationString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}
