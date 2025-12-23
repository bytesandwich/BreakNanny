//
//  StatusBarController.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
        setupStatusBar()
        appState.statusBarController = self
        updateStatusBar() // Initialize with current state
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Plan Code"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        // Activate the app and bring all windows to front
        NSApp.activate(ignoringOtherApps: true)

        // Find the main application window
        for window in NSApp.windows {
            if window.title == "BreakNanny" || window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        // If no window was found, try to open it via notification
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
    }

    func updateStatusBar() {
        guard let appState = appState else { return }

        let title: String

        switch appState.phase {
        case .idle:
            title = "Plan Code"
        case .activeCoding:
            if appState.remainingSeconds < 60 {
                title = "Coding \(appState.remainingSeconds)s"
            } else {
                let minutes = appState.remainingSeconds / 60
                title = "Coding \(minutes)m"
            }
        case .activeBreak:
            if appState.remainingSeconds < 60 {
                title = "Break \(appState.remainingSeconds)s"
            } else {
                let minutes = appState.remainingSeconds / 60
                title = "Break \(minutes)m"
            }
        }

        if let button = statusItem?.button {
            button.title = title
        }
    }

    deinit {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
