# Velotask

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/Source-of-USTB/Velotask?style=social)](https://github.com/Source-of-USTB/Velotask/stargazers) [![Issues](https://img.shields.io/github/issues/Source-of-USTB/Velotask)](https://github.com/Source-of-USTB/Velotask/issues) [![GitHub Actions](https://img.shields.io/github/actions/workflow/status/Source-of-USTB/Velotask/build.yml?branch=main)](https://github.com/Source-of-USTB/Velotask/actions) [![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)

![banner](docs/banner.jpg)

> Velotask doesn't just help you check off items quickly; it gives your day direction.

[中文](README.md) | English

Velotask is a simple, fast task app. Built with Flutter.

## ✨ Features

- **📝 Task Management**
  * Add, edit, delete tasks; swipe to mark complete.
  * Three task types: todo, deadline, and date range.

- **🏷️ Tags & Organization**
  * Custom tags with color, filter by tag.
  * Set priority, start/due dates, estimated effort hours.

- **📊 Timeline View**
  * Gantt-style timeline showing task spans at a glance.
  * Ctrl/Cmd + scroll to zoom, jump-to-today shortcut.
  * Weekend highlights, grid lines, red "now" line.

- **🤖 AI Parsing**
  * OpenAI-compatible API — turn natural language into structured tasks.
  * Parses multiple tasks at once, infers task type and dates.
  * All data stays local.

- **🎨 Personalization**
  * Light / dark theme.
  * Visual progress bar, completion celebration.
  * Editable colour preset system (8 groups, 41 keys, light+dark pairs).

- **🚀 Offline-first**
  * Drift (SQLite) database. Everything is stored locally.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Database**: [Drift](https://drift.simonbinder.eu/)

## 🚀 Getting Started

### Prerequisites

- Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Set up IDE (VS Code or Android Studio).

### Installation

1. Clone the repo:

    ```bash
    git clone https://github.com/Source-of-USTB/Velotask.git
    cd velotask
    ```

2. Install dependencies:

    ```bash
    flutter pub get
    ```

3. Run code generator:

    ```bash
    dart run build_runner build
    ```

4. Run the app:

    ```bash
    flutter run
    ```

## 📦 Building

### Android

Build APK:

```bash
flutter build apk
```

To reduce size:

```bash
flutter build apk --split-per-abi
```

### Windows

Build Windows executable:

```bash
flutter build windows
```

### Others

Not tested yet.

## 🤝 Contributing

Your contributions are very welcome! If you find any bugs or have suggestions for new features, feel free to submit an Issue or Pull Request.

Check [Roadmap](docs/ROADMAP_en.md) for our future plans.

1. Fork repo.
2. Create branch (`git checkout -b feature/AmazingFeature`).
3. Commit changes (`git commit -m 'Add AmazingFeature'`).
4. Push branch (`git push origin feature/AmazingFeature`).
5. Open Pull Request.

## 📄 License

[MIT License](LICENSE)
