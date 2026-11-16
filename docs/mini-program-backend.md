# 集市小程序后端：独立新服务方案

> 状态：设计文档（待评审，不包含实现）
> 目标读者：负责新建小程序后端的同学 / 运维
> 结论先说：**新建一个独立的“小程序平台服务”，不复用现有 `SSE_market_server` 的进程、数据库、Redis、MinIO 桶和对外凭证。**
> 现有 App 里的下拉小程序面板只是前端原型；接入新服务前，需要按本文 §10、§12 改造，尤其是**停止把主站 refreshToken 注入 WebView**。

---

## 1. 为什么必须新建服务

当前 App 的小程序原型直接复用了主站：

- 应用列表来自主站 `GET /api/auth/workbench/apps`；
- 小程序 WebView 加载 `https://ssemarket.cn/<route>`；
- 为了让 WebView 免登录，把 App 的 `refreshToken` 注入到主站域名的 `localStorage`；
- 新帖提醒由 App 每 60 秒轮询主站 `/api/auth/browse`。

这套做法只适合做交互原型，不能作为正式的小程序平台，原因：

1. **安全边界**：把主站 refreshToken 交给 WebView，等于把 30 天的主站登录态交给任意一个被打开的小程序页面。只要某个小程序页面被 XSS 或第三方脚本污染，主站账号即失守。
2. **权限边界**：小程序应该只能访问自己被授权的接口，不能拿着主站 token 调用全部 `/api/auth/*`。
3. **故障隔离**：小程序列表、启动票据、推送、埋点这些流量不应该打到业务主服务；主服务发版时不应导致小程序入口不可用。
4. **数据归属**：最近使用、我的小程序、设备推送 token、订阅关系属于“小程序平台”数据，不应写进主站业务库。
5. **演进**：后续要接第三方小程序、审核/发布/灰度、按小程序限流、审计，这些都不适合塞进现有业务服务。

因此：**新服务独立部署、独立数据库、独立 Redis 前缀、独立 MinIO 桶、独立域名与凭证。**

---

## 2. 总体架构

```
┌──────────────────────────────┐
│  App（Android / HarmonyOS /  │
│  Windows / iOS）             │
│  ├─ 下拉小程序面板           │
│  ├─ 小程序容器（WebView）    │
│  └─ 通知 / 设备注册          │
└──────────────┬───────────────┘
               │ HTTPS + 用户 JWT
               ▼
┌──────────────────────────────┐        ┌──────────────────────┐
│  小程序平台服务（新）        │        │  推送渠道             │
│  mp-api.ssemarket.cn         │───────▶│  FCM / HMS Push Kit  │
│  - 应用目录 / 分类 / 搜索    │        │  APNs / WNS          │
│  - 启动票据 launch ticket    │        └──────────────────────┘
│  - 最近使用 / 我的小程序     │
│  - 设备 token / 订阅关系     │
│  - 新帖事件 fanout / 去重    │
│  - 审核 / 发布 / 审计        │
└───────┬──────────────┬───────┘
        │              │
        │ 独立 DB      │ 签名内部 API（可选）
        ▼              ▼
┌──────────────┐  ┌──────────────────────┐
│ MySQL/PG     │  │ 现有业务服务（旧）    │
│ Redis        │  │ SSE_market_server     │
│ MinIO 桶     │  │ 只作为业务数据源      │
└──────────────┘  └──────────────────────┘

小程序页面域名：mp-app.ssemarket.cn（与主站 ssemarket.cn 不同源）
```

### 2.1 两种集成模式（建议先做 A）

| | 模式 A：独立控制面 + 旧服务做业务数据源（推荐） | 模式 B：完全独立数据面 |
|---|---|---|
| 新服务负责 | 应用目录、票据、偏好、推送、审计 | 上述全部 + 帖子/用户/商城等业务 |
| 业务数据 | 通过签名内部 API 调旧服务 | 新库，迁移业务逻辑 |
| 工作量 | 中 | 大，需长期迁移 |
| 风险 | 旧服务需提供内部接口 | 双写/迁移/一致性风险 |
| 适用 | 现阶段 | 旧服务确定要下线时 |

**建议**：先按模式 A 落地。新服务不直接连旧库、不共享旧服务凭证；只通过 `X-Internal-Signature` 调旧服务少量内部接口（或由旧服务主动推送事件）。后续如果旧服务要退役，再把业务数据面迁进新服务。

