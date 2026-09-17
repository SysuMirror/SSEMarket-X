# 收藏 / 历史(原始標題:「收藏」、「发帖历史」)

- 路由:`/save`(Save)、`/history`(History)
- 來源:JS bundle 分析(SaveView-C-q46mIm.js、HistoryView-DTMiPXE1.js;兩者結構相同)

## 用途
個人收藏帖 / 自己發過的帖的資訊流(伺服器按 searchsort 過濾)。

## UI 結構
h2「收藏」/「发帖历史」+ PostList(同主頁卡片;無排序器、無置頂列)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/browse | POST | `{limit:15(首載10), offset, partition:"收藏"/"历史", searchsort:"save"/"history", searchinfo:"", tag:"", orderBy:"time_desc", timeFrom:"", timeTo:"", userTelephone}` | 載入/滾底 | 擷取檔#14,#16 | **partition 與 searchsort 同時帶** |
| /api/auth/getPostNum | POST | 同上 | 載入 | 擷取檔#15,#17 | |

## 分頁
同主頁(limit 15/首載 10 + offset;Postcount;觸底載入)。收藏頁取消收藏 → 該帖自列表移除且 `offset--`、`total--`。

## 導向
帖子卡 → `/postdetail/:id`。

## 需登入?
是。

## 未確認事項
- 「历史」定義 = 自己發的帖(含匿名)或瀏覽過的帖:前端無線索,僅能從語意與擷取檔 #16 推測為發帖歷史(頁面標題即「发帖历史」)。
