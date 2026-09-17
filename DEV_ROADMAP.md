# SSEMarket-X 任務路線圖(開發者指南)

> **Last updated: 2026-09-08**
> 本文檔是移動端 App(Flutter)對齊官網 ssemarket.cn 的完整任務清單:要做的功能、要修的 bug、對應的 API 與技術債。

## 文檔地圖(查資料先看這裡)

| 文檔 | 內容 | 何時查 |
|---|---|---|
| **`docs/site/INDEX.md`** | **官網逆向總覽,一切官網問題的入口**:§1 技術棧摘要+共用前端基建(回應包絡三態、401→refresh 單飛機制、token 儲存)、§2 完整路由樹+PC/Mobile 導航結構、§3 API 端點總表(按領域,含 method/參數/auth/實測狀態)、§6 各接口分頁慣例對照、§7 全部頁面文檔清單 | 接新 API 前(§3)、查頁面歸屬(§2/§7)、對分頁語義(§6) |
| `docs/site/<頁面>.md` | 單頁規格:UI 結構、API 呼叫、分頁、導向、空/錯誤狀態文案 | 做該頁功能時 |
| `AI_ROADMAP.md` | 技術債詳細證據與建議做法(TD 編號,唯一 AI 維護來源) | 處理技術債時 |
| `sse_api_capture.md` | 2026-08-25 Playwright 抓包紀錄(150 項,較舊) | docs/site/ 查不到實測樣本時 |

**接任何新 API 前必讀 — INDEX.md §1「回應包絡三態」**:①`{code,data,msg}`(多數)、②**裸陣列/裸物件**(browse、getProducts、resume/list、showPcomments、rating 三個 list、calculateHeat、getNoticeNum、userProfilePosts、workbench/apps)、③`{ok:…}`(rag-local)/`{code:0,…}`(agent)。解析寫錯形態 = 靜默空列表(B3/B4 實際踩過)。優先級:docs/site/ > sse_api_capture.md;程式碼與文檔衝突時以程式碼為準並回報。

---

## 0. 專案現況速覽

| 項目 | 狀態 |
|---|---|
| 技術棧 | Flutter(無狀態管理框架,setState 為主)、http、SharedPreferences、WebSocket、url_launcher、webview_flutter |
| 架構 | `core/api/` 按領域拆分 Service(PostService/UserService/…)+ `core/models/` 手寫容錯 model;禁止重建 god-object ApiService(TD-04) |
| 版控 | git repo 存在(main 分支);節奏:每 Batch 一個 commit |
| 測試 | ❌ 無有效測試(TD-03),驗證靠 flutter analyze + 人工清單 |
| 驗證鐵律 | 結構性修改後必須**停 App + flutter clean + 全新執行**(熱重載會產生假故障);analyze 基準約 225 條 / 0 error |

### 已完成並驗收(Batch 進度)

