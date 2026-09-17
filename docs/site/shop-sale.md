# 发布商品(原始標題:「发布商品」)

- 路由:`/shop/sale`(name: Sale)
- 來源:JS bundle 分析(SaleView-DnijuNK_.js、mutations-C00mKXf9.js、utils-1MCYKXOd.js)

## 用途
上架二手商品(最多 5 圖),可選同步發帖到主頁。

## UI 結構
- 標題「发布商品」+「返回」。
- 欄位:「名称（最多 30 字）」(placeholder「如：高等数学教材第七版」)、「价格（元）」(number,min 1,placeholder「整数价格」)、「图片（最多 5 张）」(file input accept image/*, multiple;FileReader 預覽 + 「×」刪除)、「描述」textarea(maxlength 2000,placeholder「成色、交易方式、联系方式等」)。
- 同步開關「同步发帖到主页」+ 說明「开启后将以「新上架-名称」为题在主页发帖，正文含商品链接；关闭则仅上架商品。」
- 提交「发布商品/发布中…」;toast:「请填写商品名称」「请填写有效价格」「请填写商品描述」「最多 5 张图片」「发布失败」/「已发布，并已同步发帖到主页」「商品发布成功」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/uploadPhotos | POST | FormData(`file`) | 提交時逐張序列上傳 | — | 原生 fetch + Bearer;回 `.fileURL` |
| /api/auth/postProduct | POST | `{UserID, Price:Math.round(輸入), Title:name.trim(), Content:description.trim(), Photos:[fileURL…], ISAnonymous:false, syncFeedPost:bool}` | 提交 | — | 成功取 `data?.ProductID ?? ProductID`;失敗條件 `code!==undefined && code!==200` |

## 分頁
無。

## 導向
成功 → `/shop/productdetail/{ProductID}`;返回 → back。

## 需登入?
是。

## 未確認事項
- 本頁無匿名選項(ISAnonymous 恆 false);AI 草稿卡路徑(SmartXiaoQiu)可帶 ISAnonymous → 欄位伺服器支援,UI 入口僅在 AI 草稿。
- 價格實際上限(min 1 前端;伺服器規則未確認)。
