# 简历专区(原始標題:「简历专区」)

- 路由:`/resume`(全部简历,searchsort=home)、`/resume/my`(我的简历,searchsort=my)
- 來源:JS bundle 分析(ResumeView-D9KFnLkR.js)

## 用途
簡歷分享區:列表 + 搜尋;兩個 tab 其實是同一元件以 searchsort 區分。

## UI 結構
- 頭部(tabler:file-cv)「简历专区」/ 副標「上传与分享简历，支持 PDF、Word、图片格式」。
- Tabs:「全部简历」(`/resume`)、「我的简历」(`/resume/my`,router.replace 切換)。
- 搜尋:placeholder「搜索标题、简介或文件名」+「搜索」鈕;「上传简历」鈕 → `/resume/upload`。
- 狀態:「加载中…」;空:「你还没有上传简历」(my)/「暂无简历，快来上传第一份吧」(home)。
- ResumeCard:副檔名 icon(pdf/doc/圖片/其他)、標題 + 「匿名」徽章(isAnonymous)、描述、meta「{uploader} · {大小} · {viewNum} 次浏览 · {downloadNum} 次下载」(大小:`fileSize/1024` KB/MB)、footer `{fileExt 大寫}` + createdAt;整卡點擊 → 詳情。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/resume/list | POST | `{searchinfo:<關鍵字trim>, searchsort:"home"/"my", limit:200, offset:0}` | 載入/tab 切換/搜尋 | 擷取檔#120 | 回**陣列**(小寫駝峰欄位) |

## 分頁
無滾動載入——固定 `limit:200, offset:0` 一次取回。

## 導向
`/resume/upload`(上傳)、`/resume/{resumeID}`(卡片)。

## 需登入?
是。

## 顯示資料
`{resumeID, title, description, uploader, isAnonymous, fileExt, fileSize, viewNum, downloadNum, createdAt}`。

## 未確認事項
- 「我的简历」是否由伺服器按 token 判斷(body 無 userID 欄位 → 伺服器從 JWT 取)。
- 超過 200 份時的行為(前端不翻頁)。
