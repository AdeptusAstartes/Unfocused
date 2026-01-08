# Repository Guidelines

## Project Structure & Module Organization
The `Unfocused/` directory contains the SwiftUI app entry point (`UnfocusedApp.swift`), UI surface (`ContentView.swift`), and runtime logic (`FocusManager.swift`), while reusable assets sit in `Unfocused/Assets.xcassets`. The `assets/` folder stores supporting artifacts such as `Unfocused.shortcut` and marketing icons that ship with release builds. Open `Unfocused.xcodeproj` in Xcode to view the single target; keep new Swift sources within the `Unfocused` group and mirror the folder hierarchy so Xcode references stay in sync.

## Build, Test, and Development Commands
Use `open Unfocused.xcodeproj` for full Xcode workflows. For scripted builds, run `xcodebuild -scheme Unfocused -configuration Debug build` to ensure the menu bar app compiles cleanly, and prefer `xcodebuild -scheme Unfocused test` when XCTest targets are present to block regressions in CI. Launch the debug build directly from Xcode (⌘R) to exercise menu bar behavior and confirm Focus automation still works.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: four-space indentation, `UpperCamelCase` for types (e.g., `FocusManager`), and `lowerCamelCase` for functions, properties, and bindings. Keep SwiftUI view structs small, extracting modifiers into extensions when they exceed ~40 lines. Observe value semantics and make members `private` unless accessed by another file. When adding linting, match Xcode's default formatting so `git diff` stays noise-free.

## Testing Guidelines
Add XCTest targets parallel to `Unfocused` (e.g., `UnfocusedTests/FocusManagerTests.swift`) and name suites after the component under test. Prefer deterministic unit tests for `FocusManager`'s shortcut orchestration and UI tests for menu bar state. Run `xcodebuild test` locally before every push; aim for coverage on branches that handle Focus detection, shortcut invocation, and user notifications.

## Commit & Pull Request Guidelines
Recent history favors concise, lower-case subjects like `improvements`; continue writing imperative summaries under 50 characters ("add focus retries"), with optional detail in the body. Each PR should link issues or describe the user problem, list build/test evidence (command + result), and include screenshots or screen recordings when UI changes affect the menu bar icon or notifications. Revalidate the bundled shortcut whenever behavior changes so reviewers can reproduce the automation end-to-end.

## Security & Configuration Tips
Never commit personal Focus shortcuts—use the templated `assets/Unfocused.shortcut` and document additional setup steps in the PR. When handling macOS permissions (Full Disk Access, Accessibility), gate new code paths with clear user messaging so the app cannot silently fail. Keep bundle identifiers and signing settings in sync between the project file and any release automation to avoid notarization issues.
