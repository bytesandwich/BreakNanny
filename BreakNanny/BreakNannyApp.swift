//
//  BreakNannyApp.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import SwiftUI
import ServiceManagement

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private static var hasLaunched = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure only one instance runs
        if AppDelegate.hasLaunched {
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        AppDelegate.hasLaunched = true

        // Enable launch at login
        enableLaunchAtLogin()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window is closed - keep running in menu bar
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        }
        return true
    }

    private func enableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }
}

@main
struct BreakNannyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        Window("BreakNanny", id: "main") {
            ContentView(appState: appState)
                .onAppear {
                    if appDelegate.statusBarController == nil {
                        appDelegate.statusBarController = StatusBarController(appState: appState)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
                    // Bring window to front when notification is received
                    DispatchQueue.main.async {
                        for window in NSApp.windows {
                            if window.title == "BreakNanny" {
                                window.makeKeyAndOrderFront(nil)
                            }
                        }
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        .defaultPosition(.center)
        .handlesExternalEvents(matching: [])
    }
}
