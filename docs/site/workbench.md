# 工作台(原始標題:「工作台」)

- 路由:`/workbench`(name: Workbench;Mobile 底欄「工作台」)
- 來源:JS bundle 分析(WorkbenchView-TftrVydq.js)+ 線上實測

## 用途
應用入口聚合頁:內建常用入口 + 後端動態下發的生態應用 + 全部分區。

## UI 結構
- 標題「工作台」+ 說明「后续集市会扩展更多生态，目前大部分平台还在内测阶段」。
- 「常用」區:應用卡(icon + label,支援後端 colorBg/colorFg 客製色)。
- 「全部分区」區:十大分區卡 → `/partition/{name}`。

## 內建應用清單
| label | 目標 |
|---|---|
| 排行榜 | /ranking |
| 小秋 | /smart-xiaoqiu |
| 打分 | /rating |
| 简历 | /resume |
| 商城 | /shop |
| iWiki | https://ssemarket.cn/iwiki/(外連) |
| 课程专区 | /course |
| 学人汇 | https://scholarhub.top/(外連) |

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/workbench/apps | GET | — | 載入 | ✅實測 200 | **無需 auth**(全站唯一匿名 /auth/* 端點);回裸陣列,以 name 去重後**附加**在內建清單後 |

實測回應樣本(2026-09-04,前 3 筆):
```json
[{"appID":2,"name":"数据库","icon":"tabler:database","targetType":"link","target":"https://db.ssemarket.cn/","groupName":"common","colorBg":"","colorFg":"","source":"platform","invokerSlug":"db-platform","sortOrder":10,"isVisible":true,"createdAt":"2026-09-01T18:39:37+08:00"},
 {"appID":3,"name":"开发者平台","icon":"ph:laptop-bold","targetType":"link","target":"https://developer.ssemarket.cn/","groupName":"common",…,"sortOrder":20,…}]
```
→ `targetType:"route"` 走內部路由、`"link"` 外連(target=_blank rel=noopener noreferrer)。`groupName/source/invokerSlug/sortOrder/isVisible` 前端未使用(意義未確認)。

## 分頁
無(單次載入)。

## 導向
見上表;外連開新分頁。

## 需登入?
頁面:是(路由守衛);但 apps 端點本身**匿名可呼叫**。

## 未確認事項
- 後端如何決定下發哪些 app(全部 isVisible=true?按用戶?未確認)。
