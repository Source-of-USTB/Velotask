# Velotask

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![GitHub stars](https://img.shields.io/github/stars/Source-of-USTB/Velotask?style=social)](https://github.com/Source-of-USTB/Velotask/stargazers) [![Issues](https://img.shields.io/github/issues/Source-of-USTB/Velotask)](https://github.com/Source-of-USTB/Velotask/issues) [![GitHub Actions](https://img.shields.io/github/actions/workflow/status/Source-of-USTB/Velotask/build.yml?branch=main)](https://github.com/Source-of-USTB/Velotask/actions) [![Platform](https://img.shields.io/badge/platform-Flutter-blue.svg)](https://flutter.dev)

![banner](banner.jpg)

> Velotask doesn't just help you check off items quickly; it gives your day direction.

中文 | [English](README_en.md)

Velotask 是一款的现代、高效的任务管理应用。

它旨在通过简洁直观的界面帮助您追踪任务进度，截止日期并保持高效。

本项目基于 Flutter 构建。

## ✨ 支持功能

- **📝 任务管理**
  * 添加、编辑、删除任务。
  * 向右滑动标记完成。

- **🏷️ 任务详情**
  * 按标签组织任务。
  * 设置重要性、开始和截止日期。
  * 添加描述。

- **🤖 AI 解析**
  * 配置 API-KEY 使用 AI。
  * 把任务文本交给 AI, 支持一次解析多个任务！
  * 数据**仅存储本地**。

- **🎨 个性化 UI**
  * 支持亮暗主题切换。
  * 可视化任务进度。
  * 筛选进行中或已完成任务。

* **🚀 高性能**
  * Drift 数据库驱动，支持离线优先。

## 🛠️ 技术栈

* **框架**: [Flutter](https://flutter.dev/)
* **语言**: [Dart](https://dart.dev/)
* **数据库**: [Drift](https://drift.simonbinder.eu/) 

<!-- * **通知**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone) -->

---

## 🚀 快速开始

### 前置要求

* 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)。
* 配置好 Flutter 开发环境的 IDE（VS Code 或 Android Studio）。

### 安装步骤

1. **克隆仓库**

    ```bash
    git clone https://github.com/Source-of-USTB/Velotask.git
    cd velotask
    ```

2. **安装依赖**

    ```bash
    flutter pub get
    ```

3. **运行代码生成器**

    ```bash
    dart run build_runner build
    ```

4. **运行应用**

    ```bash
    flutter run
    ```

## 📦 构建

### Android

构建 Android APK 安装包：

```bash
flutter build apk
```

* **注意**：为了减小特定架构的文件体积，可以使用：

    ```bash
    flutter build apk --split-per-abi
    ```

### Windows

构建 Windows 可执行文件：

```bash
flutter build windows
```

### Others

暂未对其他平台进行验证

## 🤝 贡献

非常欢迎您的贡献！如果您发现任何 Bug 或有新的功能建议，请随时提交 Issue 或 Pull Request。

查看我们的 [开发路线图](docs/ROADMAP.md) 了解未来的开发计划。

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

[MIT License](LICENSE)