| Batch | 內容 | Commit |
|---|---|---|
| B1/B1.1 | 移動端底欄 5 槽(首頁·消息·中央發帖鈕·工作台·我的),中央鈕騎邊 docked 造型;嵌入式發帖 tab | (未單獨 commit,混入後續) |
| B2 | 排行榜頁:優質榜/用户榜雙 Tab、頒獎台、postRanking/userRanking 接入 | `2f5bb18` |
| B3 | 工作台接入:8 內建入口 + 動態 apps API(匿名)+ 全部分區真導航 | `e528884` |
| B4 | 打分專區對齊官網:rating/* 新數據源、分類 pill、搜尋、讚接口修正 | `165dacb` |
| B4.2 | 主頁/分區頁分頁修復:置頂帖(pinned)與分頁計數分離,hasMore 改 >= | `1bae49d` |
| B4.3 | 打分頁 Skeleton 永久載入修復(_isLoading 初始值+try/finally+15s timeout)— 已 review,待實機驗證 | `4324d95` |
| B4.4 | 外連修復(Android 11+ queries 宣告+_launchExternal 三級策略)— 已 review,待實機驗證 | `3ae2ba7` |
| B6 | 簡历模組:ResumeService 6 端點+列表/上傳/詳情/編輯/刪除/下載(file_picker 11.0.3;detail 裸物件容錯)— 已 review,合併 main,待實機驗證 | `a7828c1` |
| TD-22 | 排行榜雙 Tab 去重構(_RankingTabState 抽象基類,864→773 行,行為零變更)— 已 review,合併 main,待實機驗證 | `a413d85` |

> 另:`e59e73c` = 分工前快照(2026-09-08)。

### 待驗收 / 進行中

- **實機驗證佇列(已 review+合併,等人工清單)**:B4.3/B4.4(打分出列表、斷網 Toast、五外連)、B6(簡历 a-g:上傳 PDF 全流程/下載開瀏覽器/isOwner 編輯刪除/雙 tab/搜尋)、TD-22(兩榜行為對照重構前)。全部 clean+全新執行。
- **下一批**:B → TD-16 分區常數統一;A → B7 小秋(阻塞中,等後端恢復)。

---

## 0.5 雙人分工(2026-09-08 起)

**策略**:按頁面模組劃分所有權;git 用分支(`batch/<編號>-<模組>`),完成報告通過審核後合回 main。開工前先 pull main。

### 開發者 A — 打分與內容域(score / course / resume)

B4.3(Skeleton 修補)→ B6 簡历模組 → 自模組補測試(TD-03 滾動)。
Own:score_page、post_service、partition_page、全部新 resume 檔案。
**B5 課程專區已凍結(2026-09-08 用戶決定)**:入口維持現狀(工作台「课程专区」佔位頁、分區格走普通分區流),解凍時恢復。

### 開發者 B — 工作台/排行榜/主頁域(workbench / ranking / home)

B4.4(外連 queries 修補)→ TD-22 排行榜去重構 → TD-17 死代碼 + TD-15 → TD-16 分區常數(原閘門 B5 已凍結,隨時可排)→ 【B6 合入後】TD-18/24 + TD-23。
Own:workbench_page、ranking_page、home_page、create_post_page、AndroidManifest。

### 衝突拆解規則(審合強制)

1. workbench_page:A 只准改 `_frequentEntries` 清單與 `_onEntryTap` 分派(佔位→真頁,~5 行);B 的任務(B4.4/TD-18/24)不得觸碰這兩處。
2. 時序閘門:TD-18/24/TD-23 等 B6 合入(TD-16 原閘門 B5 已凍結,解除)。B 的前半程(B4.4→TD-22→TD-17/15→TD-16)與 A 零檔案交集,可立即並行。
3. post_service:A 全程所有;TD-23(B)需加 getPostNum 時排在 B6 之後,避開 A 的活躍期。
4. DEV_ROADMAP.md §0 表格由任務完成者更新,commit 訊息注明 `Batch X (A/B)`。

---

## 1. 功能路線圖(按優先級)

### B4.3 + B4.4 — 緊急修補(先於一切)

| # | 任務 | Root cause | 修法 |
|---|---|---|---|
| 1 | 打分頁永久 Skeleton | `score_page.dart` 44 行 `_isLoading=true` 初始值 vs 86 行守衛 `if (_isLoading \|\| _isLoadingMore) return;` — initState 首次呼叫被守衛擋下,請求從未發出 | 初始值改 false;await 段 try/finally 保證復位;三支 rating API 加 `.timeout(15s)` |
| 2 | 外連全部「无法打开链接」 | url_launcher 的 `canLaunchUrl` 在 Android 11+ 受 package visibility 限制,Manifest 未宣告 `<queries>` 必回 false | `AndroidManifest.xml` 加 https scheme queries 宣告;代碼層 launchUrl 失敗 fallback externalApplication 直開 |

### B5 — 課程專區頁(`/course` 對齊)——❄️ 已凍結(2026-09-08)

**狀態**:暫緩,不排期。工作台「课程专区」入口維持佔位頁、分區格「课程专区」維持普通分區流 — 這是凍結的預期狀態,不是缺陷。解凍時按下述規格恢復。
**注意**:解凍後 TD-16(分區常數)若已完成,本頁應改用統一常數;兩個「课程专区」入口(工作台常用 + 分區格)都要切到新頁面。
**規格**(docs/site/course.md):老師下拉選單(`getTags?type=course` → `data.tags[{TagID,Name}]`,空值=全部)→ 以 `tag=老師名` 查 `browse(partition=课程专区)`;帖子流分頁同主頁(B4.2 已修好,復用 `GetPostsResult` 模式);換老師 = 清列表 offset 歸零。
**注意**:官網分區卡「课程专区」也是導向此頁而非普通分區流 — B5 完成後,工作台常用區的「课程专区」入口與全部分區格裡的「课程专区」**都**要切到這個新頁面。

### B6 — 簡历模組(最大件新功能)

**做甚麼**:工作台「简历」入口(現為佔位)→ 完整簡历專區。
**規格**(docs/site/resume.md、resume-upload.md、resume-detail.md):列表(搜尋 searchsort=home / 我的 searchsort=my)、上傳(PDF,FormData)、詳情(pdf.js 預覽 → App 端需評估:webview_flutter 預覽 vs 下載後系統查看器)、刪除、下載。
**API**(5 支,POST+Bearer):`/api/auth/resume/list|detail|update|delete|download`(sse_api_capture.md #120–125)。
**建議**:新建 `ResumeService` + `ResumeModel`;PDF 預覽方案先做技術評估再動工(可能需拆子批次)。

### B7 — 智能小秋 AI 對話(⚠️ 等後端)

**做甚麼**:工作台「小秋」入口(現為佔位)→ SSE 串流對話頁 + AI 草稿卡(一鍵發帖/上架)。
**規格**(docs/site/smart-xiaoqiu.md):bootstrap(task/sse 串流,事件 content/error/post_draft/rag_context)、會話管理、草稿卡發布復用既有 post/postProduct 接口。
**阻塞中**:抓包時後端 502(服務異常),事件格式未線上驗證。**觸發條件:官網智能小秋恢復可用**。Dart 端 SSE 解析需自建或評估套件(http 串流 + 手動解析,官網文檔有完整事件格式可依)。

### B8 — Refinement 收尾批(對應 AI_ROADMAP TD)

| TD | 任務 | 摘要 |
|---|---|---|
| TD-16 | 分區常數統一 | 十大分區名單已證實(docs/site/partition.md);把散落 4 檔的分區字串與兩張反向對照表收斂到 `core/constants/partitions.dart` 單一真相源 |
| TD-17 | B1 死代碼清理 | 移除 home_page 的 `showHeaderAddButton`/`onAddPostTap`(唯一呼叫者恆傳 false)、index_page `_buildPlaceholderContent` case 5 過期文案 |
| TD-18 | 工作台底部 padding 雙計 | extendBody 下 MediaQuery.padding 已含底欄高度,擇一來源 |
| TD-22 | 排行榜雙 Tab 去重 | `_PostRankingTab`/`_UserRankingTab` ~200 行近複製,抽共用榜單骨架(載入狀態機+頒獎台+清單),條目轉換注入 |
| TD-23 | 分頁體感優化 | 對齊官網:續載 limit 15、觸底前 240px 預載、getPostNum Postcount 總數真相、60 秒新帖輪詢(B4.2 已修計數,本條純體感) |
| TD-24 | 工作台視覺對齊 | 分區卡加官網 icon+描述文案;動態 apps colorBg/colorFg 支援(依 B3 debugPrint 收集到的非空值格式) |
| (新) | PostModel 補 isPinned 欄位 | B4.2 快取保守處理的根源;補欄位後快取可區分置頂,消滅一次性跳帖副作用 |

### 獨立小修補(隨時可插隊)

- **TD-15**:CreatePostPage 常駐 IndexedStack 後啟動多發 2 次重複 user 請求 — `_loadUser()` 延後至首次激活(didUpdateWidget 既有分支 + `_userLoaded` 旗標)。

---

## 2. 技術債與風險(平行線,詳見 AI_ROADMAP.md)

### 高優先(建議 B6 前啟動)

| TD | 問題 | 為甚麼急 |
|---|---|---|
| TD-03 | 零有效測試 | 每批全靠人工回歸;B4.3 的 Skeleton bug 正是「無測試+無實機執行」漏掉的執行路徑類缺陷。建議先補 Service 層 mock 測試(登入/評分/分頁) |
| TD-02 | AES key 硬編碼 5 處 | 安全債;先抽單一常數,換 key 需與後端同步 |

### 中低優先(按 Roadmap 排期)

TD-05(401/token 刷新,過期=靜默空頁面)、TD-06(域名散落三處)、TD-07(巨型檔拆分:post_detail 1336 行/index_page 1124 行)、TD-08(print 40 處無 logger)、TD-09(兩套 Markdown 庫)、TD-10(同名 NoticeService)、TD-11(Model codegen)、TD-12(i18n)、TD-13(死檔殘留)、TD-14(crash reporting)、TD-20(手機/桌面 IndexedStack 行為差異)、TD-21(AI 文檔未入版控)。

### 已知開放問題(待數據)

1. **後端 offset 語義**:browse 的 offset 是否把置頂帖計入 — B4.2 實機若跳帖需校準(人工驗證:有置頂分區連續翻頁看 PostID 連續性)
2. **動態 apps 數據收集**:route 型 target 值、非空 colorBg/colorFg(B3 已埋 debugPrint,跑一次抄回)— TD-24 前置
3. **後端隱私問題**:`rating/post/list` 回應的 `userTelephone` 未遮蔽(其他接口都是 `961****4135` 格式)— 如後端可管,值得回報
4. **打分人評數**:Σstars 與 raterCount 實機是否一致(B4 報告項)

---

## 3. 開發工作流(本專案的協作規則)

1. **每批指令**由規劃者產出(閱讀清單→背景→目標→已確認需求→不要做→API 規格→驗證→報告格式),交 Coding Agent 執行
2. **驗證鐵律**:flutter analyze 0 error + 停 App + flutter clean + 全新執行 + 人工清單。**Skeleton 類執行路徑 bug 只有實機能攔住** — 人工清單必須真的跑
3. **Review**:Agent 報告需人工核對程式碼(曾出現誤報:B4 稱 PostCard:369 反斜線路徑 bug,實際不存在)
4. **每 Batch 一個 commit**,訊息注明編號
5. API 問題先查 `docs/site/INDEX.md`(§3 端點總表、§1 回應包絡三態),再查對應頁面 md;`sse_api_capture.md` 僅補實測樣本。程式碼與文檔衝突時以程式碼為準並回報
6. 新頁面/新 Service 按領域放置;Model 容錯解析參考 `ranking_model.dart` 模式(多 key fallback + _readInt/_readString 系列)
