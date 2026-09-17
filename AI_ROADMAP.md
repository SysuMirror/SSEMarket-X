# AI Roadmap — SSEMarket-X

> **用途：** 只有在重構、架構升級、技術債處理或版本規劃時閱讀。
>
> **Last verified: 2026-09-03**
>
> 本檔是技術債的唯一 AI 維護來源。修完條目時改為 ✅、補完成日期並保留歷史；不要把完整清單複製回 `AI_ARCHITECTURE.md`。

**狀態：** 🔴 待處理｜🟡 進行中｜✅ 已完成

## 執行原則與順序

- 已完成的 TD-01、TD-04 是後續工作的基礎，不需重做。
- 安全網優先：TD-02、TD-03。
- 認證與環境一致性：TD-05、TD-06。
- 可觀測性可合併規劃：TD-08、TD-14。
- API 遷移後清理：TD-10、TD-13。
- 大檔拆分：TD-07；其前置 TD-04 已完成，實作時仍需先有足夠測試。
- 依賴整理與漸進 Model 改造：TD-09、TD-11。
- i18n：TD-12，先由產品範圍決定是否執行。
- B1（2026-09-02 底欄中央鈕＋工作台）新增債：TD-15 可獨立立即處理；TD-16 是分區相關功能（B3/B5/B8）的前置（名單已證實，僅餘常數抽離）；TD-17～TD-19 併入 B8；TD-20、TD-21 擇期。
- B2（2026-09-05 排行榜）新增債：TD-22 併入 B8。
- B4.2（2026-09-05 主頁分頁修補）決策新增：TD-23、TD-24 併入 B8；TD-19 已由 B3 解決。
- 批次編號現況：B4 打分專區、B5 課程專區、B6 簡历、B7 小秋（待後端穩定）、B8 refinement 收尾。

## 優先級：高

### TD-01 版本控制 ✅ 已完成（2026-08-31 確認）

- **問題：** 舊文件在 2026-08-30 的掛載／掃描視角下判定專案根目錄沒有 `.git`，因此曾被列為高風險。
- **證據：** 2026-08-31 實際專案為 Git work tree，位於 `main` 分支且已有 commit；舊證據已不符合現況。
- **影響：** 原先的無回復點與無法協作風險已解除；仍應維持小步 commit。
- **建議做法：** 已完成，不重新初始化。後續重構在現有 repository 中建立可回溯的基準與分段 commit。
- **前置依賴／執行順序：** 無；已是所有後續技術債工作的基礎。

### TD-02 AES 加密金鑰硬編碼於源碼 🔴

- **問題：** 登入、註冊、重設密碼的 AES key 寫在客戶端程式碼中，且重複出現。
- **證據：** `lib/core/api/auth_service.dart` 目前有 5 處字串 `'16bit secret key'`。
- **影響：** 金鑰隨源碼散佈，存在安全與維護風險；直接更換又會破壞與後端的解密協定。
- **建議做法：** 第一階段抽成單一私有常數以消除重複；長期改為建置期注入。任何實際 key 更換必須與後端同步。
- **前置依賴／執行順序：** 先補登入／註冊／重設密碼測試（TD-03），再抽常數；後端未配合前不要單方面換 key。

### TD-03 零有效測試 🔴

- **問題：** 專案沒有能保護現有產品行為的有效自動測試。
- **證據：** `test/widget_test.dart` 仍是 Flutter counter 範本，與本 App 無關，按現有 App 結構會失敗。
- **影響：** 約數萬行程式碼缺少回歸安全網，重構主要依賴手動驗證。
- **建議做法：** 移除或改寫假測試；先以領域 Service 為單位建立可注入／mock 的 HTTP 與 Storage 邊界，登入流程優先，再補 Router 與關鍵頁面測試。
- **前置依賴／執行順序：** 優先處理；是 TD-02、TD-05、TD-07 等高風險變更的前置安全網。

### TD-04 `api_service.dart` 門面遷移 ✅ 已完成（2026-08-30）

- **問題：** 原 1,420 行 god object 集中所有 API，且呼叫端透過欄位、建構子參數與過渡橋接相互耦合。
- **證據：** 31 個呼叫端已改為本地領域 Service；15 座過渡橋接及所有 `apiService` 參數／欄位已清除；`lib/` 搜尋 `ApiService` 無結果，門面檔不存在。
- **影響：** API 已按領域分離，新頁面可直接依賴小型無狀態 Service，後續測試與拆頁更可行。
- **建議做法：** 維持終態；不得恢復 god object 或只為相容舊程式碼重建門面。遷移過程史見 `AI_PROMPTS_API_SPLIT.md`。
- **前置依賴／執行順序：** 已完成；解除 TD-07、TD-10、TD-13 的原前置限制。

