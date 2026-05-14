# AGENTS.md

## Build

Two-step build. Do **not** use `swift build` — the project compiles with raw `swiftc`:

```bash
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift -framework SwiftUI -framework AppKit -framework Foundation
./build.sh
```

- `build.sh` packages the binary into `build/GLM Usage Monitor.app` (macOS app bundle with icons via `iconutil`)
- `Package.swift` exists for IDE tooling but is **not** the actual build path
- Output binary goes to `bin/`; app bundle to `build/`

## Testing

No tests. No test targets in Package.swift, no test files, no test framework.

## Lint / Format

None configured.

## Architecture

Single-target SwiftUI macOS menu bar app (`@main` → `GLMUsageWidgetApp`). Five source files in `GLMUsageWidget/`:

- `App.swift` — entry point, `MenuBarExtra` with `.window` style
- `Models.swift` — `QuotaLimitResponse` (Codable API models), `UsageStats`
- `UsageService.swift` — `ObservableObject` fetching from `/api/monitor/usage/quota/limit`, 5-minute timer, logs to `/tmp/glm-widget.log`
- `SettingsManager.swift` — singleton reading `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_BASE_URL` from `~/.claude/settings.json`
- `MenuBarView.swift` — all UI views (detail, loading, error, actions)

## Runtime Config

Reads auth credentials from `~/.claude/settings.json` (`env.ANTHROPIC_AUTH_TOKEN`, `env.ANTHROPIC_BASE_URL`). No local config file. Strips `/api/anthropic` suffix from base URL.

## Distribution

Unsigned app. Requires right-click → Open on first launch to bypass Gatekeeper. Codesign with `codesign --force --deep -s - build/GLMUsageWidget.app` for distribution.
