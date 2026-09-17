# 设置(原始標題:各區塊「账号资料」「安全」「SSO 账号绑定」「通用」「开发者」)

- 路由:`/options`(name: Options;Mobile 底欄「我的」入口)
- 來源:JS bundle 分析(OptionsView-DPVbWHBh.js,36KB;含內嵌 PAT/MCP 使用文件)

## 用途
個人設定中心:頭像/暱稱/簡介、改密碼、SSO 綁定、顯示偏好、開發者 PAT 管理。

## UI 結構(設置分區,折疊面板)
- **账号资料**:頭像(「点击更换头像」→ 檔案選擇 → uploadAvatar)、label「用户名」「个人简介」。
- **安全**:label「登录密码」「新密码」「确认新密码」「邮箱验证码」(placeholder「发送到绑定邮箱」)+「发送验证码」鈕;label「修改密码」。
- **SSO 账号绑定**:label「UniSSO 绑定」(hint「已绑定/未绑定」);已綁定顯示「绑定于 {時間}」+「登录密码」輸入以解綁;未綁定:「绑定后可使用 UniSSO 账号直接登录集市。点击下方按钮将跳转至 UniSSO 完成授权。」
- **通用**:title「电脑端样式新体验」(PWA 開關,localStorage `pwaExperienceEnabled`)、title「禁用邮箱推送」(changeEmailPush)、title「在个人主页隐藏发帖」(hideProfilePosts)。
- **开发者**(title「开发者」):「个人访问令牌（PAT）」面板:
  - 副標「用于 MCP 等对外调用。明文 token 仅在创建时显示一次，请立即复制保存。」
  - 建立:名稱 input(placeholder「如 Claude Desktop」,maxlength 64)+「权限范围（多选）」scope chips(name+description)+「创建 token」。
  - 列表「已有 token（N）」:名稱、`{prefix}…`、badge「活跃/已吊销」、scopes、「创建：{時間}」「最近使用：{時間}」(從未用 =「从未使用」)、按鈕「吊销」(confirm「确定吊销…不可恢复」)/「删除记录」。
  - 建立成功 modal:「token「{name}」已创建」+ 明文 + 「复制」+「我已保存」;失敗 toast「复制失败，请手动选择文本复制」。
  - 說明 modal「PAT 调用说明」(完整文件見下)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/uploadAvatar | POST | FormData(`file`) | 更換頭像 | — | 原生 fetch + Bearer |
| /api/auth/updateUserInfo | POST | `{avatarURL, intro, name, userID, hideProfilePosts}` | 保存資料 | — | |
| /api/auth/validateEmail | POST | `{email, mode}` | 發送驗證碼(改密碼流程) | — | |
| /api/auth/modifyPassword | POST | `{email, password(AES), password2(AES), valiCode}` | 修改密碼 | — | |
| /api/auth/changeEmailPush | POST | `{user_id}` | 禁用/啟用郵件推送 | — | 欄位 snake_case |
| /api/sso/status | GET | — | 載入 SSO 狀態 | — | |
| /api/sso/bind/start | POST | `{}` | 綁定 SSO | — | 回 `data.authorize_url` → location.href 跳轉 |
| /api/sso/unbind | POST | `{password(AES)}` | 解綁(confirm) | — | |
| /api/auth/token/scopes | GET | — | PAT 面板載入 | — | 回 `data.scopes[{name,description}]` |
| /api/auth/token/create | POST | `{name, scopes:[…]}` | 建立 token | — | 回 `data.token`(明文僅一次);伺服器只存 SHA-256 雜湊(文件自述) |
| /api/auth/token/list | GET | `?page=1&page_size=50` | 列表 | — | 回 `data.records[{token_id,name,prefix,is_active,scopes(逗號字串),created_at,last_used_at}]` |
| /api/auth/token/revoke | POST | `{token_id}` | 吊銷 | — | |
| /api/auth/token/delete | POST | `{token_id}` | 刪除紀錄 | — | |

## 分頁
token/list:`page`(1 起算)+ `page_size`(50)——全站唯一頁碼制分頁。

## 導向
SSO 綁定 → 外跳 authorize_url;無內部路由跳轉。

## 需登入?
是。

## 內嵌文件:PAT / MCP 完整說明(OptionsView 內 HTML 原文重點)
- **MCP 接入**:`POST https://ssemarket.cn/api/v1/agent/mcp`,header `Authorization: Bearer <PAT>`;協議 **MCP 2025-06-18 Streamable HTTP 單點模式**,支援 `initialize` / `tools/list` / `tools/call` / `ping`(JSON-RPC 2.0)。
- **工具**:
  | 工具 | scope | 參數 |
  |---|---|---|
  | `agent.chat` | agent:chat | `query`(1–8192 字);無會話記憶 |
  | `forum.post_search` | forum:read | `keyword`(≥1)、`limit`(1–50,預設 50) |
  | `forum.comment_search` | forum:read | `keyword`、`limit` |
  | `forum.latest_posts` | forum:read | `limit`(1–50,預設 50) |
  | `forum.post_create` | forum:write | `title`(1–30)、`content`(1–10000)、`partition`(如「二手交易」「校园生活」,**不能为「课程交流」**)、`tags: string[]`、`photos`(圖片 URL 的 JSON 陣列字串)、`is_private` |
- **curl 範例**(文件原文):`initialize` → `{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"my-script","version":"1.0"}}}`;`tools/call` → `{"method":"tools/call","params":{"name":"forum.post_create","arguments":{…}}}`。
- Claude Desktop 設定:`{"mcpServers":{"sse-smart-qiu":{"url":"https://ssemarket.cn/api/v1/agent/mcp","headers":{"Authorization":"Bearer sk_xq_…"}}}}`。

## 未確認事項
- PAT scope 完整清單(s scopes 端點動態回傳;文件僅列 agent:chat / forum:read / forum:write)。
- token prefix 格式規則(顯示 `sk_xq_` 開頭;前綴長度規則未確認)。