### TD-16 分區名稱無單一真相來源，顯示名／API 名雙軌 🔴

- **問題：** 分區字串（簡體中文）散落至少 4 個檔案各自維護，且同時存在兩張**方向相反**的顯示名↔API 名對照表；工作台的 10 個新分區名稱未經後端確認。
- **證據：** `partition_page.dart`（同時出現「课程」「课程专区」「课程交流」「学习交流」「学习解惑」等混雜字串）；`create_post_page.dart` 約 60–84 行（`_displayPartitions` 9 項＋`_displayToApiPartition` 顯示名→API 名：`'课程'→'课程交流'`、`'学习解惑'→'学习交流'`、`'随想随记'→'日常吐槽'`）；`search_page.dart` 57 行（反向表：`'学习交流': '学习解惑'`）；`workbench_page.dart`（10 個分區硬編碼，來源為產品清單，`sse_api_capture.md` 僅能證實「生活日常」「期末资料」等部分存在於後端，完整清單無佐證）。API 名「日常吐槽」僅見於 create_post 對照表。
- **影響：** B2–B4 接入分區功能時，任何一處改名或漏改都會讓 `browse` 的 `partition` 參數與後端不符（空列表或查錯區）；兩張反向對照表一旦不同步，發帖歸屬分區與搜索／顯示會互相矛盾；無法從單一位置得知合法分區集合。
- **建議做法：** 建立單一常數來源（如 `core/constants/partitions.dart`）定義 API 名＋顯示名對照，四處改引用並刪除手工對照表；工作台 10 分區名單已由 `docs/site/partition.md` 證實與後端一致（2026-09-05，含 key/icon/描述），僅餘常數抽離工作。
- **前置依賴／執行順序：** 名單確認依賴網頁端補抓或後端文件；常數抽離本身無前置、可先做。是 B2（排行榜）、B4（分區入口接入）的前置。

## 優先級：中

### TD-05 無 401 處理／token 自動刷新 🔴

- **問題：** REST Service 沒有統一處理 401，也沒有使用 refreshToken 自動更新 access token。
- **證據：** `lib/core/api/` 沒有 `statusCode == 401` 分支；refreshToken 的目前唯一消費端是年度報告 WebView。`sse_api_capture.md` 記載 JWT 約 7 天有效，並包含 `/api/auth/refresh` 規格。
- **影響：** token 過期後 Service 常回 `null`／空列表／`false`，UI 表現為空頁面而不會登出。
- **建議做法：** 設計集中式 response／auth 協調層：攔截 401、以 refreshToken 嘗試刷新、更新 StorageService；刷新失敗時呼叫 `StorageService.logout()`。需處理並發請求只刷新一次。
- **前置依賴／執行順序：** 先補認證與 API 測試（TD-03），並依 `sse_api_capture.md` 重新確認 refresh token 是否一次性及失敗語義。

### TD-06 網域散落三處硬編碼 🔴

- **問題：** REST、頭像上傳與 WebSocket 沒有共用同一環境設定來源。
- **證據：** `api_config.dart` 的 REST baseUrl、`user_service.dart` 的 uploadPhoto 完整 URL、`websocket_service.dart` 的 WSS URL 各自寫死。
- **影響：** 更換網域或 dev／prod 環境時可能只改到部分功能。
- **建議做法：** 先讓三處統一由 `ApiConfig` 衍生，再以 `--dart-define` 支援環境切換；明確處理 `https` → `wss` 與 path 組合。
- **前置依賴／執行順序：** 可在 TD-03 後獨立完成；若與 TD-05 都引入共用 client/config，先共同定義邊界以免重做。

### TD-07 巨型檔案待拆分 🔴

