# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This is a SwiftUI macOS app. Open in Xcode and build:

```bash
open Unfocused.xcodeproj
# Build: ⌘B
# Run: ⌘R
```

No external dependencies or package managers.

## Architecture

**Unfocused** is a macOS menu bar app that monitors Focus (Do Not Disturb) mode and can automatically disable it. It's designed for users who accidentally trigger Focus mode (e.g., via keyboard shortcuts).

### Core Files

- **FocusManager.swift** - The heart of the app. Handles:
  - File watching on `~/Library/DoNotDisturb/DB/Assertions.json` using `DispatchSource`
  - Parsing Focus state from JSON (`storeAssertionRecords` = manually-enabled Focus)
  - Disabling Focus via `shortcuts run "Unfocused"` shell command
  - User preferences persistence via `UserDefaults`
  - Launch at login via `SMAppService`
  - Notification delivery via `UNUserNotificationCenter`

- **UnfocusedApp.swift** - App entry point with `MenuBarExtra` (menu bar icon) and `WindowGroup` (settings window)

- **ContentView.swift** - Main settings window UI, shows onboarding or settings based on setup state

- **OnboardingView.swift** - First-run wizard guiding users through Full Disk Access and Shortcut setup

### Key Technical Details

1. **Why Full Disk Access?** - The `Assertions.json` file is protected; the app needs FDA to read it

2. **Why a Shortcut?** - Apple provides no public API to control Focus mode. The app relies on a user-created Shortcut named "Unfocused" with a "Set Focus → Off" action

3. **Manual vs Scheduled Focus** - Only manually-enabled Focus creates `storeAssertionRecords` entries. Scheduled Focus (Sleep, Work, etc.) does NOT appear in this array, so the app naturally ignores scheduled Focus modes

4. **File Watching** - Uses `DispatchSource.makeFileSystemObjectSource` on both the file and parent directory to handle file deletion/recreation
