# 创建打分分区 / 发布评分(原始標題:「创建打分分区」、「发布评分」)

- 路由:`/rating/category/new`(RatingCategoryNew)、`/rating/post`(RatingPost;query `?category=`)
- 來源:JS bundle 分析(RatingCategoryCreateView-_L7_Qvjl.js、RatingPostCreateView-D2oyeA4f.js)

## 用途
建立打分分區;在分區下發布評分帖(標題+說明,無圖)。

## UI 結構
- **创建分区**:header「创建打分分区」+ 返回;欄位「分区名称」(maxlength 30,placeholder「如：食堂餐饮、高数课程」)、「简介（可选）」(maxlength 200);同步開關「同步发帖到主页」+ 說明「开启后将以「新增分区-名称」为题在主页发帖，正文含打分专区链接；关闭则仅创建分区。」;送出鈕「创建分区/创建中…」。
- **发布评分**:header「发布评分」+ 返回;欄位「所属分区」select、「标题」(maxlength 50,placeholder「例如：东区食堂二楼」)、「说明（可选）」MarkdownEditor(placeholder「补充说明、评分理由等（可选）」);送出鈕「发布/发布中…」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/rating/category/create | POST | `{name, description:"", syncFeedPost:true/false}` | 送出 | — | 成功回分類 JSON(含 categoryID);失敗 null |
| /api/auth/rating/category/list | POST | `{}` | 發布頁載入分區 | 擷取檔#45 | 預設選中:query.category → 「其他」→ 第一個 |
| /api/auth/rating/post/create | POST | `{categoryID, title, content}` | 送出 | — | 成功回 `{ratingPostID}`;**Content-Type: application/json(非表單)** |

## 分頁
無。

## 導向
建分區成功 → `/rating?category={id}`(replace);發布成功 → `/rating/{ratingPostID}`;返回 → `router.back()`。

## 需登入?
是。

## 未確認事項
- 分區名稱唯一性規則(失敗 toast「创建失败，名称可能已存在」→ 推測伺服器拒絕重名,規則未確認)。
