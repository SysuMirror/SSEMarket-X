# 反馈(原始標題:「反馈」)

- 路由:`/feedback`(name: Feedback)
- 來源:JS bundle 分析(FeedbackView-BRN0Q9N3.js)

## 用途
提交意見反饋給站方。

## UI 結構
標題「反馈」;說明「请在下方输入您的反馈信息」;textarea placeholder「请在此输入反馈...」;「提交」鈕;空內容 toast「请输入反馈内容」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/submitFeedback | POST | `{ftext:<內容>, attachment:""}` | 提交 | — | 回應讀 `.msg` toast;attachment 恆空字串(無附件 UI) |

## 分頁
無。

## 導向
無(停留原頁)。

## 需登入?
是。

## 未確認事項
- attachment 欄位是否伺服器預留(前端無入口)。
