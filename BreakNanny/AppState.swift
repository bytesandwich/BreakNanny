//
//  AppState.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import Foundation
import SwiftUI
import AppKit

enum AppPhase {
    case idle
    case activeCoding
    case activeBreak
}

@Observable
class AppState {
    // Current state
    var phase: AppPhase = .idle {
        didSet { statusBarController?.updateStatusBar() }
    }

    // Active block being worked on
    var activeBlock: CodingBlock?

    // Timer state
    var remainingSeconds: Int = 0 {
        didSet { statusBarController?.updateStatusBar() }
    }
    private var timer: Timer?

    // Keyboard capture
    let keyboardCapture = GlobalKeyboardCapture()
    let focusEnforcer = FocusEnforcer()

    // History of completed blocks
    var completedBlocks: [CodingBlock] = []

    // Form state for new block
    var newBlockIntention: String = ""
    var newBlockPreCodeExercisesCompleted: Bool = false
    var newBlockCodingDuration: Int = 25 * 60 // 25 minutes default
    var newBlockBreakDuration: Int = 5 * 60 // 5 minutes default

    // Tracking actual time elapsed
    private var codingStartTime: Date?
    private var breakStartTime: Date?

    // Status bar controller reference
    weak var statusBarController: StatusBarController?

    init() {
        loadHistory()
    }

    // MARK: - Actions

    func startInitialFocusEnforcement() {
        focusEnforcer.start()
    }
    
    func startCodingBlock() {
        focusEnforcer.stop()
        guard !newBlockIntention.isEmpty && newBlockPreCodeExercisesCompleted else { return }

        let block = CodingBlock(
            intendedDescription: newBlockIntention,
            plannedCodingDuration: newBlockCodingDuration,
            plannedBreakDuration: newBlockBreakDuration
        )

        activeBlock = block
        phase = .activeCoding
        remainingSeconds = newBlockCodingDuration
        codingStartTime = Date()

        // Start activity tracking for coding session
        keyboardCapture.startObserveOnly()
        focusEnforcer.startOnlyTrackActiveApp()

        startTimer()

        // Clear form
        newBlockIntention = ""
        newBlockPreCodeExercisesCompleted = false
    }

    func transitionToBreak() {
        guard var block = activeBlock else { return }

        // Calculate actual coding duration
        if let startTime = codingStartTime {
            block.actualCodingDuration = Int(Date().timeIntervalSince(startTime))

            // Capture activity data into the block
            let totalMinutes = Int(Date().timeIntervalSince(startTime) / 60)
            let summaries = ActivityReviewer.calculateActivity(
                appActivations: focusEnforcer.appActivations,
                activeMinutes: keyboardCapture.activeMinutes,
                codingStartTime: startTime
            )

            // Convert to AppActivity and sort by minutes descending
            block.appActivity = summaries
                .sorted { $0.activeMinutes > $1.activeMinutes }
                .map { AppActivity(appName: $0.appName, activeMinutes: $0.activeMinutes) }
            block.totalActiveMinutes = keyboardCapture.activeMinutes.count
            block.totalMinutes = totalMinutes
        }

        // Stop activity tracking and emit summary
        emitCodingActivitySummary()
        keyboardCapture.stopObserveOnly()
        focusEnforcer.stopOnlyTrackActiveApp()

        activeBlock = block
        phase = .activeBreak
        remainingSeconds = block.plannedBreakDuration
        breakStartTime = Date()

        // CRITICAL: Bring window to foreground before starting keyboard capture
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
        NSApp.activate(ignoringOtherApps: true)

        // Start keyboard capture for break
        keyboardCapture.onCharacters = { [weak self] chars, keyCode in
            DispatchQueue.main.async {
                self?.handleBreakInput(chars: chars, keyCode: keyCode)
            }
        }
        keyboardCapture.startBreakLogCapture()

        // Start focus enforcement for break
        focusEnforcer.startEnforceAppFocus()

        startTimer()
    }

    private func emitCodingActivitySummary() {
        guard let startTime = codingStartTime else { return }

        let totalMinutes = Int(Date().timeIntervalSince(startTime) / 60)

        ActivityReviewer.printSummary(
            appActivations: focusEnforcer.appActivations,
            activeMinutes: keyboardCapture.activeMinutes,
            codingStartTime: startTime,
            totalMinutes: totalMinutes
        )
    }

    func completeBreak() {
        guard var block = activeBlock else { return }

        // Calculate actual break duration
        if let startTime = breakStartTime {
            block.actualBreakDuration = Int(Date().timeIntervalSince(startTime))
        }

        // Set completion timestamp
        block.completedAt = Date()

        // Add to history
        completedBlocks.insert(block, at: 0)
        saveHistory()

        // Cleanup
        keyboardCapture.stopBreakLogCapture()
        focusEnforcer.stopEnforceAppFocus()
        stopTimer()
        activeBlock = nil
        phase = .idle
        codingStartTime = nil
        breakStartTime = nil

        // Return to idle mode with focus enforcement
        focusEnforcer.startEnforceAppFocus()
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timerTick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            switch phase {
            case .activeCoding:
                transitionToBreak()
            case .activeBreak:
                completeBreak()
            case .idle:
                break
            }
        }
    }

    // MARK: - Input Handling

    private func handleBreakInput(chars: String, keyCode: CGKeyCode) {
        guard var block = activeBlock else { return }

        switch keyCode {
        case 51: // delete
            if !block.actualDescription.isEmpty {
                block.actualDescription.removeLast()
            }
        case 36: // return key - just add newline
            block.actualDescription.append("\n")
        default:
            if !chars.isEmpty {
                block.actualDescription.append(chars)
            }
        }

        activeBlock = block
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "completedBlocks"),
              let blocks = try? JSONDecoder().decode([CodingBlock].self, from: data) else {
            return
        }
        completedBlocks = blocks
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(completedBlocks) else { return }
        UserDefaults.standard.set(data, forKey: "completedBlocks")
    }

    func clearHistory() {
        completedBlocks = []
        UserDefaults.standard.removeObject(forKey: "completedBlocks")
    }

    // MARK: - Helpers

    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    func durationString(from seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}
