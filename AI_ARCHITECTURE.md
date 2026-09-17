# AI Architecture — SSEMarket-X

> **用途：** 每次新聊天室開始開發前預設閱讀。本文件只描述目前程式碼實際如何運作；故障排查見 `AI_TROUBLESHOOTING.md`，重構與技術債見 `AI_ROADMAP.md`。
>
> **Last verified: 2026-08-31**（依目前 Dart 程式碼、`pubspec.yaml`、Router 與 Config 核對）

## 文件優先級

**實際程式碼 > pubspec / Router / Config > `sse_api_capture.md` > AI 文件。**

如果文件內容與實際程式碼不一致，以實際程式碼為準，並同步更新文件。

當任務涉及新增或修改 API、Request、Response、Model、認證接口或後端行為時，應主動查閱 `sse_api_capture.md` 中的對應接口。該文件保留為獨立 API 規格，不在本文件複製端點明細。

## 1. Project Overview

SSEMarket-X 是 `ssemarket.cn`（軟工集市）的 Flutter 多平台用戶端，提供校園論壇、打分帖、二手商城、通知、即時聊天、個人資料與年度報告等功能。

- 套件名稱：`sse_market_x`
- 版本：`0.6.6+17`
- Dart SDK：`>=3.4.0 <4.0.0`
- Flutter：`>=3.22.0`
- 平台目錄：Android、iOS、Web、Windows、macOS、Linux、OpenHarmony（`ohos/`）
- OpenHarmony 依賴覆蓋參考：根目錄 `pubspec_overrides.yaml.bak`

## 2. 技術棧

| 類別 | 目前使用方式 |
|---|---|
| UI | Flutter Material、`StatefulWidget`、`setState` |
| 路由 | `go_router` 負責頂層路由；頁內仍使用 Flutter `Navigator` |
| REST | `http`；各領域 Service 直接建立 URI、headers 並解析回應 |
| 認證／加密 | Bearer JWT；`encrypt` + `crypto` 實作登入密碼 AES-CBC 加密 |
| 本地儲存 | `shared_preferences` |
| 即時聊天 | `web_socket_channel` |
| 響應式狀態 | `setState`、`ValueNotifier`、broadcast `Stream`，沒有 Provider／Riverpod／BLoC |
| Markdown／LaTeX | `flutter_markdown`、`markdown_widget`、`flutter_math_fork` |
| WebView | `webview_flutter`，用於年度報告 |
| 圖片／媒體 | `cached_network_image`、`extended_image`、`image_picker`、`saver_gallery` |

## 3. Directory Structure

```text
lib/
├── main.dart                         # App 入口與全域服務初始化
├── core/
│   ├── api/                          # REST 領域服務、ApiConfig、ApiClient、共用 API 型別
│   ├── models/                       # 手寫資料模型與 fromDynamic 解析
│   ├── router/app_router.dart        # GoRouter、登入 redirect、深連結
│   ├── services/                     # 本地單例服務、WebSocket、偏好與快取
│   └── utils/                        # 驗證、時間、等級、年度報告等純邏輯
├── shared/
│   ├── components/                   # 跨頁面 Widget，按用途分子目錄
│   └── theme/app_colors.dart         # 明暗主題與 BuildContext 顏色擴充
└── views/
    ├── auth/ chat/ home/ notice/
    ├── post/ profile/ ranking/ resume/    # 功能頁面
    ├── shop/ todo/ workbench/
    └── index_page.dart               # 響應式主殼、分頁與桌面詳情 Navigator
```

現有分層規則：

- `core/` 不放 Widget；放 API、Model、Router、本地服務與純邏輯。
- `views/` 放頁面級 Widget；只被單一功能使用的 UI 可留在該功能目錄。
- `shared/components/` 放跨頁面重用的 Widget，依既有子目錄分類。
- `core/models/` 目前不使用 code generation；解析需容忍後端 key 大小寫或命名差異。

## 4. Architecture Overview

