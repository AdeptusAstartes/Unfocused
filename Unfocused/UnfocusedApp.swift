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
        WindowGroup(id: "settings") {
            ContentView()
                .environmentObject(focusManager)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(focusManager)
        } label: {
            Image(nsImage: Self.menuBarIcon())
        }
    }

    static func menuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let moonConfig = NSImage.SymbolConfiguration(pointSize: 13 * scale, weight: .black)
            let nosignConfig = NSImage.SymbolConfiguration(pointSize: 18 * scale, weight: .light)

            if let moon = NSImage(systemSymbolName: "moon", accessibilityDescription: nil)?
                .withSymbolConfiguration(moonConfig) {
                let moonRect = NSRect(
                    x: (rect.width - moon.size.width / scale) / 2,
                    y: (rect.height - moon.size.height / scale) / 2,
                    width: moon.size.width / scale,
                    height: moon.size.height / scale
                )
                moon.draw(in: moonRect)
            }

            if let nosign = NSImage(systemSymbolName: "nosign", accessibilityDescription: nil)?
                .withSymbolConfiguration(nosignConfig) {
                let nosignRect = NSRect(
                    x: (rect.width - nosign.size.width / scale) / 2,
                    y: (rect.height - nosign.size.height / scale) / 2,
                    width: nosign.size.width / scale,
                    height: nosign.size.height / scale
                )
                nosign.draw(in: nosignRect)
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}

struct MenuBarView: View {
    @EnvironmentObject var focusManager: FocusManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Circle()
                .fill(focusManager.isFocusEnabled ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            Text(focusManager.isFocusEnabled ? "Focus is ON" : "Focus is OFF")
        }

        Divider()

        if focusManager.hasFullDiskAccess && focusManager.shortcutConfigured {
            Picker("When Focus is enabled", selection: $focusManager.focusAction) {
                Text("Play alert sound").tag(FocusManager.FocusAction.soundAlert)
                Text("Auto-disable Focus").tag(FocusManager.FocusAction.autoDisable)
            }

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

        Button("Settings...") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")

        Button("Quit Unfocused") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
