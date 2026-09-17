# AI Troubleshooting — SSEMarket-X

> **用途：** 只有在修 Bug、排查異常、功能失效或報錯時閱讀。
>
> **Last verified: 2026-08-31**
>
> 本文件只收錄已有文件或程式碼可證實的踩坑。正常架構見 `AI_ARCHITECTURE.md`；未來改善見 `AI_ROADMAP.md`。

## 修改類別或建構子後出現無法解釋的假故障

**症狀：**  
程式碼看起來正確且可編譯，但登入、Service 欄位、Widget State 或建構子行為仍像舊版本；Hot Reload 後才出現型別、欄位或狀態不一致。

**原因：**  
Dart Hot Reload 不會重新建立所有既有物件。畫面中仍存活的舊 `State` 可能和新的類別定義或欄位結構混用。

**處理方法：**  
涉及類別結構、建構子、State 欄位、Service 欄位新增／替換時，停止 App 後 Full Restart。若狀態仍可疑，再執行 `flutter clean` 後完整重啟。

**驗證：**  
從全新程序啟動 App，重新走一次受影響流程；確認故障不再出現，而不是只在 Hot Reload 工作階段暫時正常。

**首次／最近確認日期：**  
2026-08-30（登入失效事件；完整重啟後恢復，程式碼本身無誤）／2026-08-31

## 兩個 `NoticeService` 同名而呼叫錯服務

**症狀：**  
通知 API 方法找不到、呼叫到不預期的未讀數邏輯，或 import 後類別名稱看似正確但用途不對。

**原因：**  
專案有兩個同名類別：

- `core/api/notice_service.dart`：REST 通知 API。
- `core/services/notice_service.dart`：本地未讀數 broadcast Stream。

**處理方法：**  
同一檔同時使用兩者時，API 版採：

```dart
import 'package:sse_market_x/core/api/notice_service.dart' as api_notice;
```

呼叫 API 用 `api_notice.NoticeService()`；本地 badge 狀態用未加 prefix 的 `NoticeService()`。可參考 `notice_page.dart`、`index_page.dart`、`side_menu.dart`。

**驗證：**  
確認 REST 呼叫實際進入 `/auth/getNotice*` 方法；已讀操作後本地 badge Stream 也同步更新。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## `StorageService` 尚未初始化或初始化順序錯誤

**症狀：**  
啟動時讀取 SharedPreferences、token、user 或 Router redirect 發生 late initialization error、狀態錯誤，或 App 明明有登入資料卻進入登入頁。

**原因：**  
`StorageService` 持有登入狀態，Router 與 API Service 都依賴它。若未在其他服務和 `runApp` 前完成 `init()`，依賴方會讀到未就緒狀態。

**處理方法：**  
維持 `main.dart` 的第一個服務初始化為 `await StorageService().init()`。新增啟動服務時先確認它依賴哪些已初始化服務，再決定順序。

**驗證：**  
完全關閉後重啟 App；已登入使用者能正確恢復並進入首頁，未登入使用者正確進入 `/login`，啟動期間沒有 SharedPreferences／late initialization 例外。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## 登入或登出後 Router 沒有跳轉

**症狀：**  
token 或 SharedPreferences 已改變，但畫面仍停在登入頁或首頁；重新開 App 後狀態才改變。

**原因：**  
GoRouter 監聽的是 `StorageService.userNotifier`，不是 SharedPreferences。直接寫入 prefs 或只改 token 不會完整更新登入狀態與 notifier。

**處理方法：**  
登入成功使用 `StorageService.setUser(...)`；登出使用 `StorageService.logout()`。不要自行複製 prefs 寫入流程，也不要以顯式 Navigator 取代登入成功後的 Router redirect。

**驗證：**  
登入後自動離開 `/login` 並進入原 redirect 或 `/`；登出後自動回 `/login`；完全重啟後狀態仍一致。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## Token 過期表現為空頁面而不是登出

**症狀：**  
貼文、商品、通知或其他需登入資料突然顯示空列表、無資料或一般載入失敗，但 App 沒有回到登入頁。

**原因：**  
目前 API 層沒有集中式 `401` 處理與 access token 自動刷新。多數 Service 在非 200 或例外時回傳 `null`、空列表或 `false`，因此 UI 看起來像沒有內容。抓包文件記載 JWT 約 7 天有效。

**處理方法：**  
排查時先確認 response status 是否為 401、StorageService 中 token 是否已過期。現行恢復方式是讓使用者登出後重新登入；不要把空列表直接判定為後端沒有資料。集中刷新屬 `AI_ROADMAP.md` 的 TD-05。