```text
views/** + shared/components/**
        │  頁面本地建立無狀態領域 Service
        ▼
core/api/: Auth / User / Post / Comment / Shop / Notice / Chat / Workbench / Resume
        │  每個方法自行建立 Uri、headers、Bearer token、解析 JSON
        ▼
ApiClient（baseUrl、即時 token、目前使用者 phone）
        │
        ├── REST: https://ssemarket.cn/api
        └── StorageService（token、user、登入狀態）

平行狀態線：
StorageService.userNotifier ──► GoRouter redirect／個人資料 UI
WebSocketService Streams ─────► 聊天訊息、聯絡人、未讀數
本地 NoticeService Stream ───► 通知未讀 badge
```

七個 API Service 都是無狀態物件，可在頁面或元件中直接 `XxxService()` 建立；本地服務多採單例。

## 5. Application Startup Flow

`lib/main.dart` 的實際順序：

```text
main()
├── WidgetsFlutterBinding.ensureInitialized()
├── usePathUrlStrategy()
├── await StorageService().init()
├── await MediaCacheService().init()
├── await BlurEffectService().init()
├── await DesktopLayoutPreferenceService().init()
└── runApp(const MyApp())
    └── MaterialApp.router
        ├── lightTheme / darkTheme / ThemeMode.system
        ├── routerConfig: appRouter
        └── textScaler 限制在 0.85～1.15
```

`StorageService` 必須先初始化，因為 Router redirect 與 API Service 都會讀取它的登入狀態或 token。新增啟動期服務時，應依實際依賴順序 `await`，再呼叫 `runApp`。

## 6. Routing 與版面導航

### 6.1 頂層 GoRouter

`lib/core/router/app_router.dart` 定義 6 條路由：

| 路徑 | 內容 |
|---|---|
| `/login` | `LoginPage` |
| `/` | `IndexPage` |
| `/new` | 舊網址相容，redirect 至 `/` |
| `/new/postdetail/:id` | redirect 至 `/postdetail/:id` |
| `/postdetail/:id` | `PostDetailPage`；id 無法解析時顯示 `IndexPage` |
| `/annual-report` | `AnnualReportPage` |

Router 使用 `StorageService().userNotifier` 作為 `refreshListenable`：

- 未登入且目標不是 `/login`：轉到 `/login?redirect=<原網址>`。
- 已登入且位於 `/login`：回到 redirect 參數或 `/`。
- 其他情況放行。

### 6.2 `IndexPage` 響應式主殼

`IndexPage` 依可用寬度切換：

- `< 600`：手機版，4 個底部分頁：首頁、打分、消息、我的。
- `600～999`：桌面／平板雙欄版。
- `>= 1000`：桌面三欄版，側欄 + 內容列表／編輯區 + 詳情面板。
- 桌面側欄入口：首頁、新建、打分、閒置、消息；底部頭像另進入個人頁。
- 內部 index `5` 是舊 Chat 分頁保留槽，目前回傳空 `SizedBox`；不要把它當作有效功能入口。

### 6.3 三種 Navigator 並存

1. GoRouter：登入、首頁、深連結、年度報告等頂層路由。
2. `Navigator.push(MaterialPageRoute)`：註冊、重設密碼與一般頁面間導航。
3. `index_page.dart` 的 `_detailNavigatorKey`：桌面詳情面板的巢狀 Navigator，搭配 `_DetailNavigatorObserver`。

修改導航前先確認目標屬於 root、一般頁內或桌面詳情 Navigator。

## 7. Authentication

登入流程：

```text
LoginPage
└── AuthService.login(email, password)
    ├── AES-128-CBC 加密密碼
    └── POST /auth/login
        └── LoginResult(token, refreshToken)
            ├── AuthService.setToken(token)
            ├── UserService.getUserInfo() → GET /auth/info
            └── StorageService.setUser(...)
                ├── _isLoggedIn = true
                ├── userNotifier.value = user
                ├── 持久化 token／user／refreshToken／登入偏好
                └── GoRouter 自動 redirect 到首頁
```

密碼加密目前使用字串 `16bit secret key` 補齊為 16 bytes；IV 是該 key 的 SHA-256 hex 字串前 16 個字元所對應的 bytes。這是現行後端協定的一部分，修改前必須同步確認後端。

登入成功不直接呼叫 Navigator；導航由 `userNotifier` 觸發。App 啟動時，`StorageService.init()` 從 SharedPreferences 還原 token 與 user JSON；解析失敗會登出並清除狀態。

