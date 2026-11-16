# 小程序真实页面部署包（mp-app.ssemarket.cn）

> 日期：2026-11-15  
> 目标：把主站现有功能页面（小说/排行榜/简历/音乐视频/商城/课程）作为小程序页面部署到
> `mp-app.ssemarket.cn`，然后在平台后台把 6 个 app 的 `entryURL` 从演示页换掉。

## 1. 已生成的部署包

| 产物 | 路径 |
|---|---|
| 静态站点目录 | `/home/cloud/sdk/mp-app-deploy/` |
| 压缩包 | `/home/cloud/sdk/mp-app-deploy.zip`（9.1MB） |
| nginx 配置 | `/home/cloud/sdk/nginx-mp-app.conf` |
| 源码改动 | `newSSE` 新增 `src/views/MediaHubView.vue` + 路由 `/media` |

构建环境（已写入产物）：

```bash
VITE_API_BASE_URL=https://ssemarket.cn/api
VITE_OPSAGENT_BASE_URL=https://ssemarket.cn
VITE_ASSIST_BASE_URL=https://ssemarket.cn/api/v1/assist
VITE_WS_BASE=https://ssemarket.cn
```

产物里的 API/WebSocket 都是绝对地址，所以页面可以放在与主站不同源的
`mp-app.ssemarket.cn`，不会请求到 mp-app 自己的 `/api`。

## 2. 部署步骤

### 2.1 上传静态文件

把 `mp-app-deploy.zip` 解压到 `mp-app.ssemarket.cn` 的站点根目录（例如 `/var/www/mp-app`）。

### 2.2 nginx（SPA 回退）

```nginx
root /var/www/mp-app;
location / { try_files $uri $uri/ /index.html; }
location /assets/ { expires 1y; add_header Cache-Control "public, immutable"; }
```

完整示例见 `/home/cloud/sdk/nginx-mp-app.conf`。证书需要 `mp-app.ssemarket.cn` 的
HTTPS 证书（当前域名解析到 175.178.90.215，但 HTTPS 端口没有服务，`curl` 返回 000）。

### 2.3 主站后端 CORS

小程序页面与主站不同源，浏览器的预检要求放行 `PATCH/PUT/DELETE`。
已修改主站代码：

`SSE_market_server/middleware/CORSMiddleware.go`

```go
Allow-Methods: GET, POST, PATCH, PUT, DELETE, OPTIONS
Allow-Headers: Authorization, Content-Type
```

**这个改动需要重新部署主站后端**，否则通知已读（PATCH）、删除等操作会跨域失败。
GET/POST 功能不受影响。

### 2.4 更新平台 app 配置

在平台后台或 `PATCH /admin/v1/apps/<appKey>` 把 6 个应用改成：

| appKey | entryURL | allowedOrigins |
|---|---|---|
| novel | `https://mp-app.ssemarket.cn/novel` | `["https://mp-app.ssemarket.cn"]` |
| ranking | `https://mp-app.ssemarket.cn/ranking` | 同上 |
| resume | `https://mp-app.ssemarket.cn/resume` | 同上 |
| media | `https://mp-app.ssemarket.cn/media` | 同上 |
| shop | `https://mp-app.ssemarket.cn/shop` | 同上 |
| course | `https://mp-app.ssemarket.cn/course` | 同上 |

`/media` 是新增的入口页，里面两个卡片分别进入 `/music` 和 `/video`（音乐+视频同一个小程序）。

## 3. 登录方式（当前实现）

- 页面是主站 Vue 前端的独立部署，登录页仍然是邮箱/密码；
- token 只存在 `mp-app.ssemarket.cn` 自己的 localStorage，**不是 App 注入的**；
- 主站 CORS 允许跨源，因此页面可以直接调 `https://ssemarket.cn/api`；
- 同一个 mp-app 源下的 6 个小程序共享一次登录。

这是最快能真实跑通的方案。后续如果要做「进小程序免登录」，需要二选一：

1. 主站新增一个用小程序会话换主站短期 token 的接口（需要主站 + mp-service 双方改动）；或
2. mp-app 接入 UniSSO 授权码 + PKCE，页面拿 SSO token 再走主站 SSO 换 token（需要给 mp-app 登记 SSO 回调地址）。

