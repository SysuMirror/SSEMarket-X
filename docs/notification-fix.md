# 新帖系统通知修复记录

## 现象

App 有新帖时不弹 Android 系统通知，App 内也没有明显的权限提示。

## 根因

1. **Android small icon 被资源压缩器删除**
   - `flutter_local_notifications` 初始化用 `@mipmap/ic_launcher`；
   - 后来改用 `ic_stat_notify`，但只以字符串形式引用，Release 资源压缩器看不到静态引用，把 `drawable/ic_stat_notify` 移除了；
   - Android 8+ 收到无有效 small icon 的通知会拒绝，`show()` 抛异常；
   - 原代码 catch 后静默，所以表现为“完全没通知”。

2. **权限流程不够稳**
   - Android 13+ 需要 `POST_NOTIFICATIONS` 运行时权限；
   - 原逻辑在首帧前申请，失败也可能把“已申请”标记写掉，后续不再弹；
   - 用户拒绝后没有“去系统设置”的入口。

## 修复

- 新增 `android/app/src/main/res/drawable/ic_stat_notify.xml`（纯白剪影）；
- 新增 `android/app/src/main/res/raw/keep.xml`：
  ```xml
  tools:keep="@drawable/ic_stat_notify"
  ```
- 初始化与 `AndroidNotificationDetails` 都使用 `ic_stat_notify`；
- 显式创建高优先级通道 `new_posts`；
- `NotificationService` 新增：
  - `areNotificationsEnabled()`
  - `showTestNotification()`
  - `openSystemSettings()`（Android `ACTION_APP_NOTIFICATION_SETTINGS`）
- 启动流程：先检查已授权，未授权才申请；延迟 600ms 等 Activity resumed；被拒绝时 App 内提示“去开启”；
- 设置 → 通知设置：
  - 显示系统权限状态
  - 「发送测试通知」按钮
  - 新帖通知开关会重新申请权限
- 通知失败不再静默，写 `debugPrint`。

## APK 验证

已确认 release APK 中包含：

```text
com.susse.market:drawable/ic_stat_notify
android.permission.POST_NOTIFICATIONS
```

## 用户体验验证步骤

1. 安装新 APK；
2. 我的 → 设置 → 通知设置 → **发送测试通知**；
3. 允许系统通知；
4. 应看到“通知测试”通知；
5. 之后新帖轮询（60 秒）会走同一通道弹通知；
6. App 退到后台但进程仍存活时，轮询继续运行，通知照常弹出（之前 `didChangeAppLifecycleState` 在 paused 时错误地 `stop()` 了轮询，已修复）。

## 仍有限制

- App 进程被系统杀掉 / 被深度冻结后不会轮询；
- iOS/HarmonyOS 进入后台一段时间后系统会挂起进程，轮询同样会停；
- 要“App 完全关闭也通知”，必须接 FCM/HMS/APNs 等厂商推送（见 `docs/push-integration.md`）。