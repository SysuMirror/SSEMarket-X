# 主页(原始標題:「主页」)

- 路由:`/`(name: Home)
- 來源:JS bundle 分析(HomeView-DVrGWK-2.js + BasicCard/getPost/usePostView store)

## 用途
全站資訊流首頁:置頂帖 + 一般帖的無限滾動列表,支援三欄排序與新帖輪詢提示。

## UI 結構
- 頂部工具列 `aria-label「主页与排序」`:標題「主页」+ 排序群組「帖子排序」三鈕:「时间」(tabler:clock)、「点赞」(heart)、「回复」(message),再點同鈕切換升/降(箭頭 icon)。
- 帖子列表(PostList 元件):`[置頂帖(帶「置顶」badge), …一般帖]`;帖子卡(PostCard)結構:
  - 頭部:UserAvatar(頭像+等級標籤 Lv0~祖师爷+名稱,點擊 → 個人頁)+ UserButton 工具列(收藏「收藏/已收藏」、置顶、设为私密、刪除 — 依權限顯示)
  - 標題區:「置顶」badge、「仅自己可见」badge、標題 h3
  - 摘要:正文去圖片語法後前 100 字
  - 圖片九宮格(`Photos` 以 `|` 分隔 + 內文 markdown `![]()` 補足,上限 9 張,依張數變化 grid)
  - 「神評論」區(HotComment,有則顯示):熱評作者名(無則「匿名用户」)+ 前 50 字 + 愛心數;點擊跳詳情
  - 底部 BasicInfo:浏览量(眼)、评论数(對話泡)、点赞(愛心,可點)、投票按鈕(VoteLink:「投票/已投票/提交中」)
- 列表 footer:「加载中…」/「继续下滑加载更多」/「暂无更多」。

## 顯示資料
帖子欄位(getPost normalize):`PostID, UserID, UserName, UserScore, UserTelephone, UserAvatar, UserIdentity, Title, Content, Like, Comment, Browse, Heat, PostTime, IsSaved, IsLiked, IsWatched, IsPrivate, IsLottery, IsAnonymous, IsOwner, IsPinned, PinnedAt, PinnedExpiresAt, Photos("|"分隔), Tag, HotComment{userName,likeNum,…}`。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/browse | POST | `{limit:10(首載,續載15), offset, partition:"主页", searchsort:"home", searchinfo:"", tag:"", orderBy, timeFrom:"", timeTo:"", userTelephone}` | 載入/滾底/排序變更 | 擷取檔#13 | 回應 `{pinned:[], posts:[], total}` 或裸陣列 |
| /api/auth/getPostNum | POST | 同上條件 | 載入與增量檢查 | 擷取檔#12 | 回 `{Postcount}` |
| /api/auth/browse(置頂) | POST | 同條件但 `limit:1, offset:0` | 僅 searchsort=home 時刷新置頂 | — | 讀 `pinned` |
| /api/auth/browse(新帖輪詢) | POST | `{limit:20, offset:0, partition:"主页", searchsort:"home",…}` | 每 60 秒(newPostsStore) | — | 差集 → 通知「有 N 条未查看的新帖子」→「去查看/去首页查看」 |
| /api/auth/updateLike / updateSave / deletePost / updatePostPrivacy / pinPost / unpinPost / checkUserVoted / submitVote | POST | 見 INDEX §3 | 卡片操作 | — | 全站共用 |

## 分頁
- 參數:`limit`(初始 10、續載 15)+ `offset`(0 起算項目偏移,前端 += 本頁筆數)
- 總數:getPostNum → `Postcount`(browse 回應的 `total` 恆 0,**不可用**)
- 觸發:IntersectionObserver(rootMargin 240px);`hasMore = 本頁筆數 ≥ limit`
- orderBy 六值:`time_desc/time_asc/like_desc/like_asc/comment_desc/comment_asc`
- 快取:keep-alive 快取列表/條件/捲動位置;返回時以 Postcount 差額抓新帖 unshift 置頂。
- 排序:依 PostID 降冪(前端二分搜尋假設降冪)。

## 導向
帖子卡 → `/postdetail/:id`;頭像/名稱 → `/user/:id`;「去查看」→ `/?refresh=<ts>`。

## 需登入?
是(路由守衛;未登入 → `/auth/login?redirect=/`)。

## 未確認事項
- 伺服器對 `orderBy` 六值的實際 SQL 排序行為(僅知參數名與 UI 對應)。
- `Heat` 欄位在此頁未被渲染(僅詳情/熱榜用),意義未確認。
