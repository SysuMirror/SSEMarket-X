# 小秋原生对话页（App）

> 目标：App 内的「小秋」不搬网页版，直接用 OpsAgent 后端做成原生聊天页，交互对齐豆包 App。

## 1. 小秋前端现有能力盘点

| 能力 | 前端实现 | App 原生状态 |
|---|---|---|
| 流式对话 | `POST /api/v1/agent/task/sse`（SSE） | ✅ 已接 |
| 欢迎语 + 热帖建议 | `GET /api/v1/agent/suggestions` | ✅ 已接 |
| 历史会话 | `GET /api/v1/agent/conversations` | ✅ 已接 |
| 恢复最近会话 | `GET /api/v1/agent/conversation/bootstrap` | ✅ 已接 |
| 新建会话 | `POST /api/v1/agent/conversation/bootstrap` | ✅ 已接 |
| 停止生成 | 中断 SSE | ✅ 已接 |
| 赞/踩反馈 | `POST /api/v1/agent/feedback` | ✅ 已接 |
| 工具/专家中间步骤 | SSE `status` / `content` schema v2 | ✅ 已接（可折叠） |
| Markdown / 帖子链接 | `MarkdownContainer` | ✅ 用 `LatexMarkdown` |
| 复制 / 重新生成 | 前端 | ✅ 已接 |
| 发帖草稿卡片 | SSE `post_draft` + `PostDraftCard` | ⏳ 未接 |
| 记忆抽屉 | `/api/v1/agent/memory` | ⏳ 未接 |
| 封禁提示 | `/api/v1/agent/me/ban` | ⏳ 未接 |
| 猜拳小游戏 | `/api/v1/agent/game/rps` | ⏳ 未接 |
| 语音输入 / 附件 | 前端能力 | ⏳ UI 占位，待接 |

## 2. 原生页面结构（对齐豆包）

- 顶部：返回、小秋头像/名称、「集市 AI 助手」副标题、历史按钮、新对话按钮；
- 空态：居中头像 +「你好，我是小秋」+ 热帖建议胶囊；
- 用户消息：右侧蓝色气泡；
- AI 消息：左侧头像 + 正文（Markdown），消息下方复制/赞/踩/重新生成；
- 工具步骤：可折叠的中间步骤卡片；
- 输入栏：附件、输入框、语音、发送/停止圆钮；
- 流式时显示打字点/光标，自动贴底滚动。

## 3. 后端接口

- Base：`https://ssemarket.cn`
- 认证：`Authorization: Bearer <主站 access token>`
- SSE：`POST /api/v1/agent/task/sse`，body `{session_id, task}`，`Accept: text/event-stream`
- 事件：`content`（schema_version 2，`mode=final/append/replace`）、`status`、`error`、`post_draft`

## 4. 文件

- `lib/views/xiaoqiu/xiao_qiu_chat_page.dart`
- `lib/core/services/xiao_qiu_service.dart`

## 5. 未完成项

发帖草稿卡片、记忆抽屉、封禁提示、猜拳小游戏、语音/附件输入。核心对话体验已完成。