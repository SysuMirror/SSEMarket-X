# 個人主頁(原始標題:「{用户名} | SSE」)

- 路由:`/user/:id`(name: UserProfile)
- 來源:JS bundle 分析(UserProfileView-ks65Mbfl.js)

## 用途
他人/自己的公開檔案頁:頭像、簡介、經驗值等級、發帖動態(可被隱藏)。

## UI 結構
- 頭部:頭像、「{name}」(fallback「未命名用户」)、「发私信」按鈕、「简介」、「经验值」+ level 標籤(Lv0 菜鸟 ~ 祖师爷)+「条」。
- 動態區:tab「我的动态」/「TA 的动态」;PostList(同款帖子卡)。
- 空狀態:「还没有帖子」;「发帖记录已隐藏」/「该用户关闭了动态展示」(hideProfilePosts);無效用戶「请求无效」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/getInfo | POST | `{userID:<路由id>}` | 載入 | 擷取檔#5 | 回用戶卡 |
| /api/auth/userProfilePostNum | POST | `{targetUserID}` | 載入 | — | 回 `{Postcount}` |
| /api/auth/userProfilePosts | POST | `{targetUserID, limit:15, offset}` | 載入/滾底 | 擷取檔#26 | 回**裸陣列**帖子 |

## 分頁
limit 15 + offset 累加(無限滾動);`hasMore = 本頁 <15 或總數已達 Postcount`。

## 導向
「发私信」→ `/messages?tab=chat&user={id}`;帖子卡 → `/postdetail/:id`。

## 需登入?
是。

## 顯示資料
getInfo 回:`{avatarURL, name, intro, email(他人頁未必有), identity, score, hideProfilePosts}`;等級門檻:100/300/600/1000/2000/3000/4000/5000。

## 未確認事項
- 他人頁是否回傳 email/phone(前端僅渲染 avatar/name/intro/score;隱私欄位未確認)。
