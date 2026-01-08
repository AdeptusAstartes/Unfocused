//
//  ContentView.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some View {
        if onboardingComplete {
            mainView
        } else {
            OnboardingView(isComplete: $onboardingComplete)
        }
    }

    private var mainView: some View {
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

            if !focusManager.hasFullDiskAccess {
                fullDiskAccessView
            } else if !focusManager.notificationsEnabled {
                notificationsView
            } else if !focusManager.shortcutConfigured {
                shortcutSetupView
            } else {
                controlsView
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 340, minHeight: 360)
    }

    private var notificationsView: some View {
        VStack(spacing: 16) {
            Label("Notifications Required", systemImage: "bell.badge")
                .font(.headline)

            Text("Unfocused needs notification permission to alert you.")
                .font(.callout)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Enable Notifications") {
                    focusManager.requestNotificationPermission()
                }
                .buttonStyle(.borderedProminent)

                Button("Open Settings") {
                    focusManager.openNotificationSettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var fullDiskAccessView: some View {
        VStack(spacing: 16) {
            Label("Full Disk Access Required", systemImage: "lock.shield")
                .font(.headline)

            Text("Unfocused needs Full Disk Access to detect Focus mode.")
                .font(.callout)
                .multilineTextAlignment(.center)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Click \"Open Settings\" below")
                    Text("2. Enable the toggle for **Unfocused**")
                    Text("3. Click \"Refresh\" to continue")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button("Open Settings") {
                    focusManager.openFullDiskAccessSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Refresh") {
                    focusManager.checkFullDiskAccess()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var shortcutSetupView: some View {
        VStack(spacing: 16) {
            Label("Shortcut Setup Required", systemImage: "gear")
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
            VStack(alignment: .leading, spacing: 8) {
                Text("When Focus is enabled:")
                    .font(.headline)

                Picker("Action", selection: $focusManager.focusAction) {
                    Text("Play alert sound").tag(FocusManager.FocusAction.soundAlert)
                    Text("Auto-disable Focus").tag(FocusManager.FocusAction.autoDisable)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Toggle(isOn: $focusManager.launchAtLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch at Login")
                        .font(.headline)
                    Text("Start Unfocused when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)

            Toggle(isOn: $focusManager.showInDock) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show in Dock")
                        .font(.headline)
                    Text("Display app icon in the Dock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)

            Toggle(isOn: $focusManager.showNotifications) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Notifications")
                        .font(.headline)
                    Text("Notify when Focus is auto-disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