任何登入狀態變更必須透過：

- `StorageService.setUser(...)`
- `StorageService.logout()`

不要只直接寫 SharedPreferences，否則 Router 不會收到 `userNotifier` 更新。

目前沒有集中式 401 處理或 access token 自動刷新。`refreshToken` 目前只由年度報告 WebView 使用；相關未來改善見 `AI_ROADMAP.md`。

## 8. API Architecture

`lib/core/api/` 目前有 12 個檔案：

| 檔案 | 責任 |
|---|---|
| `api_config.dart` | `ApiConfig.baseUrl = 'https://ssemarket.cn/api'` |
| `api_client.dart` | 提供 baseUrl、即時讀取 StorageService token、取得目前使用者 phone |
| `api_types.dart` | `ApiResponseFormatError`、`GetPostsParams`、`RatingDetail` |
| `auth_service.dart` | 登入、驗證碼、註冊、重設密碼；定義 `LoginResult` |
| `user_service.dart` | 使用者資料、頭像上傳、個資更新、Email push、回饋 |
| `post_service.dart` | 貼文列表／詳情、按讚、收藏、發布、刪除、評分、熱榜 |
| `comment_service.dart` | 一二級留言、評分留言、按讚與刪除 |
| `shop_service.dart` | 商品列表／詳情、上架、售出、刪除 |
| `notice_service.dart` | 通知數量、列表、已讀的 REST API |
| `chat_service.dart` | REST 聊天歷史；即時訊息不在此處 |
| `workbench_service.dart` | 工作台動態 apps 下發 |
| `resume_service.dart` | 簡歷列表／上傳／詳情／下載／編輯／刪除 |

`ApiClient` 不是完整 HTTP wrapper。各 Service 方法仍自行：

1. 用 `_client.baseUrl` 組 URI。
2. 從 `_client.token` 取得最新 Bearer token。
3. 呼叫 `http.get/post/patch`。
4. 依方法回傳 Model、列表、`bool`、`null`，或在結構不符時拋出 `ApiResponseFormatError`。

原本的 `ApiService` 門面已刪除，現行程式碼不得再 import、建立或傳遞 `ApiService`。共用型別直接從實際定義檔 import。

### API 規格查閱規則

涉及以下任一事項時，先查 `sse_api_capture.md` 對應接口，再核對目前 Service 實作：

- 新增／修改 endpoint 或 HTTP method
- Request body、query、header
- Response 結構與狀態碼
- Model 欄位與 key fallback
- JWT、refresh token、PAT 或其他認證接口
- WebSocket 或後端行為

抓包文件會區分「✅ 實測」與「⚠️ 源碼推導」；推導接口仍需在可安全測試時向後端確認。

## 9. Data Flow

### 登入

```text
LoginPage → AuthService → /auth/login → LoginResult
          → UserService → /auth/info → UserModel
          → StorageService.setUser → userNotifier → GoRouter redirect
```

### 首頁貼文

```text
HomePage → PostService.getPosts(GetPostsParams)
         → POST /auth/browse
         → PostModel.fromDynamic × N
         → 合併並去重 pinned/posts
         → setState → PostCard 列表
```

### 通知與聊天未讀數

```text
API NoticeService.getNoticeNum
    → 本地 NoticeService.updateUnreadCount
    → unreadCount broadcast Stream ─┐
                                    ├→ side_menu badge
WebSocketService unreadCount Stream ┘
```

`NoticePage` 在已讀時呼叫本地 `decreaseUnreadCount()` 或 `clearUnreadCount()`；聊天歷史走 `ChatService`，即時聊天走 `WebSocketService`。

## 10. Important Services