## 4. 当前阻塞清单

1. `mp-app.ssemarket.cn` 没有 HTTPS 站点/部署权限：需要上传目录 + 证书 + nginx。
2. 主站后端 CORS 改动需要重新发布。
3. 小程序平台 app 的 `entryURL/allowedOrigins` 需要管理员更新（我们没有平台管理员凭证）。
4. 真·独立进程（系统进程列表多一个进程）需要把 WebView 容器改成独立进程原生 Activity/Service，属于后续项。

## 5. 验收

部署后：

```bash
curl -I https://mp-app.ssemarket.cn/novel      # 200 text/html
curl -I https://mp-app.ssemarket.cn/assets/... # 200
```

App 内打开「小说」小程序：

1. 平台签发 ticket → `mp-app.ssemarket.cn/novel?ticket=...`；
2. 页面首次要求登录（邮箱/密码）；
3. 登录后正常浏览小说；
4. 打开「音乐视频」→ 播放音乐 → 收起小程序去刷帖子 → 音乐继续；
5. 主站浮动条「停止」可暂停小程序音频。
---

## 6. 实际部署记录（2026-11-15，已可正常使用）

平台侧已加好反向代理：

```nginx
location ^~ /mp-api/websocket/ { proxy_pass http://backend/websocket/; }
location ^~ /mp-api/            { proxy_pass http://backend/api/; }
```

App 侧已按每个 appKey 重新构建并部署（`VITE_BASE=/mp/<appKey>/`）：

```bash
VITE_API_BASE_URL=/mp-api
VITE_WS_BASE=/mp-api
VITE_ASSIST_BASE_URL=/mp-api/v1/assist
VITE_DIGEST_PREF_BASE_URL=/mp-api/v1/digest-pref
VITE_RAG_PROXY_BASE=/mp-api/rag-local
VITE_ASSIST_ENABLED=true
VITE_DIGEST_PREF_ENABLED=true
```

| appKey | 当前入口 | 实测 |
|---|---|---|
| novel | `https://applet.ssemarket.cn/mp/novel/?source=...` | 登录后小说列表/发现正常 |
| ranking | `https://applet.ssemarket.cn/mp/ranking/?source=...` | 排行榜正常 |
| resume | `https://applet.ssemarket.cn/mp/resume/?source=...` | 已部署 |
| media | `https://applet.ssemarket.cn/mp/media/?source=...` | 音乐列表/封面正常 |
| shop | `https://applet.ssemarket.cn/mp/shop/?source=...` | 已部署 |
| course | `https://applet.ssemarket.cn/mp/course/?source=...` | 已部署 |

- 页面内 API 请求全部走同源 `/mp-api/...`，无 CORS、无 CSP `connect-src` 问题；
- 登录 token 存在 `applet.ssemarket.cn` 的 localStorage，6 个内部小程序共享一次登录；
- 实测 `GET /mp-api/sso/mode`、`POST /mp-api/auth/login`、`GET /mp-api/music/file/*`、WebSocket 均到达主站。

## 7. 静默 SSO（已接通并实测）

接口已存在：`POST /api/auth/sso/try`（不是 `/api/sso/try`）。
通过 `/mp-api` 反代后实际调用：

```http
POST https://applet.ssemarket.cn/mp-api/auth/sso/try
Cookie: unisso_sid=...   # .ssemarket.cn 共享 Cookie，同源自动携带
→ 200 {token, refresh_token}
```

前端已加：

- `src/api/sso/sso.ts` 的 `ssoTry()`（`credentials: 'include'`）；
- `App.vue` 启动时，仅在 `/mp/<appKey>/` 页面、且本地无 token/refreshToken 时调用一次；
- 成功后 `setToken` / `setRefreshToken`、`getInfo`、跳到对应首页；
- 失败（无 SSO 会话）静默回退到邮箱/密码登录。

### 实测（Playwright，真实账号）

1. 走主站 SSO 共享登录，浏览器获得 `.ssemarket.cn` 的 `unisso_sid`；
2. 打开 `https://applet.ssemarket.cn/mp/novel/?source=...`；
3. 页面请求 `/mp-api/auth/sso/try` → **200**；
4. 自动进入 `/mp/novel/novel`，小说列表/书架/阅读进度正常，无需再输密码。

