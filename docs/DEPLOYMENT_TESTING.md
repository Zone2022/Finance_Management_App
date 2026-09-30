# 部署与测试流程

## 0. 当前验证边界

2026-09-07 已通过 Dart 分析和 16 项自动化测试；Android Debug 构建实际报错 `No Android SDK found`。以下 Android 操作是后续待执行流程，不是已经完成的部署记录。

本项目主要部署到 Android 手机。没有需要部署的自建服务器；DeepSeek 为可选外部服务。当前 Windows/Web 目录只是模板，不能直接替代 Android 验收。

## 1. 环境准备

1. 安装 Flutter。建议先使用本次验证的 Flutter 3.44.9 / Dart 3.12.2，避免把升级依赖和业务修复混在一起；保留 pubspec.lock。
2. 安装 Android Studio 和 Android SDK，通过 SDK Manager 安装 SDK Platform、Build-Tools、Platform-Tools、Command-line Tools；编译版本由本地 Flutter Gradle 配置决定，不要凭旧文档固定一个版本。
3. 配置兼容当前 Android Gradle Plugin 的 JDK；当前项目 AGP 9.0.1、Gradle 9.1.0，源码/字节码目标为 Java 17，最终以 Gradle 构建诊断验证工具链兼容性。
4. 连接开启 USB 调试的 Android 手机，或创建 Android 模拟器。微信/支付宝真实通知最终应在真机验收。

PowerShell 示例：

```powershell
Set-Location C:\Users\24190\Projects\flutter_finance
$env:Path = "C:\Users\24190\flutter\bin;$env:Path"
flutter --version
flutter config --android-sdk "C:\Users\24190\AppData\Local\Android\Sdk"
flutter doctor --android-licenses
flutter doctor -v
flutter devices
```

Android SDK 路径按实际安装位置调整。应确认 doctor 的 Android toolchain 正常、有 Android 设备、Gradle/Maven 仓库可访问。本机此前 Maven TLS 检查失败，应修正网络/代理/证书配置，不要禁用证书验证。

## 2. 自动化检查门槛

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

验收标准：格式检查无差异，分析零问题，全部测试通过。coverage/lcov.info 是本地覆盖率文件，不代表原生通知链路覆盖率。

当前测试：

| 文件 | 验证点 |
| --- | --- |
| test/database_test.dart | 真实 SQLite：并发初始化、月末边界、自然日日均、并发幂等、金额校验、商户规则、v1→v2 迁移 |
| test/ai_service_test.dart | 单例共享、未配置不联网、中文解析、非法分类与 HTTP 失败回退 |
| test/widget_test.dart | 导航、来源筛选/清空、入账刷新、收入符号、失败重试、图表月份与零值 |

后续应增加原生解析器/暂存队列单元测试，以及 Android integration_test；当前仓库没有此类集成测试，不要把 `flutter test` 当成系统通知验收。

## 3. Debug 安装与功能验收

