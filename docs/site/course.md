# 课程专区(原始標題:「课程专区」)

- 路由:`/course`(name: Course);另有頂欄連結 `/partition/课程专区` 亦導向此頁
- 來源:JS bundle 分析(CourseView-ve4sG_yC.js、getTeacher-BPJhlnJH.js)

## 用途
以「老師(課程標籤)」過濾的课程分区帖子流:選老師 → 以 `tag=老師名` 重查 browse。

## UI 結構
- h2「课程专区」。
- 提示文字「请选择你的老师，不选也没关系 」+ `<select id="teacher">`(選項 = 老師標籤名,空值 = 全部)。
- PostList 資訊流(dense 模式:卡片僅顯示作者列,無頭像區)。

## 顯示資料
老師下拉:`{TagID, Name}[]`;帖子欄位同主頁 PostCard。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/getTags?type=course | GET | query `type=course` | 載入 | 擷取檔#119 | 回 `data.tags = [{TagID, Name}]` |
| /api/auth/browse | POST | `{limit:15(首載10), offset, partition:"课程专区", searchsort:"home", searchinfo:"", tag:<老師名或"">, orderBy:"time_desc", timeFrom:"", timeTo:"", userTelephone}` | 載入/選老師/滾底 | — | |
| /api/auth/getPostNum | POST | 同上 | 同上 | — | |

## 分頁
同主頁(limit 15/首載 10 + offset;Postcount 總數;觸底載入)。換老師:清空列表、offset 歸零重查。

## 導向
帖子卡 → `/postdetail/:id`(PostList 處理)。

## 需登入?
是。

## 未確認事項
- getTags 是否支援 `type` 其他取值(僅見 `course`)。
- 搜尋框在課程頁搜尋時會帶 `partition=课程专区` query 跳 `/search`(useHeaderSearch 特例)。
