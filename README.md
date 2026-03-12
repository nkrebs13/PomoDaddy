# 🍅 PomoDaddy

**A playful macOS Pomodoro timer that lives in your menu bar**

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

<!-- Screenshots coming soon -->

---

## ✨ Features

- **🎯 Menu Bar App** — Unobtrusive design with a dynamic progress icon that fills as your session progresses
- **🪟 Floating Timer Window** — Draggable overlay that stays on top; position is remembered between sessions
- **⏱️ Classic Pomodoro Technique** — Default intervals of 25 min work / 5 min break / 15 min long break
- **⚙️ Customizable Intervals** — Adjust work and break durations to match your flow
- **📊 Statistics Tracking** — Monitor your productivity with daily totals, weekly summaries, and streak tracking
- **🎉 Celebratory Confetti** — Delightful animations when you complete a session
- **🔕 Silent Notifications** — Non-intrusive alerts that won't disturb your focus
- **⌨️ App-Only Keyboard Shortcuts** — Quick controls without conflicting with other apps

---

## 📋 Requirements

| Requirement | Version |
|-------------|---------|
| macOS       | 14.0+   |
| Xcode       | 15+     |

---

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/nkrebs13/PomoDaddy.git
   cd PomoDaddy
   ```

2. **Install XcodeGen** (if not already installed)
   ```bash
   brew install xcodegen
   ```

3. **Generate the Xcode project**
   ```bash
   xcodegen generate
   ```

4. **Build and run**
   - Open `PomoDaddy.xcodeproj` in Xcode
   - Select your target and click **Run** (⌘R)

---

## 📖 Usage

1. **Launch PomoDaddy** — The tomato icon appears in your menu bar
2. **Start a session** — Click the menu bar icon and select "Start" or use the floating window
3. **Stay focused** — Watch the progress icon fill up as you work
4. **Take breaks** — PomoDaddy automatically transitions to break time when your work session ends
5. **Track progress** — View your statistics to see daily completions, weekly trends, and current streaks

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space`  | Start/Pause timer |
| `R`      | Reset current session |
| `S`      | Open statistics |

---

## 🏗️ Architecture

PomoDaddy follows a clean SwiftUI architecture with SwiftData for persistence.

📄 **[View Full Architecture Documentation](docs/architecture.md)**

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

---

## 🔒 Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

---

## 🔐 Privacy

PomoDaddy stores all data locally on your Mac using SwiftData. There are no network requests, no telemetry, no analytics, and no data leaves your device.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

Built with love using:

- **[SwiftUI](https://developer.apple.com/xcode/swiftui/)** — Apple's declarative UI framework
- **[SwiftData](https://developer.apple.com/xcode/swiftdata/)** — Modern data persistence
- **[Vortex](https://github.com/twostraws/Vortex)** — Particle effects for celebratory confetti 🎊

---

<p align="center">
  <sub>Made with 🍅 by developers who needed a better way to focus</sub>
</p>
