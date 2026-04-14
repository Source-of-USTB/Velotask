# Velotask

中文 | [English](README_en.md)

Velotask 是一款基于 Flutter 构建的现代、高效且用户友好的任务管理应用。它旨在通过简洁直观的界面帮助您规划生活、追踪进度并保持高效。

> Velotask doesn't just help you check off items quickly; it gives your day direction.

## ✨ 功能特性

* **📝 全面的任务管理**
  * 轻松创建、编辑和删除任务。
  * 简单的切换操作即可标记任务完成。
  * UI 更新：在操作任务时体验即时的界面反馈。

* **🏷️ 丰富的任务详情**
  * **分类管理**：按类型（Tags）组织任务。
  * **优先级设置**：设置重要程度（低、普通、高）以聚焦关键事项。
  * **日程规划**：设置开始日期和截止日期，有效管理时间。
  * 为任务添加详细描述。

* **🔔 智能本地通知**
  * **Urgency 驱动提醒**：基于任务紧急度曲线，在截止前“最该提醒”的时刻触发一次提醒。
  * **截止回退策略**：当紧急度阈值时机不可用时，自动回退到更临近截止的提醒时刻。
  * **每日摘要通知**：每天固定时间推送一次当日待办摘要。
  * **后台可达**：使用系统本地调度，应用未启动时仍可接收提醒。

* **🤖 智能输入**
  * 支持自然语言解析输入（例如“明天下午5点买牛奶”）并自动生成任务字段。

* **🎨 现代 UI 与个性化**
  * **主题支持**：在亮色和暗色模式间切换。
  * **主题持久化**：自动保存您的主题偏好。
  * **进度追踪**：可视化的任务完成进度指示器。
  * **筛选功能**：轻松筛选查看进行中或已完成的任务。

* **🚀 高性能**
  * 由 **Isar Database** 驱动，提供闪电般的本地数据存储速度。
  * 离线优先架构。

## 🛠️ 技术栈

* **框架**: [Flutter](https://flutter.dev/)
* **语言**: [Dart](https://dart.dev/)
* **数据库**: [Drift](https://drift.simonbinder.eu/)
* **通知**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone)

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

3. **运行代码生成器**（Isar 数据库需要）

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

查看我们的 [开发路线图 (Roadmap)](ROADMAP.md) 了解未来的开发计划。

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

[MIT License](LICENSE)
