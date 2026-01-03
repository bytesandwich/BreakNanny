//
//  ContentView.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI
import ApplicationServices

enum KeyboardCaptureMode {
    case observeOnly
    case breakLogCapture
    case off
}

final class GlobalKeyboardCapture {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onCharacters: ((String, CGKeyCode) -> Void)?

    // Mode-based behavior
    private(set) var mode: KeyboardCaptureMode = .off

    // Track minutes with activity (for observeOnly mode)
    private(set) var activeMinutes: Set<Int> = []  // Minutes since coding started
    private var observeStartTime: Date?

    // MARK: - ObserveOnly Mode

    private func log(_ message: String) {
        print("[KeyboardCapture] \(message)")
    }

    func startObserveOnly() {
        guard mode == .off else { return }
        mode = .observeOnly
        activeMinutes = []
        observeStartTime = Date()
        log("startObserveOnly() - observeStartTime: \(observeStartTime!)")
        startListenOnlyTap()
    }

    func stopObserveOnly() {
        guard mode == .observeOnly else { return }
        log("stopObserveOnly() - activeMinutes: \(activeMinutes.sorted())")
        stopTap()
        mode = .off
    }

    private func startListenOnlyTap() {
        guard eventTap == nil else { return }

        let mask =
            (CGEventMask(1) << CGEventType.keyDown.rawValue) |
            (CGEventMask(1) << CGEventType.leftMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.rightMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.otherMouseDown.rawValue) |
            (CGEventMask(1) << CGEventType.scrollWheel.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }

            let capture = Unmanaged<GlobalKeyboardCapture>
                .fromOpaque(refcon)
                .takeUnretainedValue()

            // Record activity for this minute
            if let startTime = capture.observeStartTime {
                let secondsSinceStart = Date().timeIntervalSince(startTime)
                let minutesSinceStart = Int(secondsSinceStart / 60)
                let isNew = !capture.activeMinutes.contains(minutesSinceStart)
                capture.activeMinutes.insert(minutesSinceStart)
                if isNew {
                    print("[KeyboardCapture] Activity detected at \(String(format: "%.1f", secondsSinceStart))s -> minute \(minutesSinceStart), total active: \(capture.activeMinutes.count)")
                }
            }

            // Pass event through (listen-only)
            return Unmanaged.passUnretained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
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

    // MARK: - BreakLogCapture Mode (original behavior)

    func startBreakLogCapture() {
        guard mode == .off else { return }
        mode = .breakLogCapture
        startBreakLogCaptureTap()
    }

    func stopBreakLogCapture() {
        guard mode == .breakLogCapture else { return }
        stopTap()
        mode = .off
    }

    private func startBreakLogCaptureTap() {
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

    // MARK: - Common Tap Management

    private func stopTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }

    // Legacy compatibility - maps to breakLogCapture
    func start() {
        startBreakLogCapture()
    }

    func stop() {
        stopBreakLogCapture()
    }
}


enum FocusEnforcementMode {
    case onlyTrackActiveApp
    case enforceAppFocus
    case off
}

struct AppActivationEvent {
    let appName: String
    let timestamp: Date
}

final class FocusEnforcer {
    private var activationObserver: Any?
    private var activationScheduled = false

    // Mode-based behavior
    private(set) var mode: FocusEnforcementMode = .off

    // Track app activations (for onlyTrackActiveApp mode)
    private(set) var appActivations: [AppActivationEvent] = []

    private func log(_ message: String) {
        print("[FocusEnforcer] \(message)")
    }

    // MARK: - OnlyTrackActiveApp Mode

    func startOnlyTrackActiveApp() {
        guard mode == .off else { return }
        mode = .onlyTrackActiveApp
        appActivations = []
        log("startOnlyTrackActiveApp() called")

        // Record the currently active app
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appName = normalizedAppName(from: frontApp)
            appActivations.append(AppActivationEvent(appName: appName, timestamp: Date()))
        }

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, self.mode == .onlyTrackActiveApp else { return }

            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let appName = self.normalizedAppName(from: app)
                self.appActivations.append(AppActivationEvent(appName: appName, timestamp: Date()))
                self.log("App activated: \(appName)")
            }
        }
    }

    func stopOnlyTrackActiveApp() {
        guard mode == .onlyTrackActiveApp else { return }
        log("stopOnlyTrackActiveApp() called")

        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        mode = .off
    }

    // MARK: - EnforceAppFocus Mode (original behavior)

    func startEnforceAppFocus() {
        guard mode == .off else { return }
        mode = .enforceAppFocus
        log("startEnforceAppFocus() called")

        scheduleActivate(reason: "startEnforceAppFocus()")

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, self.mode == .enforceAppFocus else { return }

            // IMPORTANT: ignore our own activation events
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier == Bundle.main.bundleIdentifier {
                self.log("didActivateApplicationNotification: self-activation (ignored)")
                return
            }

            self.log("didActivateApplicationNotification: other app activated -> reassert")
            self.scheduleActivate(reason: "workspace didActivate other app")
        }
    }

    func stopEnforceAppFocus() {
        guard mode == .enforceAppFocus else { return }
        log("stopEnforceAppFocus() called")

        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        mode = .off
    }

    // Legacy compatibility - maps to enforceAppFocus
    func start() {
        startEnforceAppFocus()
    }

    func stop() {
        stopEnforceAppFocus()
    }

    // MARK: - Helper Methods

    private func normalizedAppName(from app: NSRunningApplication) -> String {
        // Use localizedName for human-readable, bundleIdentifier for consistency
        return app.localizedName ?? app.bundleIdentifier ?? "Unknown"
    }

    private func scheduleActivate(reason: String) {
        guard !activationScheduled else {
            log("scheduleActivate(\(reason)): already scheduled")
            return
        }

        activationScheduled = true
        log("scheduleActivate(\(reason))")

        // Use a tiny delay to get out of the current layout/update pass
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.activationScheduled = false
            self.forceActivate()
        }
    }

    private func forceActivate() {
        log("forceActivate()")
        log("isActive before: \(NSApp.isActive)")
        log("keyWindow before: \(String(describing: NSApp.keyWindow))")

        NSApp.activate(ignoringOtherApps: true)
        NSRunningApplication.current.activate(options: [.activateAllWindows])

        log("activation calls issued")
        log("isActive after: \(NSApp.isActive)")
        log("keyWindow after: \(String(describing: NSApp.keyWindow))")
    }
}

