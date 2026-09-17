# OAuth 授權頁(原始標題:「----连接----」)

- 路由:`/connect`(name: Connect)
- 來源:JS bundle 分析(ConnectView-DRpjlNQO.js)

## 用途
第三方應用(potentially PAT 生態,如 developer.ssemarket.cn)以 OAuth 風格請求授權讀取用戶基本資訊。

## UI 結構
- 狀態:「正在验证应用信息...」/「授权过程出错」;「返回首页」鈕。
- 連接卡「----连接----」(app 圖示 + 站圖示)、「授权给 {app_name}」。
- 權限說明:「{app_name} 希望：访问您在集市的头像、用户名等基本信息」(scope read_basic)。
- 用戶卡:暱稱(fallback「未设置昵称」)+ intro + email(來自 getInfo)。
- 按鈕「允许」(送出中「授权中...」)/「取消」(回 document.referrer 或 opener,都無 → toast「无法获取来源页面URL，将返回首页」)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/connect/check | POST | `{app_id}` | 載入 | — | `code===200` → `data{app_name, app_icon, description}` |
| /api/auth/connect/authorize | POST | `{app_id, redirect_uri, response_type, scope, state}` | 點「允许」 | — | 回 `data.redirect_url` → location.href |
| /api/auth/getInfo | POST | `{userID}` | 載入用戶卡 | — | |

## Query 參數(進入本頁)
`appid`、`redirect_uri`、`scope`(僅支援 `read_basic`,否則「暂不支持」)、`response_type`(以上必填,缺 → 「缺少必需参数: …」)、`state`(選填);未登入 → `/auth/login?redirect=<完整原URL>`。

## 分頁
無。

## 導向
授權成功 → 外跳 redirect_url;取消 → referrer/opener/首頁。

## 需登入?
是。

## 未確認事項
- response_type 取值(僅知必填;`code`?未見驗證)。
- redirect_url 是否含 code/state 的組裝(伺服器端組,前端僅跳轉)。