| Service | 生命週期 | 責任 |
|---|---|---|
| `StorageService` | 單例；`main()` 最先 init | user、token、refreshToken、登入狀態與 `userNotifier` |
| `WebSocketService` | 單例；需要時 connect | 聊天連線、ping 與 messages／relevantUsers／contacts／unreadCount 四條 broadcast Stream |
| `core/services/NoticeService` | 單例 | 本地通知未讀計數，不呼叫 REST |
| `MediaCacheService` | 單例；`main()` init | 媒體快取與 metadata |
| `BlurEffectService` | 單例；`main()` init | `enabledNotifier` 控制模糊效果 |
| `DesktopLayoutPreferenceService` | 單例；`main()` init | 側欄與中欄寬度偏好 notifier |
| `BrowseHistoryService` | 單例；使用頁面 init | 本地瀏覽歷史 |
| `WatchLaterService` | 單例；使用頁面 init | 本地待看清單 |
| 七個 `core/api` Service | 非單例、無狀態 | REST 領域操作，token 每次即時讀 StorageService |

## 11. Naming Conflicts / Special Conventions

### 兩個 `NoticeService`

| 類別位置 | 用途 |
|---|---|
| `core/services/notice_service.dart` | 本地未讀數 Stream 狀態 |
| `core/api/notice_service.dart` | REST 通知接口 |

同一檔案同時使用時，API 版採既有 prefix：

```dart
import 'package:sse_market_x/core/api/notice_service.dart' as api_notice;
```

本地版保持 `NoticeService()`。判斷方式：打 API 的在 `core/api`，管 badge 狀態的在 `core/services`。

其他慣例：

- `LoginResult` 從 `auth_service.dart` import。
- `GetPostsParams`、`RatingDetail`、`ApiResponseFormatError` 從 `api_types.dart` import。
- Model 使用 `fromDynamic` 並保留後端多 key fallback，例如 `userID`／`UserID`／`id`。
- 專案現有註解與 UI 字串以簡體中文為主，尚無 i18n 架構。
- `uploadPhoto`、WebSocket 與 REST baseUrl 的網址目前不是單一來源；現況位置見 `AI_TROUBLESHOOTING.md`，重構計畫見 `AI_ROADMAP.md`。

## 12. Important Files

| 優先 | 檔案 | 閱讀目的 |
|---|---|---|
| 1 | `lib/main.dart` | 入口、初始化順序、全域 MaterialApp |
| 2 | `lib/core/router/app_router.dart` | GoRouter、登入 redirect、深連結 |
| 3 | `lib/core/services/storage_service.dart` | 登入狀態、持久化與 userNotifier |
| 4 | `lib/views/index_page.dart` | 響應式主殼、分頁、雙／三欄與巢狀 Navigator |
| 5 | `lib/core/api/api_config.dart` | REST baseUrl |
| 6 | `lib/core/api/api_client.dart` | API 共用層的實際邊界 |
| 7 | `lib/core/api/api_types.dart` | API 共用型別 |
| 8 | `lib/core/api/auth_service.dart` | 認證與加密 |
| 9 | `lib/views/auth/login_page.dart` | 登入編排與本地領域 Service 用法 |
| 10 | `lib/core/api/post_service.dart` | 貼文領域與 pinned 合併 |
| 11 | `lib/views/home/home_page.dart` | 首頁載入與 PostCard 組裝 |
| 12 | `lib/views/post/post_detail_page.dart` | 貼文詳情、留言與評分整合 |
| 13 | `lib/core/services/websocket_service.dart` | 即時聊天與 Stream |
| 14 | `lib/views/notice/notice_page.dart` | 兩個 NoticeService 的正確 import 範例 |
| 15 | `lib/views/home/annual_report_page.dart` | refreshToken 注入 WebView |
| 16 | `lib/shared/components/markdown/latex_markdown.dart` | Markdown／LaTeX 渲染 |
| 17 | `lib/shared/theme/app_colors.dart` | 主題與顏色擴充 |
| 18 | `sse_api_capture.md` | 150 項後端接口抓包／推導規格 |
| 19 | `pubspec.yaml` | 版本、SDK、依賴與 assets |

## 13. Common Development Tasks

### 新增頁面

1. 在 `lib/views/<功能域>/` 建立頁面。
2. 頁面內直接建立所需的無狀態領域 Service。
3. 頂層／深連結才新增 GoRoute；一般頁內依現有模式使用 `Navigator.push`。
4. 若涉及主殼或桌面詳情面板，先讀 `index_page.dart` 的版面分支與 Navigator 層級。

### 新增或修改 API

