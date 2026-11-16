# 手机厂商推送（Push）接入状态

> 目标数据流：主站/平台 → 厂商推送服务器 → 手机系统通知栏 → 用户点击 → App 带 dataid 打开对应帖子。

## 1. 已经完成的部分

- Android 系统通知通道：高重要性 `new_posts` 通道 + 专用小图标 `ic_stat_notify`；
- Android 13+ `POST_NOTIFICATIONS` 权限申请、系统设置跳转、设置页测试通知；
- 前台每 60s 轮询「主页」新帖，对比帖子 ID 产生提醒；
- 通知 payload 已带首条新帖 ID（`new_posts:<postId>`），点击后：
  - 回首页并清红点；
  - 直接 `push` 打开该帖子详情页（dataid 深链已通）；
- 小程序平台设备已注册（`POST /v1/devices`，当前 `pushProvider: local`，无厂商 token）；
- HarmonyOS 侧已有原生通知插件（`ssemarket/notifications`），可申请权限并弹通知。

## 2. 为什么“App 不打开就不通知”还没根治

当前新帖提醒依赖 **App 进程内的 60s 轮询**，进程被系统杀掉/冻结后定时器不再运行，
所以只能在前台/短时间后台提醒。要做到关闭 App 仍然通知，必须由厂商推送服务器在
系统级唤醒 App 的通知服务，这需要 **厂商推送 SDK + 应用配置 + 服务端密钥**。

仓库里目前没有任何推送配置文件，也没有厂商应用凭证：

- 无 `android/app/google-services.json`（FCM）
- 无 `ohos/entry/agconnect-services.json`（HMS / HarmonyOS）
- 无 APNs `.p8/.p12`、无 Windows WNS SID/Secret
- 平台侧也未配置对应厂商的 server key

因此无法凭空生成可用的 push token，代码不能只靠改 Dart 就完成这块。

## 3. 需要提供/确认的材料

按实际发行渠道选择（国内 Android 通常无法使用 FCM）：

| 平台 | 厂商 | 需要的东西 |
|---|---|---|
| Android 国内 | 华为 HMS Push | AppGallery 应用 + `agconnect-services.json` + 服务端 APP_ID/APP_SECRET |
| Android 国内 | 小米 / OPPO / vivo / 荣耀 | 各开放平台应用 + AppID/AppKey/AppSecret |
| Android 海外 | Google FCM | Firebase 项目 + `google-services.json` + 服务端 service account |
| HarmonyOS | 华为 Push Kit | `agconnect-services.json` + 应用签名证书 |
| iOS | APNs | Apple 开发者账号 + APNs Key（.p8）+ Key ID/Team ID |
| Windows | WNS | Microsoft Store 应用身份 + SID/Secret |

还需要平台管理员在 mp-service 侧配置同一套厂商服务端凭证（发推送用），
App 只负责拿 token 并 `POST /v1/devices` 上报。

## 4. 拿到材料后的接入步骤

1. Android：接入 `firebase_messaging`（FCM）或华为 `push` Flutter 插件；
   HarmonyOS：接入 HMS Push Kit 的 ArkTS/Flutter 插件；
2. 启动时拿 push token，调用已有的
   `MPPlatformApi.registerDevice(platform, pushProvider, pushToken, ...)`；
   token 变化时覆盖同一 `deviceID`；
3. 平台按订阅与静默时段推送；通知 payload 带 `postID`（平台事件 `new-posts` 的 dataid）；
4. App 冷启动读取通知 payload，复用现有 `new_posts:<id>` 深链直接打开帖子；
5. 保留前台 60s 轮询作为兜底（推送失败/未授权时仍能在 App 内看到提醒）。

## 5. 当前可验证的部分

- 在 App 前台发新帖，60s 内会收到系统通知；
- 点击通知会打开对应帖子（Android 本地通知已验证 payload 逻辑；真机需安装最新 APK 验证）；
- App 被完全杀死时不通知 —— **这是预期中的未完成项，等厂商凭证**。