// MARK: - ActivityReviewer

struct AppActivitySummary {
    let appName: String
    let activeMinutes: Int
}

struct ActivityReviewer {
    private static func log(_ message: String) {
        print("[ActivityReviewer] \(message)")
    }

    /// Calculates active minutes per app by joining app activations with active minutes.
    /// Returns apps sorted by name for deterministic output.
    static func calculateActivity(
        appActivations: [AppActivationEvent],
        activeMinutes: Set<Int>,
        codingStartTime: Date
    ) -> [AppActivitySummary] {
        log("calculateActivity called")
        log("  codingStartTime: \(codingStartTime)")
        log("  activeMinutes: \(activeMinutes.sorted())")
        log("  appActivations count: \(appActivations.count)")

        for (i, event) in appActivations.enumerated() {
            let offsetSeconds = event.timestamp.timeIntervalSince(codingStartTime)
            log("  activation[\(i)]: \(event.appName) at offset \(String(format: "%.1f", offsetSeconds))s")
        }

        guard !appActivations.isEmpty else {
            log("  No app activations, returning empty")
            return []
        }

        // Build list of (app, minute) pairs
        var appMinutePairs: [(app: String, minute: Int)] = []

        for minute in activeMinutes.sorted() {
            // Find the app that was active during this minute
            // Look for the last activation that happened before the END of this minute
            let minuteEndTime = codingStartTime.addingTimeInterval(Double(minute + 1) * 60)

            var activeApp: String? = nil
            for event in appActivations {
                if event.timestamp <= minuteEndTime {
                    activeApp = event.appName
                } else {
                    break
                }
            }

            log("  minute \(minute): minuteEndTime offset=\(String(format: "%.1f", minuteEndTime.timeIntervalSince(codingStartTime)))s, activeApp=\(activeApp ?? "nil")")

            if let app = activeApp {
                appMinutePairs.append((app: app, minute: minute))
            }
        }

        log("  appMinutePairs: \(appMinutePairs)")

        // Group by app and count minutes
        var appMinuteCounts: [String: Int] = [:]
        for pair in appMinutePairs {
            appMinuteCounts[pair.app, default: 0] += 1
        }

        log("  appMinuteCounts: \(appMinuteCounts)")

        // Convert to array and sort by app name for deterministic output
        let summaries = appMinuteCounts.map { AppActivitySummary(appName: $0.key, activeMinutes: $0.value) }
        return summaries.sorted { $0.appName < $1.appName }
    }

    /// Prints the activity summary to stdout in the required format.
    static func printSummary(
        appActivations: [AppActivationEvent],
        activeMinutes: Set<Int>,
        codingStartTime: Date,
        totalMinutes: Int
    ) {
        log("printSummary called with totalMinutes=\(totalMinutes)")

        let summaries = calculateActivity(
            appActivations: appActivations,
            activeMinutes: activeMinutes,
            codingStartTime: codingStartTime
        )

        let totalActiveMinutes = activeMinutes.count

        print("active minutes: \(totalActiveMinutes) / total minutes: \(totalMinutes)")

        // Sort by active minutes descending for output
        let sortedByMinutes = summaries.sorted { $0.activeMinutes > $1.activeMinutes }

        log("  sortedByMinutes count: \(sortedByMinutes.count)")
        for summary in sortedByMinutes {
            log("  summary: \(summary.appName) = \(summary.activeMinutes)")
        }

        for summary in sortedByMinutes where summary.activeMinutes > 0 {
            print("* app [\(summary.appName)]: \(summary.activeMinutes) active minutes")
        }
    }
}

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Primary Coding Block Area
                PrimaryBlockView(appState: appState)

                Divider()
                    .padding(.horizontal)

                // History List
                HistoryListView(completedBlocks: appState.completedBlocks)

                // Clear History Button
                if !appState.completedBlocks.isEmpty {
                    HStack {
                        Spacer()
                        Button("Clear History") {
                            showingClearConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .textSelection(.enabled)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(white: 0.08))
        .alert("Clear History?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                appState.clearHistory()
            }
        } message: {
            Text("This will permanently delete all completed coding blocks.")
        }
    }
}
