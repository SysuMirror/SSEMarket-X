# 评分帖详情(原始標題:「评分详情」)

- 路由:`/rating/:id`(name: RatingDetail)
- 來源:JS bundle 分析(RatingDetailView-D5mYBIR2.js、RatingDistribution、RatingShow、comments-CzMsPPuk.js、RatingCommentCard)

## 用途
單則評分帖:給星、分佈統計、評論(評論可攜星)、讚/刪。

## UI 結構
- 頂部「评分详情」+ 返回(aria「返回」);loading「加载中…」。
- RatingDetailCard:UserAvatar、時間(MM/DD HH:mm)、讚(heart + like 數)、本人顯示刪除(trash)。
- 分類連結 `{categoryName} 同分区更多` → `/rating?category=id`。
- 統計列:eye `{browse}`、message `{comment}`、users `{Σstars} 人评`。
- 正文 MarkdownContainer + photos 圖(點擊燈箱)。
- **RatingDistribution**:左 `averageRating.toFixed(1)` 大字 + 「综合 · {N}人」;「我的评分」5 顆可點 ★(aria「选择星级」/「N 星」);右分佈條 5星→1星 各列 `{n}星` + 進度條 + 人數(aria「评分统计」)。
- 底部撰寫區:切換「写评论/收起评论」;MarkdownEditor placeholder「写下你的评价…」(空內容且未評星 → 「请写评论或先评分」)。
- 評論區「评价」+ 計數 + CommentSortSwitch(「最新/最早」)+ CommentCard 列表;每則評論右側 RatingShow 只讀顯示**該評論作者的評星**(AuthorRating)。空狀態「暂无评价，来写第一条吧」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/rating/post/detail | POST | `{ratingPostID}` | 載入 | 擷取檔#47 | 回單帖(+ `userStar`);不存在 → toast「评分帖不存在」→ replace `/rating` |
| /api/auth/rating/star/submit | POST | `{ratingPostID, starNum}` | 點星 | — | 樂觀更新 userStar,失敗回滾「评分失败」 |
| /api/auth/rating/comment/list | POST | `{ratingPostID}` | 載入 | 擷取檔#48 | 回裸陣列 |
| /api/auth/rating/comment/create | POST | `{ratingPostID, content, starNum}` | 發評論(可同時攜星) | — | 成功 toast「已发布」 |
| /api/auth/rating/comment/like | POST | `{commentID}` | 評論讚 | — | |
| /api/auth/rating/post/like | POST | `{ratingPostID}` | 帖讚 | — | |
| /api/auth/rating/post/delete | POST | `{ratingPostID}` | 刪除(confirm「确定删除这条评分？」) | — | 成功 → `/rating` |

## 分頁
評論無分頁,一次全載,前端排序 asc/desc(CommentTime 主鍵、commentID 次鍵)。

## 導向
刪除成功 → `/rating`;分類連結 → `/rating?category=id`;返回 → back。

## 需登入?
是。

## 顯示資料
詳情 = 列表欄位 + `userStar`(本人已給星數);評論:`{commentID, authorID, author, authorTelephone, authorScore, authorAvatar, authorIdentity, commentTime, content, likeNum, isLiked, authorRating}`。

## 未確認事項
- `starNum` 範圍限制(前端送 1~5;伺服器是否驗證未確認)。
- 評論攜星與單獨 star/submit 的優先序(兩者都會影響分佈?)未確認。