```powershell
flutter run -d <Android设备ID>
# 或先构建，再通过设备安装
flutter build apk --debug
adb -s <Android设备ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

在应用设置中打开「通知使用权设置」，人工开启本应用；返回应用。允许普通通知发送不能替代此授权。

建议按以下顺序记录期望值、实际值、设备/Android/微信/支付宝版本和脱敏样本：

| 场景 | 期望结果 |
| --- | --- |
| 首次启动、无数据 | 四个标签可打开，无无限加载，图表显示暂无数据 |
| 快捷入口 | 点击「查看全部流水」切到流水，历史月份记录也可见 |
| 来源、类别筛选 | 微信/支付宝/类别可切换，再选全部恢复；无崩溃 |
| 未授予通知读取权限 | 应用可查看现有账本，设置入口可用，无错误入账 |
| 已授权，前台支持格式支付通知 | 入账一次，金额/时间正确；概览、流水、报表自动更新 |
| 无 Flutter 界面，监听服务仍工作 | 通知先暂存；重新打开应用补录，补录后重启不重复 |
| 写库成功、确认删除暂存前进程结束 | 下次重放仍只有一条交易 |
| 多条通知连续到达 | 串行入库，全部保留，分类与金额不串单 |
| 同一事件重复回调 | 系统通知 key + postTime 不变时只记一次 |
| 聊天里提到金额、营销、收款、退款、分组摘要 | 不应被当作支出自动入账 |
| 本地规则「美团买药」和「美团」同时存在 | 更具体规则优先，归医疗 |
| 未配置 AI / 网络失败 / 错误 Key | 本地已知规则仍可用，未知商户回退其他，账单不丢 |
| 配置 AI | 未匹配商户能分类，界面遮挡 Key；重启后需重新配置 |
| 月末 23:59:59.999 与次月 00:00:00 | 分别计入对应月份；自然日日均符合预期 |
| 零消费、跨年、无交易月份 | 不崩溃，月份 1～12 正确，无交易月份趋势为零 |
| 撤销/重新授权、锁屏、回前台 | 记录是否恢复监听，恢复后补录已成功暂存事件 |
| 小屏与大金额 | 卡片金额可读、无布局溢出 |

解析器目前要求白名单标题和「支付成功/付款成功/消费成功」语义。若真实版本不产生这些格式，应先扩充解析器和样本测试，不应为了通过测试放宽到「任何带金额的消息」。通知不是官方账单；手机未产生通知的交易无法靠监听补齐。

ADB 发普通测试通知的包名不在微信/支付宝白名单内，应被忽略。这类测试不能证明真实支付采集成功。不要为验收绕过生产包名过滤；可通过专用测试 harness 将脱敏样本注入解析器。

## 4. 升级与数据验收

- 在保留旧应用数据的测试设备上覆盖安装同签名新版，不先卸载。v1→v2 应保留原有交易并新增 event_id 列/索引；旧事件不会被自动追溯去重。
- 升级前保存测试账本快照，升级后对照笔数、总支出、类别汇总、月份边界。
- 自动化迁移测试已经通过，但不能替代设备上实际 SQLite/安装升级验证。
- 原 Debug 版本与新正式签名版本通常不能直接覆盖安装；不要通过卸载来验证保留数据升级。需要用相同正式签名准备旧版和新版测试包。
- 当前没有备份/导入 UI，真实账本应先解决备份和恢复，再进行生产升级。数据库已升 v2 后，不应直接降级运行仅认识 v1 的旧包；优先用新构建号发布向前修复版本。

## 5. Release 签名与构建

代码已移除 Debug 签名回退。准备自己的发布 keystore，复制模板 `android/key.properties.example` 为 `android/key.properties`，本地填写：

```properties
storeFile=C:/secure/finance-upload.jks
storePassword=<本地填写>
keyAlias=upload
keyPassword=<本地填写>
```

密钥文件需要自行生成并备份，模板不是有效密钥。key.properties、*.jks、*.keystore 已在 android/.gitignore 中排除；当前目录尚未初始化 Git，初始化后仍应检查忽略规则。不要把密钥或密码放入 README、CI 日志或版本库。

先确认 applicationId/应用名称符合最终产品命名，更新 pubspec.yaml 的版本号和递增构建号，再运行：

```powershell
flutter build apk --release
flutter build appbundle --release
```

- APK：`build/app/outputs/flutter-apk/app-release.apk`，用于同签名设备测试/受控分发。
- AAB：`build/app/outputs/bundle/release/app-release.aab`，用于应用商店上传，不是可直接 adb install 的 APK。
- 使用 SDK Build-Tools 的 `apksigner verify --verbose --print-certs <APK路径>` 检查签名，核对证书，不应是 Android Debug。
- Release 真机再次验证通知权限、后台暂存/恢复、数据库升级、图表和 DeepSeek 网络。Debug 通过不代表 Release 通过。
- 先内部测试，再小范围发布；记录版本、构建号、签名指纹、设备测试结果。当前尚未执行任何商店上传/公开发布。

官方步骤：[Flutter Android 构建与签名](https://docs.flutter.dev/deployment/android)。通知服务系统行为参见 [Android NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)。平台数据库支持参见 [sqflite](https://pub.dev/packages/sqflite)。

## 6. 发布准入

只有在以下事项完成后，才应把该原型认定为可正式使用的记账应用：Android 原生编译与真机验收通过；关键真实支付通知样本识别可靠；重复通知与漏单可发现和纠正；提供补录/编辑/删除或对账途径；确认数据备份策略；正式签名、升级保留数据和 Release 网络验证通过。
