# 智能小秋(原始標題:「智能小秋」)

- 路由:`/smart-xiaoqiu`(name: SmartXiaoQiu,meta.layoutFill)
- 來源:JS bundle 分析(SmartXiaoQiuView-BZJ8RVGu.js,23KB)

## 用途
AI 助手對話頁(SSE 串流):檢索論壇、整理要點、可直接產出「發帖/上架商品」草稿卡一鍵發布。

## UI 結構
- 頂欄:品牌「智能小秋」+ 頭像 `/new/xiaoqiu-avatar.png`;狀態列三態:「正在思考与整理回复…」(live)/「论坛助手 · 检索帖子 · 整理要点」/「正在连接…」;「新对话」鈕。
- 時間軸:訊息泡泡(assistant 名「小秋」+「回复中」badge;user);**中間步驟卡**(badge「处理中/中间步骤」,placeholder「正在整理信息…」);thinking 三點動畫「小秋在想一下…」;錯誤橫幅。
- **發帖草稿卡**(AI 產出 post_draft 事件):類型「普通帖子/商城商品」、標題(30 字)、正文(10000 字)、价格（元）(min 0.01)、匿名发布、分区、标签(逗號分隔)、仅自己可见、图片(「+」上傳 /「×」移除);狀態徽章「发帖草稿/提交中…/已发布/失败」;按鈕「取消」「确认发帖」;成功區「已发布成功！查看帖子 →」。
- 輸入列:placeholder「问我任何与论坛相关的问题…」;提示「Enter 发送 · 帖子链接将在新标签页打开，不会中断当前对话」;按鈕「停止生成」(abort)/「发送」。
- 歡迎語(無歷史時播種):「你好，我是小秋，可以帮你检索论坛帖子、整理要点或回答与社区相关的问题。欢迎来找我聊天~」

## API 呼叫(全部直連 `location.origin + /api/v1/agent/*`,自帶 fetch,非共用 wrapper)
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/v1/agent/conversation/bootstrap | GET | Bearer JWT | 掛載 / 會話失效 | ❌實測 502(服務當前異常) | `code===0` 成功;**HTTP 503 或 code 50301 → 「会话服务未就绪（需配置 Redis）」**;回 `data{session_id, segment_seq, archived, messages[]}` |
| /api/v1/agent/task/sse | POST | `{session_id, task}`,header `Accept: text/event-stream` | 發送 | — | **SSE 串流**(ReadableStream 解析,`\n\n` 切事件);AbortController 支援「停止生成」 |
| /api/v1/agent/conversation/close | POST | `{session_id}` | 「新对话」 | — | `code===0` 成功 |
| /api/auth/uploadPhotos | POST | FormData(file) | 草稿卡加圖 | — | → fileURL |
| /api/auth/post | POST | `{content, partition, photos:"|"連接, tagList:"|"連接, title, userTelephone, isPrivate}` | 草稿卡發帖 | — | 回 `data.postID ?? postID` → `/postdetail/{id}` |
| /api/auth/postProduct | POST | `{UserID, Price, Title, Content, Photos[], ISAnonymous, syncFeedPost:true}` | 草稿卡上架 | — | → `/shop/productdetail/{id}` |

### SSE 事件格式(task/sse)
- `ping`:忽略。
- `content`(**`payload.schema_version===2`** 才處理):`{mode:"final"/"append"/"replace"/"other", text, round?}`;
  - `mode==="final"` → 收合步驟卡、定稿 assistant 泡泡;
  - text 以「【…】」開頭 + replace + 無 round → 步驟卡(label=首個【…】,無則「【专家进展】」);
  - 有 round 或 append → 寫入泡泡(append 累加/否則覆蓋)。
- `error`:`payload.message` → 全域錯誤列。
- `post_draft`:`{type:"product"/"post", title, content, partition, tags[], price, is_anonymous, is_private}` → 插入草稿卡。
- `rag_context` / `search_context`:前端不渲染(僅佔位事件名)。
- 串流結束但泡泡空 → 「当前没有生成有效回复，请稍后重试。」

### 錯誤碼語義
- `50301` / HTTP 503:Redis 未配置。
- `40301` 或(`40001` + msg 含 session/会话/bootstrap)→ 自動重新 bootstrap,toast「会话已失效，已重新同步，请再次发送。」(再失敗:「会话同步失败，请刷新页面后重试。」)。
- 其他:「发送失败，请检查网络后重试。」/「服务暂时不可用，请稍后重试。若多次失败，可检查网络或稍后再打开本页。」

## 訊息渲染
`post://123` → markdown 連結 `[帖子 #123](/postdetail/123)` 開新分頁;MarkdownContainer(variant chat)渲染。

## 分頁
無(歷史靠 bootstrap 一次回)。

## 導向
草稿卡成功 → `/postdetail/{id}` 或 `/shop/productdetail/{id}`。

## 需登入?
是(每次呼叫前 ensureLogin;未登入「请先登录后再使用智能小秋」)。

## 未確認事項
- bootstrap 回應 `messages[]` 上限(歷史筆數截斷規則)。
- `segment_seq` 用途(續傳序號?前端僅保存未使用於請求)。
- agent 後端實測當下 502,事件格式為程式碼推導、未線上驗證。
