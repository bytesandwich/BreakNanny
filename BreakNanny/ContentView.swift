//
//  ContentView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI
import ApplicationServices

final class InputEventTapLock {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard eventTap == nil else { return }

        let mask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, _ in
            // Drop all keyboard and mouse events
            return nil
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: nil
        ) else {
            print("Failed to create keyboard event tap")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            tap,
            0
        )

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            runLoopSource,
            .commonModes
        )

        CGEvent.tapEnable(tap: tap, enable: true)
        print("Keyboard + mouse event tap enabled")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                source,
                .commonModes
            )
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        runLoopSource = nil
        eventTap = nil
        print("Keyboard + mouse event tap disabled")
    }
}

struct ContentView: View {
    @State private var isRunning = false
    @State private var selectedDurationSeconds = 10 * 60
    @State private var remainingSeconds = 10 * 60
    @State private var timer: Timer?
    @State private var keyboardLock = InputEventTapLock()

    private let availableDurations: [Int] = [
        3,
        5 * 60,
        10 * 60,
        15 * 60,
        25 * 60
    ]

    var body: some View {
        VStack(spacing: 12) {
            if isRunning {
                Text(timeString(from: remainingSeconds))
                    .font(.system(.title, design: .monospaced))
            } else {
                Picker("Duration", selection: $selectedDurationSeconds) {
                    ForEach(availableDurations, id: \.self) { seconds in
                        if seconds < 60 {
                            Text("\(seconds) sec").tag(seconds)
                        } else {
                            Text("\(seconds / 60) min").tag(seconds)
                        }
                    }
                }
                .pickerStyle(.segmented)

                Button("Start break") {
                    startTimer()
                }
            }
        }
        .padding()
        .frame(minWidth: 220)
    }

    private func startTimer() {
        keyboardLock.start()
        isRunning = true
        remainingSeconds = selectedDurationSeconds

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        keyboardLock.stop()
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