**驗證：**  
以有效 token 重新登入後相同接口恢復資料；網路記錄不再回 401，且空頁面消失。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## 修改 baseUrl 後只有部分網路功能失效

**症狀：**  
一般 REST 正常但頭像上傳或聊天失效，或相反；更換網域／環境後只有部分功能仍連到舊站。

**原因：**  
目前有三個獨立網址來源：

- REST：`lib/core/api/api_config.dart` 的 `https://ssemarket.cn/api`
- 頭像上傳：`lib/core/api/user_service.dart` 的完整 `https://ssemarket.cn/api/auth/uploadPhotos`
- WebSocket：`lib/core/services/websocket_service.dart` 的 `wss://ssemarket.cn/websocket/auth/chat?token=...`

修改 `ApiConfig.baseUrl` 不會自動改另外兩處。

**處理方法：**  
先分辨失效的是一般 REST、`uploadPhoto` 還是 WebSocket。若任務本身就是切換網域，三處一起核對，並同步查閱 `sse_api_capture.md` 的 URL 與認證規格。

**驗證：**  
分別測試一般 API、頭像上傳與 WebSocket 連線；確認三者都連到預期網域，且 WebSocket 帶有目前 access token。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## ApiService 遷移後仍出現舊 import、欄位或建構子參數

**症狀：**  
編譯器找不到 `ApiService`／`api_service.dart`，頁面要求已不存在的 `apiService` 建構子參數，或新增程式碼又開始把單一服務沿 Widget tree 傳遞。

**原因：**  
原本的 1,420 行 `ApiService` god object 已在 2026-08-30 完成拆分並刪除。現行 API 層是七個領域 Service；過渡橋接、欄位、參數與 import 都已清除。

**處理方法：**  
依功能改用 `AuthService`、`UserService`、`PostService`、`CommentService`、`ShopService`、API `NoticeService` 或 `ChatService`，在使用端本地建立。共用型別從 `auth_service.dart` 或 `api_types.dart` 的實際定義檔 import。不要重建門面來讓舊呼叫編譯。

**驗證：**  
搜尋 `ApiService` 與 `api_service.dart`，`lib/` 應沒有結果；靜態分析不再報舊建構子／import 錯誤；完整重啟後受影響頁面可正常呼叫領域 Service。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## `index_page` 巢狀 Navigator 導航到錯誤層級

**症狀：**  
桌面三欄模式下，詳情頁覆蓋整個 App、返回鍵退出錯誤頁面、詳情面板沒有更新，或 `pop` 操作了 root 而不是右側詳情棧。

**原因：**  
專案同時使用 GoRouter、一般 `Navigator.push` 與 `index_page.dart` 的 `_detailNavigatorKey`。`Navigator.of(context)` 會依 context 所在位置取得不同 Navigator。

**處理方法：**  
先決定目標應在頂層、一般頁內還是桌面詳情面板。桌面詳情使用 `_detailNavigatorKey.currentState` 與既有 `_navigateTo...`／`_update...Detail` 路徑；只有確實需要全 App 覆蓋時才使用 root Navigator。

**驗證：**  
至少在手機版、600～999 雙欄版、1000+ 三欄版各測一次開啟與返回；確認路由棧、選中分頁和詳情 placeholder 都恢復正確。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

## Annual Report 修改認證後仍顯示未登入或重複載入

**症狀：**  
App 其他 API 已登入，但年度報告 WebView 顯示未登入、資料缺失、持續 loading 或反覆 reload。

**原因：**  
`annual_report_page.dart` 不使用一般 REST Bearer token 流程。它讀取 `StorageService.refreshToken` 與 `refreshTokenExpiry`，在第一次 `onPageFinished` 注入 WebView `localStorage`，reload 後才結束 loading。

**處理方法：**  
修改登入、refresh token 儲存、key 名稱、到期時間或年度報告網址時，同時檢查 `annual_report_page.dart` 的 JavaScript 注入與 `_waitingForReload`／`_hasInjectedToken` 流程。不要只改 `AuthService` 的 access token。

**驗證：**  
使用具有有效 refreshToken 的帳號開啟 `/annual-report`；確認只執行預期的一次注入 reload，第二次完成後顯示內容，WebView localStorage 具有 `refreshToken` 與 `refreshTokenExpiry`。

**首次／最近確認日期：**  
2026-08-30／2026-08-31

