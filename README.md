# 基于 Flutter 与 Material Design 3 的 Android 通知监听原型系统：Notif Hub

**摘要**：本文档对一型面向 Android 平台的跨端移动应用原型——**Notif Hub**（工程标识：`notif_hub`）之设计动机、系统架构、权限与安全边界、功能构成及构建流程予以系统性阐述。该原型依托 **Flutter** 框架实现用户界面与业务逻辑，采用 **Material Design 3（M3）** 作为视觉与交互范式，并在原生层集成 **NotificationListenerService** 机制，以在用户显式授权前提下采集并展示来自第三方应用程序之通知事件。鉴于通知内容可能承载敏感信息，本文亦从移动操作系统安全模型角度讨论其合规使用边界。

**关键词**：Flutter；Material Design 3；Android；通知监听服务；最小权限原则；侧载分发

---

## 1 引言与研究背景

在现代移动生态中，操作系统通过**通知中心（Notification Shade）**向用户聚合多源信息。对特定应用场景（如个人财务管理、消息聚合研究或无障碍辅助原型）而言，在**用户知情同意**与**系统级显式授权**之前提下，对通知事件进行结构化采集具有理论与工程意义。

Android 自 API 18 起提供 **`NotificationListenerService`** 接口，使经用户于系统设置中授权的受信应用得以接收通知的发布与移除事件。本仓库所实现之 **Notif Hub** 即基于该机制之教学/研究向最小可行原型（MVP），辅以 **Flutter** 的声明式 UI 与 **M3** 设计语言，以验证跨层数据流与权限门控之可行性。

---

## 2 系统需求与运行环境

### 2.1 硬件与平台约束

- **目标平台**：Android（本工程当前仅配置 Android 构建目标）。
- **指令集架构**：默认于 `android/app/build.gradle.kts` 中通过 `ndk { abiFilters += listOf("arm64-v8a") }` 限定为 **ARM64（arm64-v8a）**，以减小交付物体积并契合主流 64 位终端设备。

### 2.2 开发工具链

| 组件 | 说明 |
|------|------|
| Flutter SDK | 稳定通道，建议与 `pubspec.yaml` 中 `environment.sdk` 约束一致 |
| Dart | 随 Flutter 分发 |
| JDK | **17**（与 Android Gradle Plugin 之常见配置相容） |
| Android SDK | 含 **Platform**、**Build-Tools**、**NDK**（具体版本由 Flutter/Gradle 解析） |

---

## 3 系统架构与模块划分

### 3.1 总体架构

应用采用经典 **单 Activity + Flutter Engine** 嵌入模式。Dart 层负责状态管理、持久化策略及 UI 渲染；Java/Kotlin 侧由第三方插件 **`notification_listener_service`** 封装 **`NotificationListener`** 服务，经 **方法通道（Method Channel）** 与 **事件流（Stream）** 向 Dart 层投递 `ServiceNotificationEvent`。

### 3.2 逻辑分层

1. **表示层**：`lib/pages/` 下各页面组件，遵循 M3 之 `NavigationBar`、`Card`、`ListTile` 等构件组合。
2. **控制与状态层**：`AppController`（`ChangeNotifier`）统一维护监听授权状态、白名单集合及已捕获通知列表。
3. **持久化层**：`shared_preferences` 存储用户选定之应用包名白名单。
4. **系统元数据层**：`installed_apps` 用于枚举可启动之非系统应用列表，以支撑「按应用启用监听」之交互。

### 3.3 导航结构

底部 **`NavigationBar`** 含二目：**「通知」**与**「设置」**。未授予通知监听权限时，应用以全屏门控页引导用户跳转至系统设置完成授权；授权后始可进入主导航。

---

## 4 权限、安全与合规性讨论

### 4.1 权限模型

- **`BIND_NOTIFICATION_LISTENER_SERVICE`**：由系统在用户于「通知访问」设置中启用本应用之监听服务后生效；应用**不得**在未获用户交互确认的情况下隐式获取该能力。
- **`QUERY_ALL_PACKAGES`（间接）**：`installed_apps` 插件可能在合并清单中声明该权限，以枚举已安装应用；其使用应符合 Google Play 及本地法规对包可见性之要求。

### 4.2 安全与隐私边界

通知载荷可能包含 **一次性口令（OTP）**、金融交易摘要等敏感数据。本原型在 Dart 层依据**白名单**过滤事件：仅当 `packageName` 属于用户显式勾选之集合时，方将事件纳入界面列表。此举体现 **最小必要原则（Data Minimization）** 之工程近似，**并不**免除开发者在产品化阶段须提供隐私政策、数据留存说明及安全存储方案之法定义务。

### 4.3 分发与平台风控

经 **侧载（Sideload）** 安装之 APK 可能触发 **Google Play Protect** 等机制之启发式评估；该行为系平台安全策略之体现，**非**应用层可通过简单配置完全消除之确定性结果。若面向公众分发，宜遵循官方应用商店之政策披露与审核流程。

---

## 5 功能规格摘要

| 功能项 | 描述 |
|--------|------|
| 授权门控 | 首次启动强制引导完成通知监听授权 |
| 按应用开关 | 设置页枚举应用，用户勾选需监听之 `packageName` |
| 通知列表 | 主列表以 M3 风格展示标题、正文、包名与时间等元数据 |
| 生命周期同步 | 应用自后台恢复时重新校验监听授权状态 |

---

## 6 依赖项（节选）

- `flutter`（SDK）
- `notification_listener_service`：桥接 `NotificationListenerService`
- `shared_preferences`：键值持久化
- `installed_apps`：已安装应用元数据枚举

完整约束见 **`pubspec.yaml`** 与 **`pubspec.lock`**。

---

## 7 构建与运行

于项目根目录执行：

```bash
flutter pub get
flutter run
```

发布用 **Release** 且仅含 **ARM64** 引擎产物之示例：

```bash
flutter build apk --release --target-platform android-arm64
```

生成路径通常为：`build/app/outputs/flutter-apk/app-release.apk`。

**说明**：`android/local.properties` 含本机 SDK 路径，默认由 `.gitignore` 排除，克隆后需在本地配置 `sdk.dir` 或通过 Android Studio 自动重建。

---

## 8 仓库与许可证

- **远程仓库**：[https://github.com/WIKKIwk/unofficial_calculator](https://github.com/WIKKIwk/unofficial_calculator)  
- 本 README 旨在提供**学术化技术说明**；**默认 Flutter 模板许可证**以各生成文件及上游依赖为准。若将本项目用于科研或教学，建议在论文或课程材料中注明出处及所用第三方库版本。

---

## 9 参考文献与延伸阅读

1. Android Developers. *NotificationListenerService*. [https://developer.android.com/reference/android/service/notification/NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)  
2. Google. *Material Design 3*. [https://m3.material.io/](https://m3.material.io/)  
3. Flutter Team. *Flutter documentation*. [https://docs.flutter.dev/](https://docs.flutter.dev/)  
4. Pub.dev. *notification_listener_service*. [https://pub.dev/packages/notification_listener_service](https://pub.dev/packages/notification_listener_service)

---

**结语**：Notif Hub 作为一型**最小原型**，其学术价值在于演示 Android 通知子系统与 Flutter 声明式 UI 之集成路径，以及在工程上对白名单过滤与显式授权之落实。后续工作可扩展至加密本地存储、可审计日志、与后端同步之隐私增强设计等方向。
