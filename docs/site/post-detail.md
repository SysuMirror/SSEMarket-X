# 帖子詳情(原始標題:帖子標題 | SSE)

- 路由:`/postdetail/:id`(name: Postdetail)
- 來源:JS bundle 分析(PostDetailView-NDYwTIOd.js、CommentToolbar、CommentCard、lottery、MarkdownContainer、ImageShower)

## 用途
單帖全貌:正文(Markdown+圖)、互動(讚/收藏/碼住/投票)、抽獎盒、一/二級評論。

## UI 結構
- **DetailCard**:UserAvatar + UserButton 工具列;私密 badge「仅自己可见」;標題 h2;MarkdownContainer 正文(支援 @提及連結、KaTeX、程式碼複製鈕「复制」);`Photos` → OldImages 圖列;BasicInfo(時間 `toLocaleString("zh-CN")`、浏览/评论/点赞);CommentToolbar(「码住」按鈕「已码住/码住」+ VoteLink 投票);回覆框 MarkdownEditor placeholder「写下你的评论…（@昵称+空格 可通知对方）」。
- **LotteryDetailBox**(抽獎帖):「抽奖」標題;模式+狀態(「许愿抽奖|随机抽奖 · 进行中|已开奖」);倒數「距离开奖 HH:MM:SS」/「已到开奖时间，等待开奖…」;統計「N 人次参与 · 你已参与」;獎品列(名稱、×數量、許願關鍵詞、「N 人」、「已参与」);參與鈕「参与抽奖/已参与/提交中…」(僅隨機模式進行中);結果「中奖名单」`{userName, prizeName}`[] 或「暂无中奖者」。到期未開獎 → **每 15 秒輪詢** detail。
- **評論區**:「评论」+ 總數(= 一級 + 二級)+ CommentSortSwitch(「最新/最早」);CommentCard:UserAvatar、時間(MM/DD HH:mm)、正文 Markdown、讚、回覆框(placeholder「写下你的回复…（输入 @昵称 可通知对方，后接空格）」)、子評論展開「展开(N)」;CCommentCard 子評論卡。
- 圖片點擊 → ImageShower 全屏燈箱(resized → uploads 原圖)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/showDetails | POST | `{postID, userTelephone}` | 載入 | 擷取檔#27 | 單帖(含 IsOwner/HotComment 等) |
| /api/auth/updateBrowseNum | POST | `{postID, userTelephone}` | showDetails 後 fire-and-forget | 擷取檔#28 | |
| /api/auth/showPcomments | POST | `{postID, userTelephone, postType:"post"}` | 載入 | 擷取檔#38 | 回評論陣列(含 SubComments) |
| /api/auth/toggleWatch | POST | `{postID, userTelephone}` | 「码住」 | — | 回 `data.watched` |
| /api/auth/lottery/detail | POST | `{postID, userTelephone}` | 帖為抽獎帖時 | — | `code===200 && data.isLottery!==false` |
| /api/auth/lottery/participate | POST | `{postID, userTelephone}` | 「参与抽奖」 | — | |
| /api/auth/postPcomment | POST | `{content, postID, userTelephone}` | 發一級評論 | — | |
| /api/auth/postCcomment | POST | 子評論物件(呼叫端組裝) | 發二級回覆 | — | 欄位未全確認 |
| /api/auth/deletePcomment / deleteCcomment | POST | `{pcommentID}` / `{ccommentID}` | 刪評論(本人) | — | |
| /api/auth/updatePcommentLike / updateCcommentLike | POST | `{pcommentID|ccommentID, userTelephone}` | 評論讚 | — | |
| /api/auth/checkUserVoted / submitVote | POST | `{postID, userTelephone}` | VoteLink | 擷取檔#65+ | |
| /api/auth/resolveMentions | POST | `{names[]}` | 正文含 @ 時 | — | → `data.users[{name,userID}]` |

## 分頁
**評論無分頁**:一次全載,前端排序 asc/desc(鍵 CommentTime→Date.parse,次鍵 PcommentID)。

## 導向
刪帖 → `/`;@提及/頭像 → `/user/:id`;`post://123` 形式連結 → `/postdetail/123`。

## 需登入?
是。

## 顯示資料
評論欄位(camel/Pascal 容忍):`PcommentID, AuthorID, Author, AuthorTelephone, AuthorScore, AuthorAvatar, AuthorIdentity, CommentTime, Content, LikeNum, IsLiked, SubComments[](同構+ccommentID)`;抽獎:`{status:"active"/"drawn"/"closed", mode, drawAt, participantCount, participated, prizes:[{prizeID,name,quantity,wishKeyword,participantCount,participated}], winners:[{userName,prizeName}]}`。

## 未確認事項
- `postCcomment` 完整 body 欄位(組裝處在 404 chunk 鏈)。
- 「神評論」HotComment 的伺服器挑選規則。
- `postType` 參數是否有 `"post"` 以外取值(打分評論另走 rating 端點,此參數可能為相容欄位)。
