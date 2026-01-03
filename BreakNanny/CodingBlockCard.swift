//
//  CodingBlockCard.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI

enum BlockDisplayMode {
    case form // New block form (Idle state)
    case activeCoding // During coding
    case activeBreak // During break
    case historical // Completed block in history
}

struct CodingBlockCard: View {
    let mode: BlockDisplayMode
    @Binding var block: CodingBlock?
    @Binding var formIntention: String
    @Binding var formPreCodeExercisesCompleted: Bool
    @Binding var formCodingDuration: Int
    @Binding var formBreakDuration: Int
    var remainingTime: String = ""
    var onStart: (() -> Void)?

    // Color scheme
    private let systemTextColor = Color.gray
    private let userTextColor = Color.white
    private let cardBackgroundColor = Color(white: 0.15)

    var body: some View {
        VStack(spacing: 0) {
            // Top Section: Coding Info
            VStack(alignment: .leading, spacing: 8) {
                switch mode {
                case .form:
                    ZStack(alignment: .leading) {
                        if formIntention.isEmpty {
                            Text("New Coding Block")
                                .foregroundColor(systemTextColor)
                        }
                        TextField("", text: $formIntention)
                            .textFieldStyle(.plain)
                            .foregroundColor(userTextColor)
                            .onSubmit {
                                if !formIntention.isEmpty && formPreCodeExercisesCompleted {
                                    onStart?()
                                }
                            }
                    }
                    Toggle("Pre-code exercises completed", isOn: $formPreCodeExercisesCompleted)
                        .toggleStyle(.checkbox)
                        .foregroundColor(systemTextColor)
                default:
                    Text(block?.intendedDescription ?? "")
                        .foregroundColor(userTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    switch mode {
                    case .form:
                        Picker("", selection: $formCodingDuration) {
                            Text("25m").tag(25 * 60)
                            Text("45m").tag(45 * 60)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: formCodingDuration) { oldValue, newValue in
                            // Link coding duration to break duration
                            if newValue == 25 * 60 {
                                formBreakDuration = 5 * 60
                            } else if newValue == 45 * 60 {
                                formBreakDuration = 10 * 60
                            }
                        }

                        Text("of coding")
                            .foregroundColor(systemTextColor)
                    case .activeCoding:
                        Text(remainingTime)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(userTextColor)
                        Text("of coding")
                            .foregroundColor(systemTextColor)
                    case .activeBreak, .historical:
                        if let block = block {
                            Text("\(block.totalActiveMinutes)m active / \(block.totalMinutes)m total of coding")
                                .foregroundColor(systemTextColor)
                        }
                    }
                }
            }
            .padding(12)

            // Divider with vertical padding
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 3)
                Divider()
                    .background(systemTextColor.opacity(0.3))
                Spacer()
                    .frame(height: 3)
            }
            .padding(.horizontal, 12)

            // Bottom Section: Break Info
            VStack(alignment: .leading, spacing: 8) {
                switch mode {
                case .form, .activeCoding:
                    Text("Coding Block Reflection")
                        .foregroundColor(systemTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .activeBreak:
                    if let actualDesc = block?.actualDescription, !actualDesc.isEmpty {
                        Text(actualDesc)
                            .foregroundColor(userTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 40, alignment: .topLeading)
                    } else {
                        Text("Coding Block Reflection")
                            .foregroundColor(systemTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 40, alignment: .topLeading)
                    }
                case .historical:
                    if let actualDesc = block?.actualDescription, !actualDesc.isEmpty {
                        Text(actualDesc)
                            .foregroundColor(userTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Coding Block Reflection")
                            .foregroundColor(systemTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                HStack {
                    switch mode {
                    case .form:
                        Picker("", selection: $formBreakDuration) {
                            Text("5m").tag(5 * 60)
                            Text("10m").tag(10 * 60)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: formBreakDuration) { oldValue, newValue in
                            // Link break duration to coding duration
                            if newValue == 5 * 60 {
                                formCodingDuration = 25 * 60
                            } else if newValue == 10 * 60 {
                                formCodingDuration = 45 * 60
                            }
                        }

                        Text("of break")
                            .foregroundColor(systemTextColor)
                    case .activeBreak:
                        Text(remainingTime)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(userTextColor)
                        Text("of break")
                            .foregroundColor(systemTextColor)
                    case .activeCoding, .historical:
                        if let block = block {
                            let duration = mode == .activeCoding ? block.plannedBreakDuration : block.actualBreakDuration
                            Text("\(durationString(from: duration)) of break")
                                .foregroundColor(systemTextColor)
                        }
                    }
                }
            }
            .padding(12)

            // Start button for form mode
            if mode == .form {
                HStack {
                    Spacer()
                    Button("Start Coding Block") {
                        onStart?()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(formIntention.isEmpty || !formPreCodeExercisesCompleted)
                }
                .padding(12)
            }
        }
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }

    private func durationString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}
