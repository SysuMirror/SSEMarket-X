# 小程序平台接入状态

> 更新：2026-11-15（平台已修复主站 token 校验，目录/票据实测通过）

## 1. 当前实测结果

主站 access token 直接调平台接口已经正常：

| 请求 | 结果 |
|---|---|
| `GET /v1/apps?limit=50` | `200`，返回 6 个小程序：novel / ranking / resume / media / shop / course |
| `GET /v1/me/prefs` | `200`，recent/favorites 正常 |
| `POST /v1/launch-tickets` | `201`，返回 `launchURL`（60 秒一次性 ticket） |
| `POST /v1/sessions/exchange` | `200`，下发 `mp_session` HttpOnly Cookie |
| 重复 exchange 同一 ticket | `401 TICKET_USED`（符合预期） |

平台文档：`https://applet.ssemarket.cn/app-docs/unissso-integration.md` §7
（平台改为用 `MP_MAIN_VERIFY_URL=https://ssemarket.cn/api/auth/info` 校验主站 token，不再共享 JWT 密钥）。

## 2. App 侧已实现

- 目录/搜索/偏好：`/v1/apps`、`/v1/search`、`/v1/me/prefs`
- 启动票据、容器、origin 白名单、无 token 注入
- 设备注册 + new_posts 订阅（`/v1/devices`、`/v1/me/subscriptions`）
- 小程序全局常驻（收起后音频继续）、主站停止入口、Android 前台保活服务
- 帖子 `::music id::` 占位卡片：直接试听 / 进入音乐视频小程序
- 主站/小程序拆分：小说、排行榜、简历、音乐视频、商城、课程走小程序；小秋留在主站

## 3. 仍需平台/页面侧完成

1. **当前 6 个小程序的 `entryURL` 都是演示页**：
   `https://applet.ssemarket.cn/demo/app?app=<appKey>`
   真实的小程序页面（小说/排行榜/简历/音乐视频等）部署到 `mp-app.ssemarket.cn` 后，
   需要更新 `entryURL` / `allowedOrigins`（管理后台或 `PATCH /admin/v1/apps/<appKey>`）。
2. **音频后台保活的系统级隔离**：当前 WebView 在 Flutter 主进程内，Android 用前台服务
   `MiniProgramKeepAliveService` 保活；如果要求系统进程列表里出现独立进程，需要把
   小程序容器改成独立进程的原生 Activity/Service（后续项）。

## 4. 复现/验证命令

```bash
# 1. 主站登录拿 access token
# 2. 目录
curl -s -H "Authorization: Bearer $TOKEN" \
  'https://applet.ssemarket.cn/v1/apps?limit=50' | jq .
# 3. 票据
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"appKey":"novel","deviceID":"dev_test","origin":"https://applet.ssemarket.cn"}' \
  https://applet.ssemarket.cn/v1/launch-tickets | jq .
# 4. 票据换会话
curl -s -i -X POST -H 'Content-Type: application/json' \
  -d '{"ticket":"<上一步 ticket>"}' \
  https://applet.ssemarket.cn/v1/sessions/exchange
```