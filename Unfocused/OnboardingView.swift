//
//  OnboardingView.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var focusManager: FocusManager
    @Binding var isComplete: Bool

    @State private var currentStep = 0

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(.linear)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Step content
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    fullDiskAccessStep
                case 2:
                    notificationsStep
                case 3:
                    shortcutStep
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentStep)
        }
        .frame(minWidth: 400, minHeight: 420)
    }

    // MARK: - Welcome Step

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "moon.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        iconScale = 1.0
                        iconOpacity = 1.0
                    }
                }

            Text("Welcome to Unfocused")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unfocused monitors Focus mode and can automatically disable it, so you never miss a notification.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)

            Spacer()

            Button("Get Started") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 1
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Full Disk Access Step

    private var fullDiskAccessStep: some View {
        VStack(spacing: 20) {
            Label("Full Disk Access", systemImage: "lock.shield")
                .font(.title)
                .fontWeight(.bold)

            Text("Unfocused needs Full Disk Access to detect when Focus mode is enabled.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Click **Open Settings** below")
                    Text("2. Find **Unfocused** in the list")
                    Text("3. Enable the toggle")
                    Text("4. Come back here and click **Continue**")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            if focusManager.hasFullDiskAccess {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 12) {
                Button("Open Settings") {
                    focusManager.openFullDiskAccessSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Continue") {
                    focusManager.checkFullDiskAccess()
                    if focusManager.hasFullDiskAccess {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 2
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!focusManager.hasFullDiskAccess)
            }

            Button("Refresh Status") {
                focusManager.checkFullDiskAccess()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Notifications Step

    private var notificationsStep: some View {
        VStack(spacing: 20) {
            Label("Notifications", systemImage: "bell.badge")
                .font(.title)
                .fontWeight(.bold)

            Text("Get notified when Unfocused disables Focus mode for you.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            if focusManager.notificationsEnabled {
                Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 12) {
                Button("Enable Notifications") {
                    focusManager.requestNotificationPermission()
                }
                .buttonStyle(.borderedProminent)
                .disabled(focusManager.notificationsEnabled)

                Button("Continue") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 3
                    }
                }
                .buttonStyle(.bordered)
            }

            Button("Skip") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 3
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Shortcut Step

    @State private var showManualInstructions = false

    private var shortcutStep: some View {
        VStack(spacing: 20) {
            Label("Install Shortcut", systemImage: "square.and.arrow.down")
                .font(.title)
                .fontWeight(.bold)

            Text("Unfocused uses a Shortcut to disable Focus mode.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Picker("Method", selection: $showManualInstructions) {
                Text("Install from iCloud").tag(false)
                Text("Create Manually").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if showManualInstructions {
                manualShortcutInstructions
            } else {
                autoShortcutInstructions
            }

            Spacer()

            if focusManager.shortcutConfigured {
                Label("Shortcut Installed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 12) {
                if showManualInstructions {
                    Button("Open Shortcuts") {
                        focusManager.openShortcutsApp()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Install Shortcut") {
                        focusManager.installShortcut()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Finish") {
                    focusManager.checkShortcutExists()
                    if focusManager.shortcutConfigured {
                        completeOnboarding()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!focusManager.shortcutConfigured)
            }

            Button("Refresh Status") {
                focusManager.checkShortcutExists()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var autoShortcutInstructions: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Click **Install Shortcut** below")
                Text("2. Click **Add Shortcut** in the window that opens")
                Text("3. Come back here and click **Finish**")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var manualShortcutInstructions: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Click **Open Shortcuts** below")
                Text("2. Create a new shortcut (⌘N)")
                Text("3. Name it exactly: **Unfocused**")
                Text("4. Add action: **Set Focus** → **Off**")
                Text("5. Close Shortcuts and click **Finish**")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        withAnimation {
            isComplete = true
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
        .environmentObject(FocusManager())
}