---

## 3. 服务职责边界

新服务（下称 `mp-service`）只做小程序平台域：

1. **应用目录**：小程序注册、分类、图标、入口 URL、允许的 origin、可见范围、上下架。
2. **启动票据**：App 为“当前用户 + 目标小程序 + 设备”申请一次性 ticket，WebView 用 ticket 换取小程序会话。
3. **用户偏好**：最近使用、我的小程序、排序、置顶（跨端同步；本地缓存只是加速）。
4. **设备与推送**：设备注册、推送 token、通知开关、按平台分发。
5. **新帖事件**：接收旧服务的新帖事件，做订阅匹配、去重、fanout、静默时段。
6. **运营后台**：应用 CRUD、版本、审核、发布、分类、审计日志、灰度。
7. **可观测性**：请求日志、审计、指标、告警。

**不做**：帖子/评论/小说/商城等业务读写；这些仍由旧服务负责（模式 A）。

---

## 4. 技术选型建议

| 层 | 建议 | 理由 |
|---|---|---|
| 语言/框架 | Go + Gin（与现有团队栈一致） | 复用团队经验、部署方式一致 |
| 数据库 | MySQL 8（独立库 `ssemarket_mp`） | 与现有运维习惯一致；偏好/设备/订阅都是关系型 |
| 缓存/队列 | Redis（独立 ACL 用户 + `mp:` 前缀） | 票据、限流、事件去重、轻量队列 |
| 对象存储 | MinIO 独立桶 `ssemarket-mp` | 小程序图标、审核附件 |
| 部署 | YatTerra Pod，supervisor 前台进程 | 平台已有能力；对外 8080，内部端口按需声明 |
| 观测 | Prometheus `/metrics` + 结构化日志 | 便于定位推送/票据问题 |
| 文档 | OpenAPI 3.1 | 前后端契约 |

如果团队更熟 Node/TypeScript，也可以；但不要与旧服务共用进程和数据库账号。

---

## 5. 域名、源与 Cookie 隔离

| 用途 | 建议域名 | 说明 |
|---|---|---|
| 新服务 API | `mp-api.ssemarket.cn` | App 和 WebView 都调它 |
| 小程序页面宿主 | `mp-app.ssemarket.cn` | 与主站 `ssemarket.cn` **不同源** |
| 运营后台 | `mp-admin.ssemarket.cn` | 仅内网/VPN 或管理员 |

关键原则：

1. **不同源**：小程序页面不要跑在 `ssemarket.cn` 下，避免与主站共享 cookie/localStorage。
2. **WebView 不注入主站 token**：主站 refreshToken 永远不进入 WebView。
3. **HttpOnly + Secure + SameSite=Lax**：小程序会话 cookie 只作用于 `mp-app.ssemarket.cn`。
4. **CSP**：小程序页面响应头限制 `script-src`、`frame-ancestors`，只允许注册过的 origin。
5. **App 内 WebView 校验**：容器只允许加载 `apps.entry_url` 或其同源子路径；禁止任意 URL（防止钓鱼）。

> 如果暂时没有独立域名，也必须至少使用独立子域；不要复用主站域名 + 主站 token。

---

## 6. 认证与授权

### 6.1 用户身份

App 已经登录主站。调用 `mp-service` 时带主站 access token：

```
Authorization: Bearer <main_access_token>
```

`mp-service` 两种校验方式（二选一）：

- **推荐**：主站暴露 JWKS 或内网校验接口，`mp-service` 只验签，不查主站库；
- 或 `mp-service` 调旧服务 `POST /internal/v1/token/verify`（签名 + 内网），返回 `userID`。

`mp-service` **不保存主站密码、不保存主站 refreshToken**；只保存 `main_user_id` 的映射。

### 6.2 小程序会话（launch ticket）

不要让 WebView 直接拿主站 token。流程：

