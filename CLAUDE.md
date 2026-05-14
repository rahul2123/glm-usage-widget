# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

**Do not use `swift build`.** The project uses raw `swiftc`, not Swift Package Manager. `Package.swift` exists for IDE tooling only.

```bash
# Step 1: compile
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift \
  -framework SwiftUI -framework AppKit -framework Foundation -framework Security

# Step 2: package into app bundle
./build.sh
```

Output: `bin/GLMUsageWidget` (binary), `build/GLM Usage Monitor.app` (app bundle).

To run: `open 'build/GLM Usage Monitor.app'`  
To install: `cp -R 'build/GLM Usage Monitor.app' /Applications/`

For distribution (unsigned): `codesign --force --deep -s - 'build/GLM Usage Monitor.app'`

## No Tests, No Lint

No test targets, test files, or test framework. No linter configured.

## Architecture

Single-target SwiftUI macOS menu bar app (`@main` in `App.swift`). Five source files in `GLMUsageWidget/`:

- **`App.swift`** — entry point; `GLMUsageWidgetApp` uses `MenuBarExtra` with `.window` style; `MenuBarLabel` shows the pinned token's 5-hour % if one is pinned, otherwise the highest 5-hour % across all tokens; color coding: green/yellow/orange/red at thresholds 50/70/90%
- **`Models.swift`** — `TokenConfig` (Codable, Identifiable — name + token only, no per-token URL); `TokenUsage` (config + stats + loading/error state); `QuotaLimitResponse` / `QuotaLimitData` / `QuotaLimit` (API shapes); `UsageStats` (derived display model with 5-hour and weekly fields)
- **`UsageService.swift`** — `ObservableObject`; fetches `https://api.z.ai/api/monitor/usage/quota/limit` (hardcoded) for all configured tokens concurrently via `Publishers.MergeMany`; refreshes on init and every 5 minutes; publishes `tokenUsages: [TokenUsage]` and `pinnedTokenId: UUID?`; quota `unit == 3` = 5-hour, `unit == 6` = weekly; logs to `/tmp/glm-widget.log`
- **`SettingsManager.swift`** — singleton; stores `[TokenConfig]` as JSON in the macOS Keychain (`service: "com.glm.usage-widget"`, `account: "token-configs"`); stores `pinnedTokenId: UUID?` in `UserDefaults` (key `"pinnedTokenId"`); `migrateFromClaudeSettings()` pre-populates the Add form from `~/.claude/settings.json` on first run; max 5 tokens enforced in UI
- **`MenuBarView.swift`** — `MenuBarView` toggles between `TokenListView`+`ActionsView` and `SettingsView`; `TokenListView` renders per-token `TokenRowView` (name + loading/error/`UsageBarsView`); `UsageBarsView` shows 5h and 7d progress bars with reset countdown; `ActionsView` has Refresh/Settings/Quit buttons; `SettingsView` has two sub-screens: `TokenListSettingsView` (list with radio-pin, edit, delete) and `TokenEditForm` (add/edit with SecureField + show/hide toggle)

## Runtime Configuration

Credentials stored in the macOS Keychain — no config file needed. On first launch the settings screen opens automatically. Users add up to 5 named tokens (name, auth token) via the in-app UI.

The pinned token (shown in menu bar label) is chosen via radio button in `TokenListSettingsView`; selecting the already-pinned token unpins it (falls back to highest %).

For machines that already have `~/.claude/settings.json`, the Add Token form pre-populates `ANTHROPIC_AUTH_TOKEN` as a one-time migration convenience (user must still click Save).

## Debugging

Runtime logs are appended to `/tmp/glm-widget.log`. Check this file when diagnosing auth or API errors.