- **問題：** 多個頁面／渲染器承擔過多責任。
- **證據：** 2026-09-03 行數：`post_detail_page.dart` 1,336、`latex_markdown.dart` 1,156、`index_page.dart` 1,124（B1 +50）、`browse_history_page.dart` 1,022。
- **影響：** 閱讀與修改成本高、merge 衝突集中、局部變更容易產生跨區域回歸。
- **建議做法：** 先拆 `post_detail_page` 的詳情／留言／評分區，再拆 `index_page` 的響應式 layout 與 detail navigation；每次只拆一個責任並保持外部行為不變。Markdown 與瀏覽歷史另開獨立計畫。
- **前置依賴／執行順序：** TD-04 已完成；實作前先補對應流程測試（TD-03）。建議順序：post detail → index page → browse history／Markdown。

### TD-08 `print()` 40 處，無統一 logger 🔴

- **問題：** 記錄輸出分散，沒有一致的 level、格式與導出策略。
- **證據：** 2026-08-31 在 `lib/` 搜尋到 40 個 `print(` 呼叫。
- **影響：** release 問題難追蹤，敏感資料與噪音也缺乏集中控制。
- **建議做法：** 選擇 logger 套件或建立小型分級 wrapper，定義 debug／info／warning／error 與敏感資料遮蔽，再逐處替換並人工覆核。
- **前置依賴／執行順序：** 與 TD-14 一起規劃介面；不要先做無語義的一次性字串替換。

### TD-09 重複依賴：兩套 Markdown 庫 🔴

- **問題：** `flutter_markdown` 與 `markdown_widget` 同時存在。
- **證據：** `pubspec.yaml` 同時依賴兩者；`latex_markdown.dart` 同時 import，`comment_input.dart`、`markdown_help_page.dart` 另使用 `flutter_markdown`。
- **影響：** 增加套件體積、升級面與樣式不一致風險。
- **建議做法：** 先列出兩套庫各自支援的語法、LaTeX、圖片、選取與 compact mode，再以實際功能覆蓋選定保留者，逐頁遷移後移除另一依賴。
- **前置依賴／執行順序：** 需先建立 Markdown 視覺／解析回歸案例；可與 `latex_markdown.dart` 拆分同一方案設計，但不要同時無測試地大改。

### TD-10 同名 `NoticeService` 造成 import 陷阱 🟡

- **問題：** 本地未讀狀態 Service 與 REST 通知 Service 同名。
- **證據：** `core/services/notice_service.dart` 與 `core/api/notice_service.dart` 都定義 `NoticeService`；`notice_page.dart`、`index_page.dart`、`side_menu.dart` 需使用 `as api_notice`。
- **影響：** import 容易選錯，名稱無法表達物件責任，新增維護者需記住 prefix 慣例。
- **建議做法：** 將 API 版改為 `NoticeApiService`，或將本地版改為 `UnreadBadgeService`，一次性更新引用並移除不必要的 prefix。
- **前置依賴／執行順序：** TD-04 已完成。改名前先以搜尋列出所有 import、型別與建構處；完成後跑通知列表、已讀與 badge 驗證。

### TD-15 啟動期重複 user 請求（B1 副作用）🔴

- **問題：** `CreatePostPage` 常駐 IndexedStack 後，`initState` 的 `_loadUser()` 在 App 啟動即發 `getUserInfo`＋`getDetailedUserInfo`，與 `IndexPage._refreshUserInfo()` 的啟動請求完全重複（開機共 4 次 user 請求）。
- **證據：** `create_post_page.dart` 88 行 `initState→_loadUser()`（147、151 行兩請求）；`index_page.dart` 219–253 行同一對請求並回寫 StorageService；`_loadUser()` 為快取先行（先讀 StorageService 再補 API），故重複無 UX 必要。
- **影響：** 啟動多餘網路開銷；兩處獨立的用戶資料拉取邏輯，未來修改需記得改兩處，易漏。
- **建議做法：** 方案 A——`_loadUser()` 延後至頁面首次成為激活態（掛進 `didUpdateWidget` 既有的首次激活分支，加 `_userLoaded` 旗標防重複，模式同 `_draftLoaded`；`initState` 內 `isActive==true` 路徑亦需覆蓋）。不改 `_loadUser` 內部、不動 `_loadDraft`／`fromRatingPage`。根治（共用資料 notifier）屬方案 C，待狀態管理決策，暫緩。
- **前置依賴／執行順序：** 無前置，改動極小；驗證須完整重啟（禁熱重載）＋草稿保留＋首次進入發帖頁資料正常。

## 優先級：低

### TD-11 Model 手寫解析，無 codegen 🔴

