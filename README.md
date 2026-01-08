# Unfocused

A macOS menu bar app that monitors Focus (Do Not Disturb) mode and automatically disables it.

Perfect for when you have a keyboard with a Focus key that you keep accidentally pressing.

## Features

- **Real-time monitoring** - Detects Focus mode changes instantly
- **Auto-disable** - Automatically turns off Focus when detected
- **Menu bar app** - Lives in your menu bar, no dock icon
- **Launch at login** - Starts automatically when you log in
- **Notifications** - Get notified when Focus is auto-disabled

## Requirements

- macOS 13.0 or later
- Full Disk Access permission (to read Focus state)
- One-time shortcut setup (to disable Focus)

## Installation

1. Download the latest release or build from source
2. Move `Unfocused.app` to `/Applications`
3. Launch the app
4. Grant **Full Disk Access** when prompted:
   - System Settings → Privacy & Security → Full Disk Access → Enable Unfocused

## Setup

On first launch, you'll need to create a simple Shortcut (one-time setup):

1. Click **Open Shortcuts** in the app
2. Create a new shortcut (⌘N)
3. Name it exactly: **Unfocused**
4. Add the action: **Set Focus** → set to **Off**
5. Close Shortcuts and click **Refresh** in the app

That's it! The app will now automatically disable Focus mode whenever it's enabled.

## Why a Shortcut?

Apple doesn't provide a public API for third-party apps to control Focus mode. The Shortcuts app is the only reliable way to toggle Focus programmatically. The shortcut runs silently in the background - no terminal windows or popups.

## Building from Source

```bash
git clone https://github.com/yourusername/Unfocused.git
cd Unfocused
open Unfocused.xcodeproj
```

Build and run in Xcode (⌘R).

## License

MIT License - See [LICENSE](LICENSE) for details.
