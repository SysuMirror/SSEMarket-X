# 商品详情(原始標題:「商品详情」)

- 路由:`/shop/productdetail/:ProductID`(name: Productdetail)
- 來源:JS bundle 分析(ProductView-AUCfPioN.js、queries、mutations)

## 用途
單一商品:圖集、價格、賣家資訊;賣家可標售出/刪除;買家可私聊/匿名私聊。

## UI 結構
- 「返回」+「商品详情」;「加载中…」。
- 圖集:主圖 + 縮圖列(縮圖 src 將 `/uploads/` 換成 `/resized/`);點主圖 → 全屏燈箱(還原 uploads 原圖);無圖顯示 tabler:photo-off;已售浮標「已售出」。
- 內文:Name(h1)、`¥{Price}`、meta(賣家名 + PostTime `toLocaleString("zh-CN")` 月/日 時:分)、Description。
- 動作列:
  - 賣家本人:「标记售出」(confirm「确认标记为已售出？」)、「删除」(confirm「确定删除该商品？」);ISSold 時前者 disabled。
  - 買家:「私聊卖家」、「匿名私聊」(ISSold 時 disabled)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/getProductDetail | POST | `{productID}` | 載入 | 擷取檔#61 | 回單一商品;null → 「商品不存在」→ replace `/shop` |
| /api/auth/getInfo | POST | `{userID: SellerID}` | 載入(SellerID>0) | 擷取檔#5 | 取賣家 name;模組級 Map 快取;fallback「用户{id}」/「匿名卖家」 |
| /api/auth/saleProduct | POST | `{productID}` | 标记售出 | — | 成功條件 `code===200 || code===undefined` |
| /api/auth/deleteProduct | POST | `{productID}` | 删除 | — | 成功 → `/shop/myproducts` |

## 分頁
無;watch `route.params.ProductID` 重載。

## 導向
`/shop`(錯誤)、`/shop/myproducts`(刪除後)、`/messages?tab=chat&user={SellerID}`(私聊;匿名再加 `&anonymous=1`)。

## 需登入?
是。

## 未確認事項
- 匿名賣家(SellerID=0 或 ISAnonymous)時 getInfo 行為——前端跳過呼叫,賣家名顯示規則為 fallback 邏輯。