- **問題：** `core/models/` 依賴手寫 `fromDynamic`、`copyWith` 與 `toJson`。
- **證據：** 現有 Model 均未使用 json_serializable／freezed；後端欄位又需要多 key fallback。
- **影響：** 樣板碼多、欄位新增容易漏改；但直接 codegen 也可能破壞既有容錯。
- **建議做法：** 新 Model 或被功能修改的 Model 再漸進導入 codegen；先設計自訂 converter／fallback 策略，不進行全專案一次性重寫。
- **前置依賴／執行順序：** 先有解析 fixture 測試（TD-03）；優先處理常變動且 API 規格較穩定的 Model。

### TD-12 硬編碼中文字串，無 i18n 🔴

- **問題：** UI 字串直接寫在大量 Dart 檔案中，沒有本地化架構。
- **證據：** 原 2026-08-30 掃描為 81+ 個檔案包含硬編碼中文字串；目前專案仍未配置 ARB／Flutter gen-l10n。
- **影響：** 若支援多語，翻譯、文案一致性與語系測試成本會快速上升。
- **建議做法：** 先由產品決定是否只服務中文市場；若需要多語，及早導入 ARB 與 gen-l10n，按功能域漸進搬移。
- **前置依賴／執行順序：** 產品決策是前置；若確定只做中文，可明確降級或關閉此項，而不是長期保持模糊狀態。

### TD-13 死碼與殘留檔案 🔴

- **問題：** repository 仍包含不應作為有效配置／測試使用的殘留檔。
- **證據：** 根目錄仍有 `pubspec_overrides.yaml.bak`；`test/widget_test.dart` 仍是無效 counter 範本。2026-08-30 舊技術債記錄所稱 `login_page.dart` 106–109 舊導航註解目前已不存在，該部分證據已過時。
- **影響：** AI 或開發者可能誤把備份檔當正式設定，或誤認範本測試提供了安全網。
- **建議做法：** 先確認 OpenHarmony 的正式依賴覆蓋來源，再決定備份檔要改名、文件化或移除；counter 測試應由 TD-03 的有效測試取代。
- **前置依賴／執行順序：** API 門面清理前置 TD-04 已完成；測試檔處理併入 TD-03，備份檔需先確認平台建置流程。

### TD-14 無集中式錯誤／當機回報 🔴

- **問題：** 沒有全域 Flutter error、async zone error 與 release crash reporting 管線。
- **證據：** 現有啟動流程未配置 `FlutterError.onError`、`runZonedGuarded` 或 Sentry／Crashlytics 類服務。
- **影響：** release 問題主要依賴使用者口述，難以取得 stack trace、版本與發生頻率。
- **建議做法：** 設計全域錯誤入口，串接選定的 crash reporting 服務，定義環境、版本、使用者隱私與敏感資料遮蔽；與 TD-08 logger 共用事件格式。
- **前置依賴／執行順序：** 先決定服務與隱私政策；與 TD-08 一起設計，先在非 production 環境驗證。

### TD-17 B1 遺留死代碼 🔴（排 B8）

- **問題：** 發帖入口移至底欄中央鈕後，HomePage 的發帖按鈕參數與回呼成為不可達代碼；另有一處永不可達的過期 placeholder 文案。
- **證據：** `home_page.dart` 29、35、430、768 行 `showHeaderAddButton`（唯一呼叫者 `index_page.dart` 768 行恆傳 `false`）、793 行 `onAddPostTap` 回呼不可達；`index_page.dart` 908–911 行 `_buildPlaceholderContent` case 5 仍寫「选择一个联系人开始聊天」（tab 5 已是工作台，且桌面側欄無 index 5 入口，永不可達）。
- **影響：** 誤導維護者以為 header「+」仍是有效入口；無效分支增加閱讀與修改成本。
- **建議做法：** B4 時移除 `showHeaderAddButton`／`onAddPostTap` 及其內部分支，並刪 case 5 過期文案；移除前以 grep 確認無其他呼叫者。
- **前置依賴／執行順序：** 無（已確認唯一呼叫者）；依 B1 任務圍欄保留至 B4。

### TD-18 工作台底部 padding 疑似雙計 🔴（排 B8，純視覺）

- **問題：** `extendBody: true` 時 `MediaQuery.padding.bottom` 已含底欄高度，工作台又手動加 `kBottomNavigationBarHeight`，列表尾端留白偏多。
- **證據：** `workbench_page.dart` 70–71 行 `bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight`；`index_page.dart` 285 行 `extendBody: true`。
- **影響：** 純視覺（尾端空白略多），無功能影響。
- **建議做法：** B8 refinement 時於毛玻璃開／關兩狀態實測留白，改為單一來源（僅用 MediaQuery 或僅用常數）。
- **前置依賴／執行順序：** 無。

