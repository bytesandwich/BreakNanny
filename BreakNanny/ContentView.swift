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
    @State private var appState = AppState()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Primary Coding Block Area
                PrimaryBlockView(appState: appState)

                Divider()
                    .padding(.horizontal)

                // History List
                HistoryListView(completedBlocks: appState.completedBlocks)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(white: 0.08))
    }
}

#Preview {
    ContentView()
}
