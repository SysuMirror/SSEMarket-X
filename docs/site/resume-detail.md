# 简历详情(原始標題:「简历详情」)

- 路由:`/resume/:id`(name: ResumeDetail)
- 來源:JS bundle 分析(ResumeDetailView-CTfSZJBj.js + pdfjs-pmUu2cY4.js)

## 用途
簡歷單頁:資訊、線上預覽(pdf.js/圖片)、下載、編輯、刪除。

## UI 結構
- 導航「返回」+「简历详情」;loading「加载中…」;不存在:「简历不存在或已删除」+「返回列表」。
- 左欄:檔案 icon、標題、chips「匿名」+類型(PDF/Word/图片/副檔名)+「可预览」(canPreview);描述或「暂无简介」;統計「上传者/大小/浏览/下载/时间」;isOwner 編輯模式(「标题」maxlength 50、「简介」maxlength 500、「保存/取消」);動作「预览/刷新预览」「下载」(confirm「确定要下载这份简历吗？」)「编辑」「删除」(confirm「确定删除这份简历吗？」)。
- 右欄預覽:PDF 工具列(縮放 75–200%、slider「缩放比例」、「缩小/放大/适应宽度」)、逐頁 canvas;圖片預覽同款縮放/拖曳;doc/docx:「该格式请下载后本地打开」。微信環境(UA MicroMessenger)有專屬提示文案。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/resume/detail | POST | `{resumeID}` | 載入 | 擷取檔#122 | 回整包 detail |
| /api/auth/resume/preview/stream/{resumeID} | GET | — | 點「预览」 | — | **原生 fetch + Bearer**;PDF→arrayBuffer、圖→blob→objectURL |
| /api/auth/resume/download | POST | `{resumeID}` | 點「下载」 | — | 回 `data.downloadURL`、`data.fileName`;前端建 `<a download>`(微信內直接 location.href) |
| /api/auth/resume/update | POST | `{resumeID, title, description}` | 保存編輯 | — | 回應直接成為新 detail |
| /api/auth/resume/delete | POST | `{resumeID}` | 刪除 | — | `code===200` |

## 分頁
無;watch `route.params.id` 重新載入。

## 導向
刪除成功 → `/resume/my`;返回 → back。

## 需登入?
是。

## 顯示資料
`{resumeID, title, description, uploader, fileExt, fileSize, viewNum, downloadNum, createdAt, isAnonymous, isOwner, canPreview}`;pdf.js worker 路徑 `/new/pdf.worker.min.js`,DPR 上限 2(微信 1.5)。

## 未確認事項
- `canPreview` 判斷規則(推測 = pdf/圖片類,伺服器欄位)。
- downloadURL 的有效期/是否限本人才可下載。