### TD-19 工作台入口以中文字串作路由鍵 ✅ 已完成（2026-09-05）

- **問題：** 入口點擊行為以 UI 顯示字串分派（`switch (entry.name)`、`case '打分'`），字串同時承擔顯示文案與功能識別兩職。
- **證據：** `workbench_page.dart` 46–66 行 `_onEntryTap` 以 `entry.name` 字串 switch；入口清單 24–44 行同以字串定義。
- **影響：** 僅改文案（如「商城」→「商店」）會靜默落入 default 佔位分支，導航壞掉且不易察覺。
- **建議做法：** `_WorkbenchEntry` 增加列舉／id 欄位，switch 改用列舉；可與 TD-16 分區常數化同批處理。
- **前置依賴／執行順序：** 無；建議併入 TD-16 或 B8。
- **狀態更新（2026-09-05）：** 已由 B3（commit `e528884`）解決 — 工作台重寫為 `_EntryKind` 枚舉分派（ranking/score/shop/externalLink/partition/placeholder），中文字串不再承擔功能識別。

### TD-20 手機／桌面 IndexedStack 內嵌方式不一致 🔴

- **問題：** 同一 `_buildBodyForTab` 產物，桌面每個 tab 包在獨立 `Navigator`（per-tab 返回堆疊），手機版 children 為裸 widget 不包 Navigator。
- **證據：** `index_page.dart` 623–637、734–747 行（桌面 `List.generate` 包 `Navigator`，用 `_navigatorKeys`）vs 289–304 行（手機直接 `_buildBodyForTab`，未包）。
- **影響：** 兩版型的頁面內導航行為不同（桌面 tab 內 push 保留於該 tab；手機 push 走根 Navigator），維護者需記住差異；未來統一行為時需兩處同步修改。
- **建議做法：** 先以人工測試確認手機版行為是否為預期設計並記錄結論；若要統一，讓手機 children 亦包 Navigator（`_navigatorKeys` 已有 7 個 key 可復用）。
- **前置依賴／執行順序：** 屬行為決策，先確認再動；實作前建議有 TD-03 安全網。

### TD-21 文檔引用與版控狀態不一致 🔴

- **問題：** 維護文檔間的引用指向已刪除檔案；根目錄 AI 維護文檔本身未納入版控。
- **證據：** `PROJECT_GUIDE.md`、`TECH_DEBT.md`、`AI_PROMPTS_API_SPLIT.md` 已於工作樹刪除（git 狀態 `D`，未 commit），但本檔 53 行仍引用 `AI_PROMPTS_API_SPLIT.md`；`AI_ARCHITECTURE.md`／`AI_ROADMAP.md`／`AI_TROUBLESHOOTING.md`／`AI_PROMPTS_SITE_CRAWL.md`／`B1_完成報告.md` 均為 untracked（`??`）。
- **影響：** 依引用找文件會撲空；文檔無版本歷史，誤改誤刪無法回溯；大量刪檔未 commit 與 TD-01「小步 commit」原則不一致。
- **建議做法：** 決定文檔治理策略：根目錄 AI_*.md 納入 git；commit 文檔刪除動作；清理本檔失效引用（本條完成時一併處理）。
- **前置依賴／執行順序：** 無。

### TD-22 排行榜頁兩 Tab UI 結構近複製 🔴（排 B8）

- **問題：** `_PostRankingTab` 與 `_UserRankingTab` 兩個 State 類各自實作近乎相同的載入流程、頒獎台與清單渲染（約 200 行重複），`ranking_page.dart` 因此達 864 行。
- **證據：** `lib/views/ranking/ranking_page.dart`（2026-09-05 B2，commit `2f5bb18`）：`_PostRankingTabState` 與 `_UserRankingTabState` 各有一套 `_load`／`_buildPodium`／`_buildPodiumCard`／`_buildListRows`，結構相同，僅條目型別（PostRankingEntry／UserRankingEntry）與卡片內容欄位不同；骨架屏、空狀態、錯誤狀態已共用（`_RankingSkeleton` 等）。
- **影響：** 樣式或榜單行為調整需同步修改兩處，漏改會造成優質榜／用戶榜顯示不一致；檔案過長增加閱讀與 review 成本。
- **建議做法：** 抽出共用的榜單骨架（載入狀態機＋頒獎台＋第 4 名起清單佈局），兩 Tab 以注入方式提供條目轉換（副標文案、徽章色、卡面欄位、點擊導航）；重構時保持外部行為不變。
- **前置依賴／執行順序：** 無；併入 B8 refinement 批次（TD-19 已由 B3 解決），重構後需人工回歸兩榜的顯示、切換快取與導航。

