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

/// Manages detection of macOS Focus (Do Not Disturb) state.
@MainActor
class FocusManager: ObservableObject {

    @Published var isFocusEnabled: Bool = false
    @Published var shortcutConfigured: Bool = false
    @Published var lastError: String?

    @Published var autoDisableEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableEnabled, forKey: "autoDisableEnabled")
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }

    private let assertionsPath: String
    private let shortcutName = "Unfocused"

    private var fileDescriptor: Int32 = -1
    private var dirDescriptor: Int32 = -1
    private var fileSource: DispatchSourceFileSystemObject?
    private var dirSource: DispatchSourceFileSystemObject?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        assertionsPath = "\(home)/Library/DoNotDisturb/DB/Assertions.json"

        // Load persisted settings
        autoDisableEnabled = UserDefaults.standard.bool(forKey: "autoDisableEnabled")
        launchAtLogin = SMAppService.mainApp.status == .enabled

        requestNotificationPermission()
        checkShortcutExists()
        readFocusState()
        startWatching()
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

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
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
        guard FileManager.default.isReadableFile(atPath: assertionsPath) else {
            lastError = "Grant Full Disk Access in System Settings"
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: assertionsPath))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let isEnabled = parseFocusState(from: json)

            let wasEnabled = isFocusEnabled
            isFocusEnabled = isEnabled
            lastError = nil

            if autoDisableEnabled && isEnabled && !wasEnabled {
                disableFocus()
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

            // Send notification
            sendNotification(
                title: "Focus Disabled",
                body: "Unfocused automatically turned off Focus mode."
            )

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                readFocusState()
            }
        } catch {
            lastError = "Failed to run shortcut"
        }
    }
}
