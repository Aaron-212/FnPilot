# FnPilot

FnPilot is a macOS menu bar app for switching the keyboard function-key mode globally or per application.

Use it when you want the top-row keys to behave as media controls in most apps, but as standard `F1`-`F12` function keys in selected tools such as terminals, editors, IDEs, or games.

FnPilot is a spiritual successor to Fluor, a macOS utility with a similar goal. Fluor has not been actively maintained for more than five years, so FnPilot takes the same core idea and rebuilds it as a modern SwiftUI menu bar app.

## Features

- Menu bar control for the current function-key mode.
- Global mode selection:
    - `Media`: use the top row as brightness, volume, playback, and other media keys.
    - `Fn`: use the top row as standard function keys.
- Per-app overrides based on the foreground app.
- Configurable Fn or Media mode to leave active after quitting.
- Support for both application bundles and standalone executable paths.
- Settings window with launch-at-login support.
- Preferences stored locally in `UserDefaults`.

## Requirements

- macOS 15.6 or later, Apple Silicon or Intel processors are supported.
- Xcode with support for the configured macOS SDK.

FnPilot is a native SwiftUI app and uses AppKit, IOKit, Observation, ServiceManagement, etc.
It has no external or 3rd party package dependencies.

## Build and Run

Open the project in Xcode, select the `FnPilot` scheme, and then build and run.

You can also build from the command line:

```sh
xcodebuild -project FnPilot.xcodeproj -scheme FnPilot -configuration Debug build
```

## Release Downloads

GitHub release assets are unsigned app bundles. macOS may block the first launch or show an unidentified developer warning.
If you download a release build, open it only if you trust the source, then use Finder's `Open` command or System Settings privacy controls to allow it.

## Notes

- FnPilot is inspired by Fluor, but it is a separate project, and not a fork.
- FnPilot starts as a menu bar app and suppresses the settings window on launch.
- Per-app settings are keyed by bundle identifier when available, or by executable path for apps without a bundle identifier.