```
App                     mp-service                小程序页面(mp-app)
 │  POST /v1/launch-tickets                         │
 │  {appKey, deviceID}                              │
 │───────────────────────▶│                         │
 │                        │ 生成一次性 ticket(60s)   │
 │◀───────────────────────│ {ticket, launchURL}     │
 │ 打开 WebView launchURL?ticket=...                 │
 │─────────────────────────────────────────────────▶│
 │                        │◀─ POST /v1/sessions/exchange {ticket}
 │                        │   校验：未过期/未使用/绑定 app+device
 │                        │   签发 app-scoped session（HttpOnly cookie）
 │                        │────────────────────────▶│
 │                        │                         │ 之后只带 cookie 调 mp-api
```

要点：

- ticket：**一次性、60 秒、绑定 userID + appKey + deviceID + origin**；Redis 存储，使用后删除。
- ticket 只能换 session，不能直接当 API token。
- app-scoped session：权限仅限该 app 的 scopes，例如 `profile:read`、`posts:read`、`notifications:write`；默认 2 小时，滑动续期。
- 小程序页面调用 `mp-api` 时，`mp-service` 从 session 取 `appKey`，做 scope 校验。
- 第三方小程序使用 `appKey` + 后端签名（`X-App-Signature` + timestamp + nonce）调用服务端 API；**appSecret 只放服务端，不能出现在 WebView**。

### 6.3 权限模型

```
user (main_user_id)
  └─ app_grant (user_id, app_key, scopes, created_at)
       └─ session (ticket → session)
```

默认 scopes：`profile:read`、`prefs:read`、`prefs:write`、`notifications:read`、`notifications:write`。业务数据权限由旧服务的内部接口再校验。

---

## 7. API 设计（v1）

统一约定：

- Base URL：`https://mp-api.ssemarket.cn/v1`
- JSON；时间 ISO-8601 UTC；ID 用字符串或 int64（避免 JS 精度问题）。
- 错误：

```json
{"code":"INVALID_TICKET","message":"启动票据无效或已过期","requestId":"..."}
```

- 分页：`?limit=20&cursor=...`，返回 `{items, nextCursor}`。
- 幂等：写接口支持 `Idempotency-Key` 头。
- 限流：按 user + appKey + IP 三维度；Redis 令牌桶。

### 7.1 客户端 API（App 用，Bearer 主站 token）

#### `GET /v1/apps`

返回小程序目录（内置 + 动态 + 已上架）。

```json
{
  "items": [
    {
      "appKey": "novel",
      "name": "小说",
      "icon": "tabler:book-2",
      "category": "content",
      "entryURL": "https://mp-app.ssemarket.cn/novel",
      "badge": null,
      "visible": true,
      "sort": 10
    }
  ],
  "nextCursor": null
}
```

#### `GET /v1/apps/{appKey}`

单个小程序详情：入口、允许 origin、版本、是否可添加到“我的小程序”。

#### `GET /v1/categories`

分类列表（内容、工具、生活、官方……）。

#### `GET /v1/search?q=小说`

按名称/拼音/关键词搜索；返回 `items`。服务端做分词，App 不做本地全量搜索（避免目录变化后不一致）。

#### `POST /v1/launch-tickets`

```json
{"appKey":"novel","deviceID":"dev_xxx","origin":"https://mp-app.ssemarket.cn"}
```

响应：

```json
{"ticket":"lt_xxx","launchURL":"https://mp-app.ssemarket.cn/launch?ticket=lt_xxx","expiresIn":60}
```

#### `POST /v1/sessions/exchange`

小程序页面调用（不需要主站 token）：

```json
{"ticket":"lt_xxx"}
```

响应 `Set-Cookie: mp_session=...; HttpOnly; Secure; SameSite=Lax; Path=/`。

#### `GET /v1/me/prefs`

最近使用 + 我的小程序（跨端同步）：

```json
{
  "recent": [{"appKey":"novel","openedAt":"2026-11-14T08:00:00Z"}],
  "favorites": [{"appKey":"ranking","addedAt":"2026-11-13T10:00:00Z"}]
}
```

#### `PUT /v1/me/prefs`

整体或增量更新：

```json
{
  "recent": ["novel","ranking"],
  "favorites": ["coin","novel"]
}
```

服务端做去重、截断（recent 最多 20），并返回规范化结果。App 本地 SharedPreferences 作为离线缓存。

#### `POST /v1/devices`

注册/更新设备推送 token：

