# GLM Usage Monitor

Native macOS menu bar app for monitoring [GLM Coding Plan](https://api.z.ai) token usage across multiple accounts.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **5-hour & weekly** usage bars per account
- Color-coded menu bar indicator: green → yellow → orange → red (at 50 / 70 / 90%)
- **Pin any token** to the menu bar label, or show the highest % automatically
- Up to 5 accounts, credentials stored in the macOS Keychain
- Auto-refresh every 5 minutes with manual Refresh button
- Reset time countdown per window

## Requirements

- macOS 13.0+
- Xcode Command Line Tools (`xcode-select --install`)
- A valid GLM API token

## Build & Install

```bash
# Clone
git clone https://github.com/rahul2123/glm-usage-widget.git
cd glm-usage-widget

# Compile
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift \
  -framework SwiftUI -framework AppKit -framework Foundation -framework Security

# Package into app bundle
./build.sh

# Install
cp -R 'build/GLM Usage Monitor.app' /Applications/

# Run
open '/Applications/GLM Usage Monitor.app'
```

> **First launch:** right-click the app → Open to bypass Gatekeeper (unsigned binary).

## Configuration

On first launch, the Settings screen opens automatically. Add a token with:

| Field | Value |
|-------|-------|
| Name | Any label (e.g. "Work") |
| Auth Token | Your GLM API token |

Tokens are stored in the macOS Keychain — no config files or environment variables needed.

If you already have a token in `~/.claude/settings.json` (`ANTHROPIC_AUTH_TOKEN`), the Add Token form pre-fills it automatically.

## Distribution (unsigned)

```bash
codesign --force --deep -s - 'build/GLM Usage Monitor.app'
```

## Development

```bash
# Recompile after changes
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift \
  -framework SwiftUI -framework AppKit -framework Foundation -framework Security
./build.sh
open 'build/GLM Usage Monitor.app'

# Runtime logs
tail -f /tmp/glm-widget.log
```

No tests, no linter. See [CLAUDE.md](CLAUDE.md) for architecture notes.

## License

MIT — see [LICENSE](LICENSE).
