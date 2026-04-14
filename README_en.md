# Velotask

[中文](README.md) | English

Velotask is a modern, efficient, and user-friendly task management application built with Flutter. It is designed to help you organize your life, track your progress, and stay productive with a clean and intuitive interface.

> Velotask doesn't just help you check off items quickly; it gives your day direction.

## ✨ Features

* **📝 Comprehensive Task Management**
  * Create, edit, and delete tasks easily.
  * Mark tasks as completed with a simple toggle.
  * **Optimistic UI Updates**: Experience instant feedback when interacting with tasks.

* **🏷️ Rich Task Details**
  * **Categorization**: Organize tasks by types:
    * **DDL**: Deadline-driven tasks.
    * **TDL**: Standard To-Do List items.
    * **WTD**: "Want To Do" - personal goals or wishlists.
  * **Prioritization**: Set importance levels (Low, Normal, High) to focus on what matters.
  * **Scheduling**: Set Start Dates and Deadlines to manage your time effectively.
  * Add detailed descriptions to your tasks.

* **🔔 Smart Local Notifications**
  * **Urgency-driven reminder**: Triggers a single reminder at the most meaningful pre-deadline moment based on task urgency.
  * **Deadline fallback strategy**: Automatically falls back to a later pre-deadline reminder when urgency-threshold timing is not available.
  * **Daily summary notification**: Sends one scheduled summary notification per day.
  * **Works in background**: Uses system local scheduling, so reminders can arrive even when the app is not running.

* **🤖 Intelligent Input**
  * Supports natural language task parsing (for example, “Buy milk tomorrow at 5pm”).

* **🎨 Modern UI & Customization**
  * **Theme Support**: Switch between Light and Dark modes.
  * **Theme Persistence**: Your theme preference is saved automatically.
  * **Progress Tracking**: Visual indicators of your task completion progress.
  * **Filtering**: Easily filter tasks to see what's active or completed.

* **🚀 High Performance**
  * Powered by **Isar Database** for lightning-fast local data storage.
  * Offline-first architecture.

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/)
* **Language**: [Dart](https://dart.dev/)
* **Database**: [Drift](https://drift.simonbinder.eu/)
* **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone)

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
* An IDE (VS Code or Android Studio) configured for Flutter development.

### Installation

1. **Clone the repository**

    ```bash
    git clone https://github.com/Source-of-USTB/Velotask.git
    cd velotask
    ```

2. **Install dependencies**

    ```bash
    flutter pub get
    ```

3. **Run the code generator** (required for Isar database)

    ```bash
    dart run build_runner build
    ```

4. **Run the app**

    ```bash
    flutter run
    ```

## 📦 Building

### Android

To build an APK for Android devices:

```bash
flutter build apk
```

* **Note**: To reduce file size for specific architectures, use:

    ```bash
    flutter build apk --split-per-abi
    ```

### Windows

To build a Windows executable:

```bash
flutter build windows
```

### Others

We haven't tested on other platforms yet.

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

Check out our [Development Roadmap](ROADMAP.md) to see what's planned for the future.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

[MIT License](LICENSE)