```json
{
  "deviceID": "dev_xxx",
  "platform": "android",          // android | ohos | windows | ios
  "appVersion": "0.6.7+18",
  "pushProvider": "fcm",          // fcm | hms | apns | wns | local
  "pushToken": "...",
  "notificationEnabled": true,
  "locale": "zh-CN"
}
```

> `pushToken` 是敏感数据：只存哈希/加密值，日志里打码。

#### `DELETE /v1/devices/{deviceID}`

登出/卸载时注销。

#### `PUT /v1/me/subscriptions`

```json
{"topics":[{"topic":"new_posts","enabled":true,"quietHours":{"from":"23:00","to":"07:00"}}]}
```

#### `POST /v1/me/prefs/import`（可选）

把 App 本地旧数据（recent/favorites）一次性导入，便于从原型迁移。

### 7.2 运营后台 API（管理员）

```
GET    /admin/v1/apps
POST   /admin/v1/apps
PATCH  /admin/v1/apps/{appKey}
POST   /admin/v1/apps/{appKey}/submit
POST   /admin/v1/apps/{appKey}/approve
POST   /admin/v1/apps/{appKey}/publish
POST   /admin/v1/apps/{appKey}/unpublish
GET    /admin/v1/audit-logs
```

应用字段：

```json
{
  "appKey": "novel",
  "name": "小说",
  "icon": "tabler:book-2",
  "entryURL": "https://mp-app.ssemarket.cn/novel",
  "allowedOrigins": ["https://mp-app.ssemarket.cn"],
  "scopes": ["profile:read","posts:read"],
  "visibility": "public",         // public | logged_in | allowlist
  "status": "draft",              // draft | reviewing | published | offline
  "version": "1.0.0",
  "ownerType": "official"         // official | partner
}
```

### 7.3 内部 API（旧服务 → 新服务）

签名：`X-Internal-Timestamp` + `X-Internal-Nonce` + `X-Internal-Signature = HMAC-SHA256(secret, timestamp + nonce + body)`；只在内网 Service 或 mTLS 上开放。

#### `POST /internal/v1/events/new-post`

旧服务在新帖发布成功后推送（建议用 outbox + 重试）：

```json
{
  "eventID": "evt_...",
  "postID": 7726,
  "title": "想分享一件很有爱的事情",
  "partition": "主页",
  "authorUserID": 561,
  "createdAt": "2026-11-14T08:00:00Z",
  "dedupKey": "post:7726"
}
```

新服务按 `eventID/dedupKey` 去重（Redis SETNX + TTL 7 天），再 fanout 给订阅用户。

#### `POST /internal/v1/token/verify`（如果不用 JWKS）

```json
{"token":"..."}
→ {"valid":true,"userID":561,"expiresAt":"..."}
```

### 7.4 健康与指标

```
GET /healthz
GET /readyz
GET /metrics        # Prometheus，仅内网
```

---

## 8. 数据模型（MySQL，独立库）

> 所有表带 `created_at/updated_at`；软删除用 `deleted_at`；字符集 `utf8mb4`。

### `mp_apps`

| 字段 | 类型 | 说明 |
|---|---|---|
| id | BIGINT PK | |
| app_key | VARCHAR(64) UNIQUE | 稳定标识，如 `novel` |
| name | VARCHAR(64) | 展示名 |
| icon | VARCHAR(64) | 图标名或 URL |
| entry_url | VARCHAR(512) | 入口地址 |
| allowed_origins | JSON | 允许的 origin 列表 |
| scopes | JSON | 授权范围 |
| category | VARCHAR(32) | 分类 |
| visibility | VARCHAR(16) | public/logged_in/allowlist |
| status | VARCHAR(16) | draft/reviewing/published/offline |
| owner_type | VARCHAR(16) | official/partner |
| sort | INT | 排序 |
| version | VARCHAR(32) | 当前版本 |
| created_by | BIGINT | 管理员 userID |
| UNIQUE KEY uk_app_key (app_key) | | |
| KEY idx_status_sort (status, sort) | | |

### `mp_app_versions`

`id, app_id, version, entry_url, allowed_origins, scopes, changelog, status, published_at`。用于回滚与灰度。

### `mp_user_prefs`

`id, user_id, app_key, is_favorite, opened_at, sort_order, UNIQUE(user_id, app_key)`。

### `mp_devices`