1. 主動查 `sse_api_capture.md` 的 endpoint、Request、Response 與認證規格。
2. 將方法放進對應領域 Service；只有全新功能域才新增 Service 檔。
3. 使用 `ApiClient` 提供的 baseUrl／token，不恢復已刪除的 `ApiService` 門面。
4. Model 依既有 `fromDynamic` 容錯慣例解析。
5. 頁面本地建立 Service，不把 Service 當建構子參數沿 Widget tree 傳遞。

### 修改登入／認證

依序檢查 `login_page.dart`、`auth_service.dart`、`user_service.dart`、`storage_service.dart`、`app_router.dart`，並查閱 `sse_api_capture.md` 的 Auth 接口。登入狀態只透過 `setUser`／`logout` 改變。

### 新增 Model

在 `core/models/` 新增欄位、const 建構子、`fromDynamic`、必要的 `copyWith`／`toJson`。對後端不一致的 key 保留明確 fallback。

### 新增共用 Widget

放入 `shared/components/<用途>/`，以參數表達輸入輸出；業務 Service 優先由頁面層持有。

### 本地儲存

小型鍵值使用 SharedPreferences。需全域共享時依現有單例 Service 模式；只有啟動前必須就緒的服務才加入 `main()` 並按依賴順序初始化。

### 修改主題

使用 `shared/theme/app_colors.dart` 的 `AppTheme` 與 BuildContext 顏色擴充，避免頁面自行建立另一套全域色彩來源。

## 14. 新程式碼應遵守的現有規則

- 先以程式碼與實際 Config 驗證文件，不照抄過時描述。
- API 變更先查 `sse_api_capture.md`，並區分實測與推導規格。
- UI、API、Model、本地 Service 按現有目錄邊界放置。
- 新 API 直接使用對應領域 Service；不得重建 `ApiService` god object 或門面依賴。
- 無狀態 API Service 在使用端本地建立，不沿 Widget 建構子層層傳遞。
- 認證狀態只經 `StorageService.setUser()`／`logout()`。
- 需登入的 REST 呼叫使用最新 StorageService token 組 Bearer header。
- Model 解析保留後端 key 容錯，不假設命名大小寫已統一。
- 導航修改前辨識 GoRouter、一般 Navigator、桌面 detail Navigator 的層級。
- 同時使用兩個 NoticeService 時，API 版必須加 `api_notice` prefix。
- 修改類別結構、建構子或 State 欄位後，用 Full Restart 驗證，不只 Hot Reload。
- 不在功能任務中順帶做與需求無關的大型重構；技術債依 `AI_ROADMAP.md` 獨立規劃。
- 架構行為改變時，同步更新本文件；新踩坑更新 `AI_TROUBLESHOOTING.md`；技術債狀態只在 `AI_ROADMAP.md` 維護。

## 15. Architecture Map

```text
SSEMarket-X 0.6.6+17
│
├── main.dart
│   └── Storage → MediaCache → BlurEffect → DesktopLayoutPreference → runApp
│
├── GoRouter
│   ├── refreshListenable: StorageService.userNotifier
│   ├── 未登入 → /login；已登入離開 /login
│   └── /、/postdetail/:id、/annual-report 與舊址 redirect
│
├── IndexPage
│   ├── Mobile <600：首頁／打分／消息／我的
│   ├── Desktop 600+：側欄入口 + 內容區
│   └── Three-column 1000+：再加巢狀 Navigator 詳情面板
│
├── UI state
│   ├── setState
│   ├── ValueNotifier（Storage、Blur、Desktop preference）
│   └── broadcast Stream（WebSocket、通知未讀）
│
├── core/api
│   ├── ApiConfig → ApiClient
│   └── Auth / User / Post / Comment / Shop / Notice / Chat / Workbench / Resume
│
├── core/services
│   ├── Storage / WebSocket / local Notice
│   └── MediaCache / Blur / DesktopPref / BrowseHistory / WatchLater
│
├── core/models
│   └── 手寫 fromDynamic + 多 key fallback
│
└── Backend
    ├── REST https://ssemarket.cn/api
    ├── WSS  wss://ssemarket.cn/websocket/auth/chat?token=...
    └── 規格 sse_api_capture.md
```

