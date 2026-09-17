# 商店列表(原始標題:「逛逛好物」、「我的商品」)

- 路由:`/shop`(Shop,searchsort=home)、`/shop/myproducts`(MyProducts,searchsort=history)——同一元件 ShopView
- 來源:JS bundle 分析(ShopView-Db8M2mH5.js、ShopLayout-BQo_YhaB.js、queries-DQfBsA89.js)

## 用途
二手集市:商品卡列表 + 輪播牆 + 搜尋 + 前端價格/狀態篩選;「我的商品」看自己上架(含已售)。

## UI 結構
- ShopLayout 導覷:Mobile tabs「商城/我的/发布/消息」;PC 側欄「商城首页/我的商品/发布商品/消息/返回主页」。
- 頭部:h1「逛逛好物」/「我的商品」+ 副標「在售 N 件」/「共 N 件 · 在售 M」+「发布」鈕。
- Hero 輪播(aria「商城轮播」,4.5 秒自動輪播,最多 6 張):首張固定宣傳「软工集市/闲置好物，校内交易」,其餘取商品圖「在售好物/点击进入详情」。
- 搜尋列:placeholder「搜索商品名或描述」/「搜索我的商品」+「搜索」。
- 篩選 chips(**純前端過濾**):home 價格「全部/≤20/≤50/≤100/≤500/500+」;my 狀態「全部/在售/已售出」。
- 商品卡:封面 Photos[0]、售出角標「已售出」、Name、Description、價格 `"¥"+Price`(整數,postProduct 已 Math.round)。
- 狀態:「加载中…」;空:「暂无在售商品」/「还没有发布商品」+「去发布」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/getProducts | POST | `{searchinfo:<trim>, searchsort:"home"(在售)/"history"(全部,myproducts 用), limit:80, offset:0}` | 載入/搜尋/路由切換 | 擷取檔#58-#60 | 回**裸陣列**;watch route.path(/shop、/shop/myproducts)重載 |
| /api/auth/getProducts(輪播) | POST | `{searchinfo:"", searchsort:"home", limit:12, offset:0}` | home 載入 | — | 取 Photos 去重前 6 張 + 固定 COS 宣傳圖 |

## 分頁
無滾動:單次 `limit:80`。API 層預設 limit=1000(呼叫端可覆寫)。

## 導向
`/shop/sale`(发布/去发布)、`/shop/productdetail/{ProductID}`(卡片)。

## 需登入?
是。

## 顯示資料
`{SellerID, ProductID, Seller, Price, Name, Description, Photos[], ISSold, ISAnonymous, PostTime}`。

## 未確認事項
- searchsort 其他取值(僅見 home/history);orderBy 類參數不存在於此端點。
- 「history」語意 = 全部(含已售),由 myproducts 用法推得。
