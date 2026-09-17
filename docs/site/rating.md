# 打分专区(原始標題:「打分专区」)

- 路由:`/rating`(name: Rating;query `?category=<categoryID>`);`/partition/打分` → redirect `/rating`
- 來源:JS bundle 分析(RatingView-C85Mtae4.js、categories-MnUjG2zL.js、posts-BoUHqj2b.js)

## 用途
評分社群首頁:分類 pill + 搜尋 + 評分帖卡列表(載入更多式)。

## UI 結構
- 頭部:品牌「打分专区」(tabler:flame)+ 動作鈕「创建分区」(ghost)、「发布」(primary,plus)。
- 搜尋列:placeholder「搜索主题或分区名（如「其他」）」+ 按鈕「搜」(Enter 同)。
- 分區 pill nav(aria「分区筛选」):「全部」+ 各分類 `{name} {postCount}`。
- 條件顯示「当前分区：{name}」。
- RatingCard:標題(fallback「未命名评分」)、meta「{Σstars} 人评 · {comment} 评 · {browse} 阅」、右側分數 `averageRating.toFixed(1)`(aria「综合评分」)、愛心讚(aria「取消赞/点赞」)、分類連結(folder + categoryName)。
- 空狀態「暂无内容」;「加载更多」按鈕(loading 顯示「…」)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/rating/category/list | POST | `{}` | 載入 | 擷取檔#45 | 回**裸陣列** `[{categoryID, name, description, postCount}]`;前端過濾 name==="test"(trim+小寫)並按 categoryID 降冪 |
| /api/auth/rating/post/list | POST | `{categoryID:<0=全部>, searchinfo:<trim>, limit:20, offset}` | 載入/換分類/搜尋/加载更多 | 擷取檔#46 | 回裸陣列 |
| /api/auth/rating/post/like | POST | `{ratingPostID}` | 卡片讚 | — | 樂觀更新,失敗 toast「操作失败」 |

## 分頁
`limit:20`(頁面實值)+ `offset` 累加;**無總數欄位**(裸陣列)→ `hasMore = 本頁 20 筆`;「加载更多」按鈕(非無限滾動)。換分類/搜尋 → offset 歸零重查。

## 導向
卡片 → `/rating/{ratingPostID}`;分類連結/pill → `/rating?category={id}`(router.replace);「发布」→ `/rating/post?category={id}`;「创建分区」→ `/rating/category/new`。

## 需登入?
是。

## 顯示資料
評分帖:`{ratingPostID, categoryID, categoryName, userID, userName, userScore, userTelephone, userAvatar, userIdentity, title, content, like, comment, browse, createdAt, isLiked, photos, averageRating, stars[5](1~5星人數), raterCount}`。

## 未確認事項
- `postCount` 由伺服器回傳(分類列表內),更新時機未確認。
- 前端過濾 "test" 分類:是歷史髒資料防禦,伺服器端是否仍存在該分類未確認。
