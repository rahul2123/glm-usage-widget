# GLM Usage Monitor

Native macOS menu bar app showing GLM Coding Plan token usage.

## Features

- Token usage percentage (5-hour rolling window)
- Color-coded indicator (green → yellow → orange → red)
- Auto-refresh every 5 minutes
- Reset time countdown

## Installation

```bash
# Build
cd ~/work/glm-usage-widget
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift -framework SwiftUI -framework AppKit -framework Foundation
./build.sh

# Install
cp -R build/GLMUsageWidget.app /Applications/

# Run
open /Applications/GLMUsageWidget.app
```

First launch: right-click the app → Open (bypasses Gatekeeper for unsigned apps).

## Configuration

The widget reads authentication from `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-token-here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai"
  }
}
```

## API Endpoint

- `/api/monitor/usage/quota/limit` — Token usage percentage and reset time

## Requirements

- macOS 13.0+
- Valid GLM API credentials in `~/.claude/settings.json`

## Development

```bash
# Compile
swiftc -o bin/GLMUsageWidget GLMUsageWidget/*.swift \
  -framework SwiftUI -framework AppKit -framework Foundation

# Build app bundle
./build.sh

# Sign (for distribution)
codesign --force --deep -s - build/GLMUsageWidget.app
```
