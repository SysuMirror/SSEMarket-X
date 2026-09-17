# 上传简历(原始標題:「上传简历」)

- 路由:`/resume/upload`(name: ResumeUpload)
- 來源:JS bundle 分析(ResumeUploadView-HM_lhI5d.js)

## 用途
上傳單一簡歷檔(PDF/Word/圖片)並設標題/簡介/匿名。

## UI 結構
- 標題「上传简历」+ 返回(→ `/resume`)。
- 欄位:「标题 *」(maxlength 50,placeholder「例如：2025 前端实习简历」)、「简介」textarea(maxlength 500)、checkbox「匿名展示（他人看不到你的用户名）」、「简历文件 *」(file input,accept 白名單;按鈕「选择 PDF / Word / 图片」顯示檔名)。
- 提示:「支持 PDF、Word、JPG、PNG、WebP、GIF，单文件不超过 10MB，每人最多 5 份」。
- 提交鈕「确认上传/上传中…」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/resume/upload | POST | **FormData**:`file`(原始檔名)、`title`、`description`、`isAnonymous`("true"/"false" 字串) | 提交 | — | **原生 fetch**(非共用 wrapper),僅帶 `Authorization: Bearer`;成功條件 `ok && code===200`;回 `data.resumeID`、`msg` |

## 分頁
無。

## 導向
成功 → `/resume/{resumeID}`;返回 → `/resume`。

## 需登入?
是(無 token 直接擋「请先登录」)。

## 未確認事項
- 「每人最多 5 份」僅為提示文字,超額時伺服器錯誤格式未確認。
- 伺服器端副檔名/大小驗證(前端已驗,伺服器行為未測)。
