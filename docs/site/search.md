# 搜索(原始標題:「搜索」)

- 路由:`/search`(name: Search;query:`sinfo`、`partition`、`smart`、`timeFrom`、`timeTo`);`/rag-preview` → redirect `/search?sinfo&q&smart=1`
- 來源:JS bundle 分析(SearchView-BqyCMKxq.js、ragSearch-CYOwrorG.js、useHeaderSearch-Dcq41tvg.js)

## 用途
兩種模式:一般(關鍵詞+分區+時間範圍,browse)與智能(RAG 語意檢索,rag-local)。

## UI 結構
- 關鍵詞列:「关键词：」+ 時間範圍「发帖时间范围」「从/到」(datetime-local)、「应用筛选」、「清除时间」、「已筛选：…/不限/至」。
- 智能模式提示「智能检索中...」。
- 結果 = PostList 資訊流(課程分區時 dense 模式)。
- 頂欄搜尋框(useHeaderSearch):熱詞輪播 placeholder(每 3.6 秒輪換,rag hot-queries limit 8)、模式切換鈕「切换普通/切换智能」;搜「年度报告」→ 直達 `/annual2025`。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/browse | POST | `{limit:15, offset, partition:<query.partition|"主页">, searchsort:"home", searchinfo:<sinfo>, tag:"", orderBy:"time_desc", timeFrom, timeTo, userTelephone}` | 一般模式載入/滾底 | — | |
| /api/auth/getPostNum | POST | 同上 | 載入 | — | |
| /api/rag-local/search | GET | `?q=<sinfo>&limit=10&source=manual` | smart=1 | ❌實測 502(服務異常) | **無 auth**;回 `{ok,data:{results:[{post,…}]}}`,前端取 `results[].post` 直接取代列表 |
| /api/rag-local/hot-queries | GET | `?limit=8` | 搜尋框掛載 | ✅實測 200 | 無 auth;`data=[{query,count,last_seen(unix秒),recommend_score}]` |

## 分頁
- 一般模式:同主頁無限滾動(limit 15 + offset)。
- 智能模式:**無分頁**(`hasMore=false`,一次 10 筆)。

## 導向
帖子卡 → `/postdetail/:id`;「年度报告」關鍵詞 → `/annual2025`。

## 需登入?
是(頁面本身);rag-local 兩端點無需 auth(單獨可呼叫)。

## 未確認事項
- rag search 回應 `results[]` 單筆完整欄位(僅知前端讀 `.post`,post 為帖子物件;服務 502 無法實測)。
- `source` 參數取值(僅見 `"manual"`)。
- 智能模式是否支援 partition 限制(前端未帶)。