`id, user_id, device_id, platform, app_version, push_provider, push_token_hash, push_token_cipher, notification_enabled, last_seen_at, UNIQUE(user_id, device_id)`。

### `mp_subscriptions`

`id, user_id, topic, enabled, quiet_from, quiet_to, UNIQUE(user_id, topic)`。

### `mp_events`

`id, event_id UNIQUE, type, payload JSON, received_at, processed_at, status`。用于事件幂等与重放。

### `mp_notifications`

`id, user_id, event_id, title, body, platform, status, sent_at, error, dedup_key`。

### `mp_launch_tickets`（也可只放 Redis）

`ticket_hash, user_id, app_key, device_id, origin, expires_at, used_at`。建议 Redis 为主，DB 只做审计。

### `mp_audit_logs`

`id, actor_id, action, target_type, target_key, before JSON, after JSON, ip, created_at`。

### `mp_app_grants`（第三方授权）

`id, user_id, app_key, scopes, granted_at, revoked_at, UNIQUE(user_id, app_key)`。

---

## 9. 推送与新帖实时提醒

### 9.1 事件流

```
旧服务发帖成功
  └─ outbox 表 / 事务消息
       └─ POST /internal/v1/events/new-post（签名，重试）
            └─ mp-service 去重
                 ├─ 写 mp_events
                 ├─ 查订阅用户（可按分区/关键词过滤）
                 ├─ 写 mp_notifications（每个用户一条）
                 └─ fanout：
                      FCM（Android）/ HMS Push Kit（HarmonyOS）
                      APNs（iOS）/ WNS（Windows）
                      local（无推送能力时的兜底）
```

### 9.2 平台差异

| 平台 | 方案 | 备注 |
|---|---|---|
| Android | FCM（国内需 Google Play 服务）或厂商通道（小米/华为/OPPO/vivo） | 建议接一家聚合推送或至少 FCM + 华为 |
| HarmonyOS | HMS Push Kit | 需要 AGC 项目、签名证书、`agconnect-services.json`；无 AGC 时退回本地通知 + 前台轮询 |
| Windows | WNS 或本地通知 | WNS 需要 MSIX 包身份；未打包时用 `flutter_local_notifications` 本地通知 |
| iOS | APNs | 需要 Apple 开发者证书 |

### 9.3 兜底策略

- 推送失败/未授权：App 前台每 60 秒轮询 `GET /v1/events/new-posts?since=...`（由 `mp-service` 提供，不直连旧服务）。
- 静默时段：`quietHours` 内只写站内通知，不弹系统通知。
- 去重：同一 `eventID` 对同一用户只发一次。
- 限流：每用户每小时最多 N 条系统通知，超出合并为“有 N 条新帖”。

### 9.4 旧服务的改动（最小）

在发帖成功的事务提交后写 outbox，后台 worker 推送事件到 `mp-service`；失败重试 + 死信。不要直接在请求链路里同步调用新服务。

---

## 10. 小程序容器协议（前端契约）

### 10.1 启动

1. App 调 `POST /v1/launch-tickets`；
2. 容器加载 `launchURL`（带 ticket）；
3. 页面调 `POST /v1/sessions/exchange` 换 HttpOnly cookie；
4. 页面后续只调 `mp-api`，不接触主站 token。

### 10.2 容器能力（胶囊菜单）

| 菜单项 | 调用 |
|---|---|
| 添加到我的小程序 / 移除 | `PUT /v1/me/prefs` |
| 分享 | 容器回调 App（`postMessage`） |
| 反馈 | `POST /v1/feedback`（可并入新服务） |
| 刷新 / 在浏览器打开 / 复制链接 | 本地能力，不需要服务端 |

### 10.3 WebView → App 的桥

只允许白名单消息：

```json
{"type":"mp.event","event":"share","payload":{...}}
```

App 侧校验 `event.origin` 在 `allowedOrigins` 内；禁止任意 JS 调用原生能力。

### 10.4 禁止事项

- ❌ 注入主站 access/refresh token；
- ❌ 允许加载未注册的任意外链；
- ❌ 在小程序页面里直接调主站 `/api/auth/*`；
- ❌ 把 appSecret 放进前端。

---

## 11. 安全清单

