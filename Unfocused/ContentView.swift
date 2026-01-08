//
//  ContentView.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager

    var body: some View {
        VStack(spacing: 20) {
            // Status indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(focusManager.isFocusEnabled ? Color.orange : Color.green)
                    .frame(width: 16, height: 16)
                    .shadow(color: focusManager.isFocusEnabled ? .orange.opacity(0.5) : .green.opacity(0.5), radius: 4)

                Text(focusManager.isFocusEnabled ? "Focus is ON" : "Focus is OFF")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            if let error = focusManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Divider()

            if !focusManager.shortcutConfigured {
                setupView
            } else {
                controlsView
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 340, minHeight: 360)
    }

    private var setupView: some View {
        VStack(spacing: 16) {
            Label("One-Time Setup Required", systemImage: "gear")
                .font(.headline)

            Text("Create a shortcut named **\"Unfocused\"** with a single action:")
                .font(.callout)
                .multilineTextAlignment(.center)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Click \"Open Shortcuts\" below")
                    Text("2. Create new shortcut (⌘N)")
                    Text("3. Name it exactly: **Unfocused**")
                    Text("4. Add action: **Set Focus** → **Off**")
                    Text("5. Close Shortcuts and click Refresh")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button("Open Shortcuts") {
                    focusManager.openShortcutsApp()
                }
                .buttonStyle(.borderedProminent)

                Button("Refresh") {
                    focusManager.checkShortcutExists()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var controlsView: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $focusManager.autoDisableEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-disable Focus")
                        .font(.headline)
                    Text("Automatically turn off Focus when detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $focusManager.launchAtLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch at Login")
                        .font(.headline)
                    Text("Start Unfocused when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            if focusManager.isFocusEnabled {
                Button(action: {
                    focusManager.disableFocus()
                }) {
                    Label("Turn Off Focus Now", systemImage: "moon.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
            }

        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusManager())
}
