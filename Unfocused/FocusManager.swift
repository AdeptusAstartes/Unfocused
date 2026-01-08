//
//  FocusManager.swift
//  Unfocused
//
//  Created by Donald Angelillo on 1/8/26.
//

import Foundation
import Combine
import AppKit
import UserNotifications
import ServiceManagement
import AudioToolbox

/// Manages detection of macOS Focus (Do Not Disturb) state.
@MainActor
class FocusManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    @Published var isFocusEnabled: Bool = false
    @Published var shortcutConfigured: Bool = false
    @Published var hasFullDiskAccess: Bool = false
    @Published var lastError: String?

    enum FocusAction: Int {
        case soundAlert = 0
        case autoDisable = 1
    }

    @Published var focusAction: FocusAction {
        didSet {
            UserDefaults.standard.set(focusAction.rawValue, forKey: "focusAction")
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            updateDockVisibility()
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }

    private let assertionsPath: String
    private let shortcutName = "Unfocused"

    private var fileDescriptor: Int32 = -1
    private var dirDescriptor: Int32 = -1
    private var fileSource: DispatchSourceFileSystemObject?
    private var dirSource: DispatchSourceFileSystemObject?

    override init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        assertionsPath = "\(home)/Library/DoNotDisturb/DB/Assertions.json"

        // Load persisted settings
        focusAction = FocusAction(rawValue: UserDefaults.standard.integer(forKey: "focusAction")) ?? .soundAlert
        launchAtLogin = SMAppService.mainApp.status == .enabled
        showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true

        super.init()

        // Set notification delegate to allow foreground notifications
        UNUserNotificationCenter.current().delegate = self

        // Apply dock visibility setting
        updateDockVisibility()

        checkNotificationPermission()
        checkShortcutExists()
        readFocusState()
        startWatching()
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is active
        completionHandler([.banner, .sound])
    }

    deinit {
        fileSource?.cancel()
        dirSource?.cancel()
        if fileDescriptor >= 0 { close(fileDescriptor) }
        if dirDescriptor >= 0 { close(dirDescriptor) }
    }

    // MARK: - Launch at Login

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }

    // MARK: - Dock Visibility

    func updateDockVisibility() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    // MARK: - Notifications

    @Published var notificationsEnabled: Bool = false

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                switch settings.authorizationStatus {
                case .authorized:
                    self.notificationsEnabled = true
                case .notDetermined:
                    // Automatically request if not yet asked
                    self.requestNotificationPermission()
                default:
                    self.notificationsEnabled = false
                }
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.notificationsEnabled = granted
            }
        }
    }

    func openNotificationSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playAlertSound() {
        AudioServicesPlaySystemSound(kSystemSoundID_FlashScreen)

        // Rapid beeps to simulate buzzer
        Task {
            for _ in 1...5 {
                NSSound.beep()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    // MARK: - Shortcut Check

    func checkShortcutExists() {
        let task = Process()
        task.launchPath = "/usr/bin/shortcuts"
        task.arguments = ["list"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            shortcutConfigured = output.contains(shortcutName)
        } catch {
            shortcutConfigured = false
        }
    }

    func openShortcutsApp() {
        NSWorkspace.shared.open(URL(string: "shortcuts://")!)
    }

    private let shortcutCloudURL = "https://www.icloud.com/shortcuts/24d24fc4d7954b91a7c5f24753288b78"

    func installShortcut() {
        if let url = URL(string: shortcutCloudURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func openFullDiskAccessSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
    }

    func checkFullDiskAccess() {
        hasFullDiskAccess = FileManager.default.isReadableFile(atPath: assertionsPath)
    }

    // MARK: - File Watching

    private func startWatching() {
        let dirPath = (assertionsPath as NSString).deletingLastPathComponent

        if dirDescriptor < 0 {
            dirDescriptor = open(dirPath, O_EVTONLY)
            if dirDescriptor >= 0 {
                dirSource = DispatchSource.makeFileSystemObjectSource(
                    fileDescriptor: dirDescriptor,
                    eventMask: [.write, .extend, .attrib],
                    queue: .main
                )
                dirSource?.setEventHandler { [weak self] in
                    self?.onDirectoryChange()
                }
                dirSource?.resume()
            }
        }

        watchFile()
    }

    private func watchFile() {
        fileSource?.cancel()
        fileSource = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }

        fileDescriptor = open(assertionsPath, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        fileSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: .main
        )

        fileSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            let events = self.fileSource?.data ?? []

            self.readFocusState()

            if events.contains(.delete) || events.contains(.rename) {
                self.watchFile()
            }
        }

        fileSource?.resume()
    }

    private func onDirectoryChange() {
        readFocusState()
        if fileDescriptor < 0 {
            watchFile()
        }
    }

    // MARK: - Read Focus State

    func readFocusState() {
        let canRead = FileManager.default.isReadableFile(atPath: assertionsPath)
        hasFullDiskAccess = canRead

        guard canRead else {
            lastError = "Full Disk Access required"
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: assertionsPath))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let isEnabled = parseFocusState(from: json)

            let wasEnabled = isFocusEnabled
            isFocusEnabled = isEnabled
            lastError = nil

            // React to Focus being enabled
            if isEnabled && !wasEnabled {
                switch focusAction {
                case .soundAlert:
                    playAlertSound()
                case .autoDisable:
                    disableFocus()
                }
            }
        } catch {
            // File might be mid-write, ignore
        }
    }

    private func parseFocusState(from json: [String: Any]?) -> Bool {
        guard let data = json?["data"] as? [[String: Any]] else {
            return false
        }

        for store in data {
            if let records = store["storeAssertionRecords"] as? [[String: Any]], !records.isEmpty {
                return true
            }
        }

        return false
    }

    // MARK: - Disable Focus

    func disableFocus() {
        guard shortcutConfigured else {
            lastError = "Shortcut not configured"
            return
        }

        let task = Process()
        task.launchPath = "/usr/bin/shortcuts"
        task.arguments = ["run", shortcutName]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                readFocusState()

                // Send notification after Focus is confirmed off
                if showNotifications {
                    sendNotification(
                        title: "Focus Disabled",
                        body: "Unfocused just saved you from missing notifications."
                    )
                }
            }
        } catch {
            lastError = "Failed to run shortcut"
        }
    }
}