- [ ] 独立数据库/Redis/MinIO 凭证，不与旧服务共用；
- [ ] ticket 一次性、短 TTL、绑定 user+app+device+origin；
- [ ] session cookie HttpOnly/Secure/SameSite；
- [ ] 每个 app 的 `allowedOrigins` 白名单 + CSP `frame-ancestors`；
- [ ] app-scoped scopes，默认最小权限；
- [ ] 内部 API 签名 + 时间窗（±5 分钟）+ nonce 防重放；
- [ ] 推送 token 加密存储，日志打码；
- [ ] 管理后台独立域名 + RBAC + 审计；
- [ ] 限流：登录态接口按 user/app/IP；内部事件按来源；
- [ ] SSRF：应用入口 URL 只允许 https + 白名单域名；
- [ ] 上传：图标/附件类型/大小校验，MinIO 私有桶 + 预签名 URL；
- [ ] 日志不打印 token/ticket/pushToken/密码。

---

## 12. 与现有 App 的改造清单

当前原型中需要改动的文件/点：

| 文件 | 现状 | 改为 |
|---|---|---|
| `lib/core/services/mini_program_catalog.dart` | 硬编码目录 + `/auth/workbench/apps` | 调 `GET /v1/apps`，本地只做缓存 |
| `lib/core/api/api_service.dart` | `getMiniProgramApps()` 走旧接口 | 新增 `MiniProgramApi`，指向 `mp-api.ssemarket.cn` |
| `lib/views/miniprogram/mini_program_drawer.dart` | 本地最近使用/我的小程序 | 读 `GET /v1/me/prefs`，写 `PUT /v1/me/prefs`；本地 SharedPreferences 仅缓存 |
| `lib/views/miniprogram/mini_program_page.dart` | 注入主站 refreshToken；直接加载 web 页面 | 用 launch ticket 换会话；加载 `launchURL`；删除 token 注入 |
| `lib/core/services/new_posts_service.dart` | 每 60s 轮询旧 `/auth/browse` | 推送为主；兜底调 `GET /v1/events/new-posts` |
| `lib/core/services/notification_service.dart` | 本地通知 | 增加 `POST /v1/devices` 注册、推送 token 上报 |
| `ohos/.../NotificationPlugin.ets` | 本地通知 | 保留本地能力；推送 token 由 HMS SDK 获取后上报 |
| `android/.../AndroidManifest.xml` | POST_NOTIFICATIONS | 保留；FCM 需要 google-services 配置 |

> 迁移期间可以保留旧代码作为 fallback，但一旦新服务上线，必须关闭“注入主站 refreshToken”这条路径。

---

## 13. 部署（YatTerra Pod 约定）

- 服务绑定 `0.0.0.0:8080`（对外），或按平台声明内部端口给旧服务调用；
- 代码/工作目录放 `/home/cloud/deploy/mp-service`（持久化）；
- 前台进程交给 supervisor，日志写 `$LOG_DIR`；
- 环境变量：

```bash
PORT=8080
MP_DB_DSN=...
MP_REDIS_ADDR=...
MP_REDIS_PREFIX=mp:
MP_MINIO_ENDPOINT=...
MP_MINIO_BUCKET=ssemarket-mp
MAIN_API_BASE=https://ssemarket.cn/api
MAIN_INTERNAL_SECRET=...        # 与旧服务共享的内部签名密钥（仅服务端）
JWT_JWKS_URL=https://ssemarket.cn/.well-known/jwks.json
MP_PUBLIC_BASE=https://mp-api.ssemarket.cn
```

- 发布：`go build` → 容器/二进制 → supervisor reload；数据库迁移用版本化 SQL（或 GORM AutoMigrate，但新服务建议显式迁移）；
- 监控：`/metrics`、错误率、票据失败率、推送成功率、事件积压；
- 备份：MySQL 每日全量 + binlog；MinIO 桶版本化。

---

## 14. 里程碑与验收

### M1（1 周）：目录 + 票据 + 容器打通

- [ ] `GET /v1/apps`、`/v1/search`、`/v1/launch-tickets`、`/v1/sessions/exchange`
- [ ] App 下拉面板从新服务拉目录
- [ ] WebView 不再注入主站 token，能正常打开内置小程序
- [ ] 验收：Android / HarmonyOS 真机各打开 3 个小程序，主站 token 不出现在 WebView

### M2（1 周）：偏好同步 + 设备注册

