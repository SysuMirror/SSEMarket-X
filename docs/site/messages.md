# 消息中心(原始標題:「消息」/「互动通知」)

- 路由:`/messages`(name: Messages,meta.layoutFill);`/notice` → redirect `/messages?tab=notice`;`/chat` → redirect `/messages?tab=chat`;query 亦可帶 `user=<userID>`、`anonymous=1`
- 來源:JS bundle 分析(MessagesView-BgX7eSVX.js、noticeStore-DYTmEZcC.js)

## 用途
雙面板:互動通知(分類+已讀管理)與私信(會話列表+即時對話,WebSocket)。

## UI 結構
- Tabs「互动通知」(badge 未讀)/「私信」(badge 未讀);副標「互动通知与私信」。
- **通知面板**:
  - 分類 tablist(aria「通知分类」):「未读/已读」+ 訊息類型「全部/评论了你的帖子/回复了你的评论/码住的帖子有新回复/帖子通知/抽奖中奖/评分区评论/处罚通知/反馈回复/举报处理」(前端過濾)。
  - 工具列:「一键已读」;空狀態「暂无未读」「全部已读」/「暂无未读通知」「暂无已读记录」。
  - 通知項:「标为已读」鈕;內容依類型渲染;「原帖已删除」/「查看原帖」;footer:「加载中…」「继续下滑加载更多」「暂无更多」。
- **私信面板**:
  - 會話列表(「暂无会话」空狀態;「在会话列表中选择联系人开始对话」);每項:頭像/名稱(匿名顯示「匿名用户」或「{name}·匿名」)、最後訊息摘要、未讀數、時間。
  - 對話區:「返回会话列表」(窄屏);訊息泡泡;「撤回」(24h 內本人);輸入框 placeholder「发消息…」+「发送」。
  - 匿名:切換鈕「开启/关闭本条匿名发送」;橫幅「匿名通道 · 你的消息将隐藏身份」/「匿名通道 · 对方身份已隐藏」;商品頁帶入 `?user=&anonymous=1` 時自動「发起匿名会话」。
  - 空狀態「还没有消息，发条私信打个招呼吧」;錯誤「消息发送失败（服务器未连接）」「撤回失败，请稍后重试」;「不能给自己发消息哦！」。

## 顯示資料
會話(relevantUsers 幀):`{userID, name, avatarURL, email, identity, score, unRead, threadAnonymous, peerMasked, lastMessagePreview, lastMessageAt, conversationKey}`;訊息:`{chatMsgID, senderUserID, targetUserID, content, isAnonymous, threadAnonymous, createdAt, isRecalled, pending}`;通知項:含 `noticeID` + 分類文字 + `lastID` 游標。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| wss://…/websocket/auth/chat | WSS | `?token=<JWT>` | DefaultLayout 掛載即連 | 擷取檔#127 | 幀格式見 INDEX §5;心跳 30s `{userID,beat:1}`;重連指數退避×5 |
| /api/auth/getNoticeNum | GET | — | 掛載/切 tab | 擷取檔#131 | 回 `{totalNum, unreadTotalNum, readTotalNum}`(裸) |
| /api/auth/getNotice | GET | `?requireID=<游標>&pageSize=20&read=<0|1>` | 載入/滾動 | 擷取檔#132 | 回 `{code, data:{noticeList, lastID}, msg}`;code 201 =「没有更多通知」 |
| /api/auth/readNotice/{noticeID} | PATCH | — | 單則標讀 | — | 回 `{status:"success"}`;「一键已读」= 逐筆並發 PATCH(無批次端點) |
| /api/auth/getChatNotice | GET | `?userID` | 開啟對話/新訊息後 | 擷取檔#126 | 回 `data.noticeNum` |
| /api/auth/getChatHistory | GET | `?senderUserID&targetUserID&threadAnonymous("true"/"false")` | 選會話/重連 | — | 回 `data.chatHistoryList[]` |
| /api/auth/leaveChatView | GET | 同上 | 離開對話 | — | |
| /api/auth/recallChatMessage | POST | `{chatMsgID}` | 撤回 | — | 回 `data.message`(recall 事件) |

## 分頁
**通知**:游標式——`requireID` 首頁 0,之後帶上頁回應的 `lastID`;`pageSize:20`;`read` 0/1 分桶;`code 201` = 到底。觸底 IntersectionObserver(rootMargin 160px)。

## 導向
「查看原帖」→ 對應帖子;`?user=` 進入即開該會話。

## 需登入?
是;WebSocket token 走 query 參數 `token`。

## 未確認事項
- `noticeList[]` 單筆完整欄位集(渲染僅用分類/內容/noticeID;時間/連結欄位名未逐一確認)。
- 通知分類的伺服器端類型代碼(前端以文字分類渲染,代碼對照未見)。
- 會話列表若無 relevantUsers 幀時是否可主動拉取(僅見被動幀)。