6 个 appKey 都已按此逻辑重新构建并部署。

> 注意：`/auth/sso/try` 有 10 次/分钟/IP 限流；前端只在启动且无登录态时调用一次，不会反复打。

## 8. App 登录态直通（当前主路径，已实测）

App 已登录时不再依赖 SSO Cookie：打开内置小程序时，Flutter 侧把主站 access token 注入 WebView。

- App：`MiniProgramRuntime._injectMainToken()` 仅在 **`https://applet.ssemarket.cn/mp/`** 页面注入
  `window.__SSE_MAIN_TOKEN__`（只注入短时效 access token，不注入 refresh token、不写 localStorage）；
- Web：`src/store/userStore.ts` 启动时读取该值，`isLogin` 在用户信息拉取前先放行；
- `App.vue` 在 `/mp/<appKey>/` 下最多等 1.2s 接收注入，然后用该 token 调 `getInfo`；
  若注入 token 失效，再回退 SSO Cookie；两者都没有才显示登录页。

实测（Playwright 预注入真实主站 token）：`/mp-api/auth/info`、`getInfo`、`novel/list` 等全部 200，
页面直接进入，无登录页、无浏览器跳转。

## 9. 图标与 WebSocket（CSP 约束）

- 平台 CSP 为 `connect-src 'self' ...`，`@iconify/vue` 默认访问 `api.iconify.design` 会被拦成空白图标。
  仓库已生成 `src/iconify/offline-icons.json`（129 个静态引用图标）并在 `main.ts` 注册；
  新增图标后运行 `node scripts/build-offline-icons.mjs` 重新生成。
- 聊天 WebSocket 必须走反代：构建时加 `VITE_WS_BASE=/mp-api`，
  实际地址为 `wss://applet.ssemarket.cn/mp-api/websocket/auth/chat`。

## 10. 构建与部署命令

```bash
export PATH=/home/cloud/tools/node-v22.20.0-linux-x64/bin:$PATH
for key in novel ranking resume media shop course; do
  VITE_BASE=/mp/$key/ VITE_API_BASE_URL=/mp-api VITE_WS_BASE=/mp-api pnpm build
  cp -a dist /home/cloud/sdk/mp-dists.build/$key
  MP_COOKIE="$(cat /home/cloud/.mp-cookie)" \
    node /home/cloud/mp.mjs deploy internal $key --dir /home/cloud/sdk/mp-dists.build/$key
done
```

## 11. 小程序内置登录（2026-11-15）

六个官方小程序共用 `src/views/MiniProgramLoginView.vue`：

- 路由：`/mp/<appKey>/mp-login?redirect=/原页面`；
- 已有 `.ssemarket.cn` 统一身份会话时，`App.vue` 的静默 SSO 会直接登录，不显示卡片；
- 没有会话时显示内置授权卡片，提交统一身份邮箱/密码到
  `POST https://applet.ssemarket.cn/auth/sso/m2m`，平台按 UniSSO 响应写入共享 Cookie，
  再用 `/mp-api/auth/sso/try` 换取集市 token；
- 不跳转主站登录页，也不再使用 `/auth/sso/start` 重定向；
- 六个小程序登录一次后共享登录态。

平台侧 `safeNext` 已允许 `/mp/` 路径，SSO 失败会回到小程序登录卡片而不是主站登录页。

## 12. 音乐小程序 AI 配音（Voice Studio）

媒体小程序新增「AI 配音」页（`MusicView.vue` 的 `tts` 模式），能力来自 Voice Studio：

- 前端调用同源 `/v1/tts/*`，由 `mp-service` 代理到 `https://tts.ssemarket.cn/api/v1/*`；
- API Key 只存在 mp-service 的 `.env`（`MP_TTS_API_KEY`），不进前端、不进 git；
- 支持音色列表/试听、文本（≤5000 字）、语速、同步合成、202 异步任务轮询、试听/下载 WAV、最近生成；
- 平台代理有每 IP 限流（合成 12 次/分钟，查询 60 次/分钟）。
