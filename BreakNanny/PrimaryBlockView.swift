//
//  PrimaryBlockView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI

struct PrimaryBlockView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            switch appState.phase {
            case .idle:
                CodingBlockCard(
                    mode: .form,
                    block: .constant(nil),
                    formIntention: $appState.newBlockIntention,
                    formPreCodeExercisesCompleted: $appState.newBlockPreCodeExercisesCompleted,
                    formCodingDuration: $appState.newBlockCodingDuration,
                    formBreakDuration: $appState.newBlockBreakDuration,
                    onStart: {
                        appState.startCodingBlock()
                    }
                )

            case .activeCoding:
                VStack(spacing: 12) {
                    CodingBlockCard(
                        mode: .activeCoding,
                        block: $appState.activeBlock,
                        formIntention: .constant(""),
                        formPreCodeExercisesCompleted: .constant(false),
                        formCodingDuration: .constant(15 * 60),
                        formBreakDuration: .constant(10 * 60),
                        remainingTime: appState.timeString(from: appState.remainingSeconds)
                    )

                    HStack {
                        Spacer()
                        Button("Done Coding Early") {
                            appState.transitionToBreak()
                        }
                        .buttonStyle(.bordered)
                    }
                }

            case .activeBreak:
                VStack(spacing: 12) {
                    CodingBlockCard(
                        mode: .activeBreak,
                        block: $appState.activeBlock,
                        formIntention: .constant(""),
                        formPreCodeExercisesCompleted: .constant(false),
                        formCodingDuration: .constant(15 * 60),
                        formBreakDuration: .constant(10 * 60),
                        remainingTime: appState.timeString(from: appState.remainingSeconds)
                    )

                    Text("All keyboard input is captured and routed to the reflection field above.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            appState.startInitialFocusEnforcement()
        }
    }
}
