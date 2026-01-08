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
                setupRequiredView(
                    icon: "lock.shield",
                    title: "Full Disk Access Required",
                    message: "Unfocused needs Full Disk Access to detect Focus mode.",
                    buttonTitle: "Open Settings",
                    action: { focusManager.openFullDiskAccessSettings() },
                    refreshAction: { focusManager.checkFullDiskAccess() }
                )
            } else if !focusManager.shortcutConfigured {
                setupRequiredView(
                    icon: "square.and.arrow.down",
                    title: "Shortcut Required",
                    message: "The Unfocused shortcut is missing. Please reinstall it.",
                    buttonTitle: "Install Shortcut",
                    action: { focusManager.installShortcut() },
                    refreshAction: { focusManager.checkShortcutExists() }
                )
            } else {
                controlsView
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 340, minHeight: 360)
    }

    private func setupRequiredView(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String,
        action: @escaping () -> Void,
        refreshAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)

                Button("Refresh", action: refreshAction)
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
