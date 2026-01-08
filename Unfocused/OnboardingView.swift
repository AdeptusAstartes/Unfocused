//
//  OnboardingView.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var focusManager: FocusManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isComplete: Bool

    @State private var currentStep = 0
    @State private var isGoingForward = true

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar with back button and step dots
            HStack {
                // Back button
                Button {
                    isGoingForward = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(currentStep > 0 && currentStep < 4 ? 1 : 0)
                .disabled(currentStep == 0 || currentStep >= 4)

                Spacer()

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.cyan : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentStep)
                    }
                }
                .opacity(currentStep < 4 ? 1 : 0)

                Spacer()

                // Placeholder for symmetry
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(height: 44)

            // Step content - fills remaining space with horizontal slide
            ZStack {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: isGoingForward ? .trailing : .leading),
                        removal: .move(edge: isGoingForward ? .leading : .trailing)
                    ))
                    .id(currentStep)
            }
            .clipped()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .frame(width: 410, height: 530)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            fullDiskAccessStep
        case 2:
            notificationsStep
        case 3:
            shortcutStep
        case 4:
            completionStep
        default:
            EmptyView()
        }
    }

    // MARK: - Welcome Step

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    @State private var moonOffset: CGFloat = 0
    @State private var glowOpacity: CGFloat = 0.3
    @State private var titleOpacity: CGFloat = 0
    @State private var subtitleOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Glow effect
                Circle()
                    .fill(.cyan.opacity(glowOpacity))
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                Image(systemName: "moon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .offset(y: moonOffset)
            .onAppear {
                // Bounce in
                withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
                // Floating animation (skip if reduce motion)
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        moonOffset = -8
                    }
                    // Pulsing glow
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.6
                    }
                }
                // Staggered text fade-in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.3)) {
                    titleOpacity = 1.0
                }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.5)) {
                    subtitleOpacity = 1.0
                }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.7)) {
                    buttonOpacity = 1.0
                }
            }

            Text("Welcome to Unfocused")
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(titleOpacity)

            Text("Unfocused monitors Focus mode and can automatically disable it, so you never miss a notification.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)
                .opacity(subtitleOpacity)

            Spacer()

            Button("Get Started") {
                isGoingForward = true
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 1
                }
            }
            .buttonStyle(GlowingButtonStyle())
            .controlSize(.large)
            .opacity(buttonOpacity)
        }
    }

    // MARK: - Full Disk Access Step

    private var fullDiskAccessStep: some View {
        VStack(spacing: 20) {
            StepHeader(icon: "lock.shield", title: "Full Disk Access")

            Text("Unfocused needs Full Disk Access to detect when Focus mode is enabled.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            CardGroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    InstructionRow(number: 1, text: "Click **Open Settings** below")
                    InstructionRow(number: 2, text: "Find **Unfocused** in the list")
                    InstructionRow(number: 3, text: "Enable the toggle")
                    InstructionRow(number: 4, text: "Come back here and click **Continue**")
                }
            }

            Spacer()

            if focusManager.hasFullDiskAccess {
                SuccessLabel(text: "Access Granted")
            }

            HStack(spacing: 12) {
                Button("Open Settings") {
                    focusManager.openFullDiskAccessSettings()
                }
                .buttonStyle(GlowingButtonStyle())

                Button("Continue") {
                    focusManager.checkFullDiskAccess()
                    if focusManager.hasFullDiskAccess {
                        isGoingForward = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 2
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!focusManager.hasFullDiskAccess)
            }

            RefreshButton {
                focusManager.checkFullDiskAccess()
            }
        }
    }

    // MARK: - Notifications Step

    private var notificationsStep: some View {
        VStack(spacing: 20) {
            StepHeader(icon: "bell.badge", title: "Notifications")

            Text("Get notified when Unfocused disables Focus mode for you.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()

            if focusManager.notificationsEnabled {
                SuccessLabel(text: "Notifications Enabled")
            }

            HStack(spacing: 12) {
                Button("Enable Notifications") {
                    focusManager.requestNotificationPermission()
                }
                .buttonStyle(GlowingButtonStyle())
                .disabled(focusManager.notificationsEnabled)

                Button("Continue") {
                    isGoingForward = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 3
                    }
                }
                .buttonStyle(.bordered)
            }

            Button("Skip") {
                isGoingForward = true
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
    @State private var isWaitingForShortcut = false

    private var shortcutStep: some View {
        VStack(spacing: 20) {
            StepHeader(icon: "square.and.arrow.down", title: "Install Shortcut")

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

            if isWaitingForShortcut {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Waiting for Shortcuts...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            } else if focusManager.shortcutConfigured {
                SuccessLabel(text: "Shortcut Installed")
            }

            HStack(spacing: 12) {
                if showManualInstructions {
                    Button("Open Shortcuts") {
                        focusManager.openShortcutsApp()
                        startWaitingForShortcut()
                    }
                    .buttonStyle(GlowingButtonStyle())
                    .disabled(isWaitingForShortcut)
                } else {
                    Button("Install Shortcut") {
                        focusManager.installShortcut()
                        startWaitingForShortcut()
                    }
                    .buttonStyle(GlowingButtonStyle())
                    .disabled(isWaitingForShortcut)
                }

                Button("Finish") {
                    focusManager.checkShortcutExists()
                    if focusManager.shortcutConfigured {
                        isGoingForward = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 4
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!focusManager.shortcutConfigured)
            }

            RefreshButton {
                focusManager.checkShortcutExists()
            }
            .disabled(isWaitingForShortcut)
        }
    }

    private var autoShortcutInstructions: some View {
        CardGroupBox {
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: 1, text: "Click **Install Shortcut** below")
                InstructionRow(number: 2, text: "Click **Add Shortcut** in the window that opens")
                InstructionRow(number: 3, text: "Come back here and click **Finish**")
            }
        }
    }

    private var manualShortcutInstructions: some View {
        CardGroupBox {
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: 1, text: "Click **Open Shortcuts** below")
                InstructionRow(number: 2, text: "Create a new shortcut (⌘N)")
                InstructionRow(number: 3, text: "Name it exactly: **Unfocused**")
                InstructionRow(number: 4, text: "Add action: **Set Focus** → **Off**")
                InstructionRow(number: 5, text: "Close Shortcuts and click **Finish**")
            }
        }
    }

    // MARK: - Completion Step

    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = -90
    @State private var celebrationOpacity: CGFloat = 0

    private var completionStep: some View {
        VStack(spacing: 24) {
            Spacer()

            completionCheckmark
                .onAppear {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5)) {
                        checkmarkScale = 1.0
                        checkmarkRotation = 0
                    }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 1).delay(0.3)) {
                        celebrationOpacity = 1.0
                    }
                }

            completionText

            Spacer()

            Button("Get Started") {
                completeOnboarding()
            }
            .buttonStyle(GlowingButtonStyle(color: .green))
            .controlSize(.large)
        }
    }

    private var completionCheckmark: some View {
        ZStack {
            celebrationRings
            checkmarkCircle
        }
    }

    private var celebrationRings: some View {
        ForEach(0..<3, id: \.self) { i in
            let size: CGFloat = CGFloat(100 + i * 40)
            let ringOpacity: Double = 0.3 - (Double(i) * 0.1)
            Circle()
                .stroke(Color.green.opacity(ringOpacity), lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(celebrationOpacity)
                .opacity(Double(1.0) - Double(celebrationOpacity) * 0.5)
        }
    }

    private var checkmarkCircle: some View {
        ZStack {
            Circle()
                .fill(Color.green.gradient)
                .frame(width: 80, height: 80)
                .shadow(color: Color.green.opacity(0.5), radius: 20)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(checkmarkScale)
        .rotationEffect(.degrees(checkmarkRotation))
    }

    private var completionText: some View {
        VStack(spacing: 12) {
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unfocused is now monitoring Focus mode and will keep you connected.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)
        }
    }

    // MARK: - Helpers

    private func startWaitingForShortcut() {
        isWaitingForShortcut = true
        // Auto-check every 2 seconds for up to 30 seconds
        Task {
            for _ in 0..<15 {
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    focusManager.checkShortcutExists()
                    if focusManager.shortcutConfigured {
                        isWaitingForShortcut = false
                        return
                    }
                }
                if focusManager.shortcutConfigured {
                    break
                }
            }
            await MainActor.run {
                isWaitingForShortcut = false
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        withAnimation(.easeInOut(duration: 0.3)) {
            isComplete = true
        }
    }
}

// MARK: - Supporting Views

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct StepHeader: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.title)
            .fontWeight(.bold)
    }
}

struct CardGroupBox<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .backgroundStyle(.ultraThinMaterial)
    }
}

struct InstructionRow: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.cyan.gradient))

            Text(text)
                .font(.callout)
        }
    }
}

struct SuccessLabel: View {
    let text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundColor(.green)
            .font(.headline)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            .accessibilityLabel(text)
    }
}

struct RefreshButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button("Refresh Status", action: action)
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(isHovered ? .primary : .secondary)
            .onHover { isHovered = $0 }
    }
}

struct GlowingButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var color: Color = .cyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(configuration.isPressed ? 0.3 : 0.5), radius: configuration.isPressed ? 5 : 10)
            )
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
        .environmentObject(FocusManager())
}
