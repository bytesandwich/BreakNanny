//
//  ContentView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI
import ApplicationServices

final class GlobalKeyboardCapture {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onCharacters: ((String, CGKeyCode) -> Void)?

    func start() {
        guard eventTap == nil else { return }

        let mask =
            (CGEventMask(1) << CGEventType.keyDown.rawValue) |
            (CGEventMask(1) << CGEventType.keyUp.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseUp.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseUp.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseUp.rawValue) |
            (CGEventMask(1) << CGEventType.mouseMoved.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseDragged.rawValue) |
            (CGEventMask(1) << CGEventType.scrollWheel.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return nil }

            // Only process characters for keyDown; all other events are swallowed
            if type != .keyDown {
                return nil
            }

            let capture = Unmanaged<GlobalKeyboardCapture>
                .fromOpaque(refcon)
                .takeUnretainedValue()

            // Extract keycode
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

            // Extract Unicode text (if any) from the keyDown event
            var buffer = [UniChar](repeating: 0, count: 8)
            var actualLength: Int = 0
            event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &actualLength, unicodeString: &buffer)

            if actualLength > 0 {
                let s = String(utf16CodeUnits: buffer, count: actualLength)
                capture.onCharacters?(s, keyCode)
            } else {
                // Still forward non-character keys (arrows, etc.) with empty string
                capture.onCharacters?("", keyCode)
            }

            // Swallow all key events while running
            return nil
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: refcon
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }
}

struct ContentView: View {
    @State private var isRunning = false
    @State private var text: String = ""
    @State private var timer: Timer?
    @State private var remainingSeconds = 10

    @State private var selectedDurationSeconds = 10 * 60
    @State private var keyboardCapture = GlobalKeyboardCapture()

    private let availableDurations: [Int] = [
        3,
        5 * 60,
        10 * 60,
        15 * 60,
        25 * 60
    ]

    var body: some View {
        VStack(spacing: 12) {
            TextField("Type anything…", text: $text)
                .textFieldStyle(.roundedBorder)
                .disabled(!isRunning)
                .focusable(isRunning)
                .frame(minWidth: 200)

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

                Button("Start") {
                    startTimer()
                }
            }
        }
        .padding()
        .frame(minWidth: 240)
    }

    private func startTimer() {
        isRunning = true

        keyboardCapture.onCharacters = { chars, keyCode in
            DispatchQueue.main.async {
                switch keyCode {
                case 51: // delete
                    if !text.isEmpty { text.removeLast() }
                default:
                    text.append(chars)
                }
            }
        }
        keyboardCapture.start()

        remainingSeconds = selectedDurationSeconds
        text = ""

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        keyboardCapture.stop()

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
