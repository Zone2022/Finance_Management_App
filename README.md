# 个人财务管理 Flutter 应用

这是一个以 Android 为主要目标的本地记账原型：读取支持格式的微信/支付宝支付通知，通过本地商户规则和可选 DeepSeek 分类，把支出保存到 SQLite，并提供流水、月度汇总和年度图表。项目没有业务后端、账户系统或云同步。

当前状态：已修复一批交互、统计、分类和通知持久化问题，Dart 静态分析及 16 项回归测试通过；Android 原生编译、签名包、真机通知尚未验收，不能据此认定可以正式发布。

- [代码架构、问题与修复说明](docs/ARCHITECTURE_REVIEW.md)
- [部署、测试与发布验收流程](docs/DEPLOYMENT_TESTING.md)

## 快速验证

本次使用 Flutter 3.44.9 / Dart 3.12.2。依赖锁文件应随应用代码保留；pubspec 的最低版本已与当前依赖要求对齐。Windows PowerShell：

```powershell
$env:Path = "C:\Users\24190\flutter\bin;$env:Path"
flutter --version
flutter pub get
flutter analyze
flutter test
```

准备好 Android SDK、许可证和 Android 手机/模拟器后：

```powershell
flutter doctor -v
flutter devices
flutter run -d <Android设备ID>
```

首次运行后，在应用「设置 → 打开通知使用权设置」中手动授予本应用通知读取权限。普通通知发送权限不等于通知读取权限。不配置 AI Key 时只使用本地规则；配置后，未匹配的商户名会发送到 DeepSeek，Key 仅在本次进程运行中有效。

目录虽然包含 iOS、Web、Windows 等 Flutter 模板，但自动通知记账目前只有 Android 实现；桌面和 Web 未配置生产数据库实现，不应作为本项目的完整部署目标。SQLite FFI 依赖仅供自动化测试。
