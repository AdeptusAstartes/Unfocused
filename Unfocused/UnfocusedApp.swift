//
//  UnfocusedApp.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import SwiftUI

@main
struct UnfocusedApp: App {
    @StateObject private var focusManager = FocusManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(focusManager)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(focusManager)
        } label: {
            Image(systemName: focusManager.isFocusEnabled ? "moon.fill" : "moon")
                .symbolRenderingMode(.hierarchical)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var focusManager: FocusManager

    var body: some View {
        HStack {
            Circle()
                .fill(focusManager.isFocusEnabled ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            Text(focusManager.isFocusEnabled ? "Focus is ON" : "Focus is OFF")
        }

        Divider()

        if focusManager.shortcutConfigured {
            Toggle("Auto-disable Focus", isOn: $focusManager.autoDisableEnabled)

            if focusManager.isFocusEnabled {
                Button("Turn Off Focus Now") {
                    focusManager.disableFocus()
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $focusManager.launchAtLogin)
        } else {
            Text("Setup required - open app")
                .foregroundColor(.secondary)
        }

        Divider()

        Button("Quit Unfocused") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