### TD-23 主頁分頁體感優化未對齊官網 🔴（排 B8）

- **問題：** 主頁／分區頁分頁為「恆定 limit 10、到底才觸發載入、無總數真相、無新帖輪詢」，與官網體感有差距。
- **證據：** `home_page.dart` 67 行 `_pageSize = 10`、541–544 行 itemBuilder 觸底觸發；docs/site/home.md「分頁」節：官網續載 limit 15、IntersectionObserver rootMargin 240px 預載、getPostNum 的 `Postcount` 為總數真相（browse 回應 `total` 恆 0 不可用）、每 60 秒 limit:20 輪詢新帖差集提示。B4.2 修補（2026-09-05）刻意「取三捨三」只修計數 bug，此四項留本條。
- **影響：** 快到底時可見 loading 停頓（無預載）；長時間停留無新帖感知（無輪詢）；「已載入/總數」無法精確對帳。
- **建議做法：** B8 時逐項評估採用：續載 limit 15、觸底前 240px 預載、以 Postcount 交叉驗證 hasMore、60 秒新帖輪詢（App 已有切 tab 靜默刷新＋新帖提示條，輪詢與其協調避免重複）。
- **前置依賴／執行順序：** B4.2（置頂分離與計數純淨化）先行完成，避免兩次改動同一計數邏輯。

### TD-24 工作台視覺未對齊官網 🔴（排 B8）

- **問題：** 工作台入口卡為通用 Material 圖標＋名稱，缺官網的分區 icon＋描述文案與動態 apps 客製色。
- **證據：** `workbench_page.dart` 入口卡僅 Icon＋Text；docs/site/partition.md 十大分區各有 tabler icon 與描述（如学习交流「知识碰撞，学术思辨。」）；docs/site/workbench.md 分區卡含 icon＋描述、應用卡支援後端 colorBg/colorFg。B3 因 tabler/ph 圖標在 App 無對應資源且 colorBg/colorFg 實測樣本為空，刻意未渲染（已埋 debugPrint 收集非空值）。
- **影響：** 純視覺差距，無功能影響。
- **建議做法：** B8 時：分區描述文字可直接採用官網文案；icon 以 Material 近似或引入 tabler 資源方案（需評估 package/資產成本，不得未評估直接加包）；colorBg/colorFg 依 B3 收集到的非空值樣本確認格式後再支援。
- **前置依賴／執行順序：** colorBg/colorFg 支援依賴實機收集數據（B3 debugPrint）。

## 已完成歷史記錄

| 項目 | 完成／確認日 | 結果 |
|---|---|---|
| TD-01 版本控制 | 2026-08-31 確認 | repository 已存在，位於 `main` 且已有 commit；修正舊文件的掛載視角誤判 |
| TD-04 門面遷移與刪除 | 2026-08-30 | 31 個呼叫端遷移、15 座橋接清除、門面刪除；當時 analyze 220 issues／0 error、debug APK 成功 |
| API 層拆分 | 2026-08-30 | 原 1,420 行 god object 拆成 ApiClient／ApiConfig／ApiTypes + 七個領域 Service |
| 登入故障排查 | 2026-08-30 | 根因是 Hot Reload 殘留；完整重啟恢復，經驗移至 `AI_TROUBLESHOOTING.md` |
| 第一版架構與技術債文件 | 2026-08-30 | 建立原始整合式文件，後於 2026-08-31 拆分為 Architecture／Troubleshooting／Roadmap |

## 維護規則

- 新技術債沿用 `TD-15` 起的連續編號。
- 修復後改狀態、補完成日期與驗證，不刪條目。
- 架構現況只更新 `AI_ARCHITECTURE.md`；故障排查只更新 `AI_TROUBLESHOOTING.md`。
- 若某項只是已知限制的排查方法，Roadmap 保留改善方案，Troubleshooting 只保留症狀與當下可行處理，避免重複整段維護。
