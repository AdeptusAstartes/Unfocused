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
        ZStack {
            // Vibrancy background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Status indicator
                StatusIndicator(isFocusEnabled: focusManager.isFocusEnabled)

                if let error = focusManager.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .transition(.opacity)
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
        }
        .frame(width: 410, height: 530)
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
                    .buttonStyle(GlowingButtonStyle())

                Button("Refresh", action: refreshAction)
                    .buttonStyle(.bordered)
            }
        }
    }

    private var controlsView: some View {
        VStack(spacing: 16) {
            // Action picker card
            SettingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When Focus is enabled:")
                        .font(.headline)

                    Picker("Action", selection: $focusManager.focusAction) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-disable Focus")
                            HStack(spacing: 0) {
                                Text("Only affects manually-enabled Focus. Scheduled Focus modes should be left alone - please ")
                                Link("report a bug", destination: URL(string: "https://github.com/AdeptusAstartes/Unfocused/issues")!)
                                    .underline()
                                Text(" if not.")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }.tag(FocusManager.FocusAction.autoDisable)
                        Text("Play alert sound").tag(FocusManager.FocusAction.soundAlert)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Settings toggles card
            SettingsCard {
                VStack(spacing: 12) {
                    SettingsToggle(
                        isOn: $focusManager.launchAtLogin,
                        title: "Launch at Login",
                        subtitle: "Start Unfocused when you log in"
                    )

                    Divider()

                    SettingsToggle(
                        isOn: $focusManager.showInDock,
                        title: "Show in Dock",
                        subtitle: "Display app icon in the Dock"
                    )

                    Divider()

                    SettingsToggle(
                        isOn: $focusManager.showNotifications,
                        title: "Show Notifications",
                        subtitle: "Notify when Focus is auto-disabled"
                    )
                }
            }

            // Turn off button (always visible, disabled when Focus is off)
            TurnOffFocusButton {
                focusManager.disableFocus()
            }
            .disabled(!focusManager.isFocusEnabled)
            .opacity(focusManager.isFocusEnabled ? 1.0 : 0.5)
        }
        .animation(.easeInOut(duration: 0.3), value: focusManager.isFocusEnabled)
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isFocusEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.5

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Outer glow (only when Focus is ON)
                if isFocusEnabled {
                    Circle()
                        .fill(Color.cyan.opacity(glowOpacity))
                        .frame(width: 28, height: 28)
                        .blur(radius: 6)
                        .scaleEffect(pulseScale)
                }

                // Main dot
                Circle()
                    .fill(isFocusEnabled ? Color.cyan : Color.green)
                    .frame(width: 16, height: 16)
                    .shadow(color: (isFocusEnabled ? Color.cyan : Color.green).opacity(0.5), radius: 4)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isFocusEnabled)
            .onAppear {
                if isFocusEnabled && !reduceMotion {
                    startPulsing()
                }
            }
            .onChange(of: isFocusEnabled) { newValue in
                if newValue && !reduceMotion {
                    startPulsing()
                }
            }

            Text(isFocusEnabled ? "Focus is ON" : "Focus is OFF")
                .font(.title2)
                .fontWeight(.semibold)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isFocusEnabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus status: \(isFocusEnabled ? "On" : "Off")")
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
            glowOpacity = 0.8
        }
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            )
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
    }
}

// MARK: - Turn Off Focus Button

struct TurnOffFocusButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Turn Off Focus Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .cyan.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .cyan.opacity(isHovered ? 0.6 : 0.4), radius: isHovered ? 12 : 8, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.97 : (isHovered ? 1.02 : 1.0)))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isPressed)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
        .accessibilityLabel("Turn off Focus mode")
        .accessibilityHint("Disables Focus mode immediately")
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusManager())
}
