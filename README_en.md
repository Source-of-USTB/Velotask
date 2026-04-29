# Velotask

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/Source-of-USTB/Velotask?style=social)](https://github.com/Source-of-USTB/Velotask/stargazers) [![Issues](https://img.shields.io/github/issues/Source-of-USTB/Velotask)](https://github.com/Source-of-USTB/Velotask/issues) [![GitHub Actions](https://img.shields.io/github/actions/workflow/status/Source-of-USTB/Velotask/build.yml?branch=main)](https://github.com/Source-of-USTB/Velotask/actions) [![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)

![banner](banner.jpg)

> Velotask doesn't just help you check off items quickly; it gives your day direction.

[中文](README.md) | English

Velotask is a simple, fast task app. Built with Flutter.

## ✨ Features

- **📝 Task Management**
  * Add, edit, delete tasks.
  * Swipe right to mark done.

- **🏷️ Task Details**
  * Organize by tags.
  * Set priority, start, and due dates.
  * Add descriptions.

- **🤖 AI Features**
  * Configure API key to use AI features (OpenAI-compatible).
  * Let AI parse task text – supports multiple tasks at once!
  * All data stays local – never uploaded to the cloud.

- **🎨 Custom UI**
  * Light and dark themes.
  * See task progress.
  * Filter active or done tasks.

- **🚀 Fast and Offline**
  * Powered by Drift database. Works offline.

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