- [ ] `GET/PUT /v1/me/prefs`，最近使用/我的小程序跨端同步
- [ ] `POST/DELETE /v1/devices`，Android/HarmonyOS 上报 token
- [ ] 验收：两台设备登录同一账号，最近使用一致

### M3（1 周）：新帖推送

- [ ] 旧服务 outbox → `POST /internal/v1/events/new-post`
- [ ] `mp-service` 去重 + fanout + 静默时段
- [ ] Android FCM/HMS + HarmonyOS Push Kit（或本地兜底）
- [ ] 验收：发一条新帖，订阅用户 10 秒内收到通知；重复事件不重复弹

### M4（1 周）：运营后台 + 审计

- [ ] 应用 CRUD、审核、发布、下架
- [ ] 审计日志、限流、指标
- [ ] 验收：新增一个第三方小程序并灰度到 10% 用户

---

## 15. 需要你确认的问题

1. **集成模式**：先走模式 A（新服务调旧服务内部 API），还是直接做模式 B（完全独立数据面）？
2. **域名**：是否有 `mp-api.ssemarket.cn` / `mp-app.ssemarket.cn` 的 DNS 与证书？没有的话先用什么子域？
3. **推送渠道**：Android 用 FCM 还是厂商通道？HarmonyOS 是否已有 AGC 项目/签名证书？Windows 是否需要 WNS（是否有 MSIX 包身份）？
4. **第三方小程序**：第一期是否只做官方内置应用？如果要开放第三方，审核/责任边界怎么定？
5. **用户体系**：新服务是只验主站 JWT，还是需要独立的用户表/匿名用户？

---

## 16. 附录：最小 SQL DDL

```sql
CREATE DATABASE IF NOT EXISTS ssemarket_mp DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE mp_apps (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  app_key VARCHAR(64) NOT NULL,
  name VARCHAR(64) NOT NULL,
  icon VARCHAR(128) NOT NULL DEFAULT '',
  entry_url VARCHAR(512) NOT NULL,
  allowed_origins JSON NOT NULL,
  scopes JSON NOT NULL,
  category VARCHAR(32) NOT NULL DEFAULT 'content',
  visibility VARCHAR(16) NOT NULL DEFAULT 'logged_in',
  status VARCHAR(16) NOT NULL DEFAULT 'draft',
  owner_type VARCHAR(16) NOT NULL DEFAULT 'official',
  sort INT NOT NULL DEFAULT 0,
  version VARCHAR(32) NOT NULL DEFAULT '1.0.0',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_app_key (app_key),
  KEY idx_status_sort (status, sort)
) ENGINE=InnoDB;

CREATE TABLE mp_user_prefs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  app_key VARCHAR(64) NOT NULL,
  is_favorite TINYINT(1) NOT NULL DEFAULT 0,
  opened_at DATETIME(3) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_app (user_id, app_key),
  KEY idx_user_fav (user_id, is_favorite, updated_at)
) ENGINE=InnoDB;

CREATE TABLE mp_devices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  device_id VARCHAR(128) NOT NULL,
  platform VARCHAR(16) NOT NULL,
  app_version VARCHAR(32) NOT NULL DEFAULT '',
  push_provider VARCHAR(16) NOT NULL DEFAULT 'local',
  push_token_hash CHAR(64) NOT NULL DEFAULT '',
  push_token_cipher VARBINARY(1024) NULL,
  notification_enabled TINYINT(1) NOT NULL DEFAULT 1,
  last_seen_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_device (user_id, device_id),
  KEY idx_platform (platform)
) ENGINE=InnoDB;
```

---

## 17. 参考

- 微信小程序运行机制（胶囊按钮 / 后台态）：https://developers.weixin.qq.com/miniprogram/dev/framework/runtime/operating-mechanism.html
- 微信小程序转发/分享：https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/share.html
- 微信 7.0.7 胶囊菜单改版：https://www.ifanr.com/minapp/1260958
- 小程序「最近使用」变两行：https://www.ifanr.com/minapp/1266213
- 长按圆点唤起多任务：https://cloud.tencent.com/developer/article/1020673
- `getMenuButtonBoundingClientRect`：https://uniapp.dcloud.net.cn/api/ui/menuButton
- 下拉小程序列表说明：https://www.sxl.cn/content/blog/xialaxcx/