# B6 (A) 完成報告 — 简历专区(列表/上传/详情/编辑/删除/下载)

> 日期:2026-09-09 · 範圍:Batch 6 A 線 · 對應官網 /resume 三頁 · 分支 `batch/td22-ranking`(見「八、尚未完成事項」分支備註)

## 一、修改檔案

| 檔案 | 變化 |
|---|---|
| `pubspec.yaml` | 新增唯一依賴 `file_picker: ^11.0.3` |
| `pubspec.lock` | 對應更新(file_picker 11.0.3 + windows_file_picker 等) |
| `lib/views/workbench/workbench_page.dart` | `_EntryKind` 加 `resume`;「简历」項 placeholder→resume;`_onEntryTap` 加 case push ResumeListPage;import;類註釋一行同步(見四.5 偏離說明) |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | flutter clean 後 pub get 自動再生(file_picker 註冊) |
| `AI_ARCHITECTURE.md` | §14 文檔同步義務:core/api 10→12 檔(補 `workbench_service.dart` 漏項 + 新增 `resume_service.dart` 行)、§3 views 樹補 ranking/resume/workbench、兩處 Service 清單補 Workbench/Resume |

## 二、新增檔案

| 檔案 | 內容 |
|---|---|
| `lib/core/models/resume_model.dart` | ResumeModel(fromDynamic 多 key 容錯)、ResumeFileCategory 四類枚舉、normalizedFileExt/category/formattedFileSize/copyWith |
| `lib/core/api/resume_service.dart` | ResumeService 6 方法 + ResumeUploadResult/ResumeDetailResult/ResumeDownloadInfo 結果類 |
| `lib/views/resume/resume_list_page.dart` | 列表頁:双 Tab(全部/我的)+ 搜索 + 骨架/錯誤/空三態 + KeepAlive + ResumeCard |
| `lib/views/resume/resume_upload_page.dart` | 上傳頁:file_picker 選檔、白名單/10MB 前端校驗、防重複提交 |
| `lib/views/resume/resume_detail_page.dart` | 詳情頁:信息區/統計、下載 confirm→url_launcher、isOwner 行內編輯/刪除 |

## 三、刪除檔案

無。

## 四、主要修改

1. **列表頁**:AppBar「简历专区」+ 右上「上传简历」;TabBar 双 Tab + 下方搜索框(placeholder「搜索标题、简介或文件名」+ 搜索鈕,Enter 同義);切 Tab 即重查(TabController listener 動畫完成觸發,`_loadedIndex` 去重),AutomaticKeepAlive 快取各自結果 — 重查期間已有資料保持展示(不清空),無快取才顯骨架(PostListSkeleton);ResumeCard:四類副檔名圖標(pdf 紅/word 藍/圖片 secondary/其他灰)、標題+「匿名」badge、簡介 2 行、meta「{uploader} · {大小} · {viewNum} 次浏览 · {downloadNum} 次下载」、divider 後 footer「{EXT 大寫} · {createdAt}」;空狀態文案 my/home 分別「你还没有上传简历」/「暂无简历,快来上传第一份吧」+ 上傳鈕;詳情返回一律刷新當前 Tab(涵蓋瀏覽/下載計數與編輯刪除同步);請求序號守衛棄置過期回應
2. **上傳頁**:頂部提示條「支持 PDF、Word、JPG、PNG、WebP、GIF,单文件不超过 10MB,每人最多 5 份」;標題*(maxLength 50,hint「例如:2025 前端实习简历」)、簡介(maxLength 500)、「匿名展示(他人看不到你的用户名)」勾選行、選檔鈕顯示已選檔名+大小;`FilePicker.pickFiles(custom 白名單, withData: true)` 後再驗副檔名/≤10MB/bytes 非空;提交防重複(`_isSubmitting` + 按鈕禁用 + spinner);失敗原樣顯示後端 msg(5 份上限無前端計數);成功 SnackBar「上传成功」+ pop(true) → 列表刷新
3. **詳情頁**:四態(loading/notFound「简历不存在或已删除」+返回列表/錯誤+重試/內容);信息卡:圖標+標題+「匿名」+類型 chips(PDF/Word/图片/EXT)、簡介空顯「暂无简介」、統計列(上传者/大小/浏览/下载/时间);底部欄:Expanded「下载」+ isOwner「编辑」「删除」icon 鈕;下載 confirm「确定要下载这份简历吗?」→ downloadResume → 立即 `_launchExternal`(workbench 同款 try-catch,鏈接不緩存);刪除 confirm「确定删除这份简历吗?」→ 成功 SnackBar+pop(true);編輯為行內 TextField(50/500)+保存/取消,成功以回應模型就地更新
4. **文檔同步**(AI_ARCHITECTURE §14):見一。另發現並修正文檔既有漏項(workbench_service 未列於 10 檔表、views 樹缺 ranking/workbench)——屬文檔過時,非本批程式碼變更
5. **偏離說明**:workbench_page 類註釋「小秋/简历/课程专区为占位页…」一行同步為「小秋/课程专区…(简历已接入)」。嚴格字面屬 `_frequentEntries`/`_onEntryTap` 之外,但不改會留下與事實矛盾且直接描述本入口的註釋,故做最小修改並於此報備

## 五、API 變化(ResumeService,6 方法,POST+Bearer+15s timeout,頁面本地實例化)

```dart
Future<List<ResumeModel>?> getResumeList({required String searchsort /*"home"|"my"*/, String searchinfo = ''})
  // body {searchinfo, searchsort, limit:200, offset:0};實測回裸陣列;容錯 {data:[...]};失敗 null
Future<ResumeUploadResult> uploadResume({required List<int> fileBytes, required String fileName, required String title, String description = '', required bool isAnonymous})
  // FormData file/title/description/isAnonymous "true"/"false";code==200 → resumeId;否則 msg 原樣
Future<ResumeDetailResult> getResumeDetail(int resumeId)   // 實測回裸物件;notFound 與錯誤分流
Future<ResumeDownloadInfo?> downloadResume(int resumeId)   // {code,data:{downloadURL,fileName}};取到即用
Future<ResumeModel?> updateResume({required int resumeId, required String title, required String description})  // 回應即新 detail(裸物件/包絡皆容錯)
Future<bool> deleteResume(int resumeId)                    // code==200
```

回傳型別偏離規格字面(裸 int?/model?)之處:`ResumeUploadResult`(需帶出後端 msg,規格五.E 要求)、`ResumeDetailResult`(需分流「不存在」與「網路錯誤」兩種失敗)、`ResumeDownloadInfo`(url+檔名)。語義上位元組數相同。

## 六、flutter analyze

**225 條,0 error,與基準 225 持平**。本批程式碼僅貢獻 1 條 info:`resume_service.dart:4` 直引 `http_parser`(與既有 `user_service.dart:5` 完全同款,屬既有模式)。三條 warning(home_header/settings_list_item/cache_management_page)均為基準既有。修復過程:初版 239 條(7 個 `const MediaType` error、1 個 `FilePicker.platform` error、1 unused field、棄用 withOpacity),全數歸零;新碼改用 `withValues(alpha:)` 不新增棄用告警。

## 七、build test

- `flutter pub get` ✓
- `flutter clean` → `flutter build apk --debug` ✓(`√ Built build\app\outputs\flutter-apk\app-debug.apk`,全新編譯 182s;detail 解析修正後複建 ✓ 25.6s)
- ⚠️ 本環境無模擬器/真機,**人工測試 a-g 未執行**(見八)

## 八、尚未完成事項

1. **人工測試 a-g 全部待本機執行**:列表載入/搜索(標題、簡介、檔名)/上傳(含 >10MB、格式白名單外、第 6 份被拒 msg)/詳情/編輯刪除與列表同步/my+home 空狀態/斷網錯誤+重試/回歸(工作台其他入口、外連 B4.4、打分頁 B4.3)
2. **分支備註**:commit `18cb2ae` 落在 `batch/td22-ranking`(其 HEAD 原為 TD-22 (B) 的 `a413d85`)。對話開始時分支快照為 `batch/6-resume`(仍停在 `3ae2ba7`,無簡歷工作)。分支切換發生於本 session 之外(平行分工 session)。若需移至 `batch/6-resume`:`git checkout batch/6-resume && git cherry-pick 18cb2ae`(未推送,本地可安全操作);未經確認不擅自搬移
3. `downloadURL` 是否可直接以瀏覽器打開、update 回應實際形態,需真機登入帳號實測(見九.2/九.3)
4. iOS/macOS/Windows 平台未構建驗證(僅 Android debug APK)

## 九、發現的新問題

1. **實測回應與文檔欄位差異(sse_api_capture.md #120-#122,✅ 實測證據)**:
   - `list`/`detail` 回**裸物件/裸陣列**,非 {code,data,msg} 包絡 — detail 若按包絡解析會全數誤判「不存在」,已修正為裸物件優先+包絡容錯(本次修正即源於此發現)
   - 回應含模型未接收欄位:`userID`、`fileName`、`mimeType`(列表卡片/詳情均未用到;fileExt 已覆蓋分類需求,不擴模型,保持 INDEX.md §1 包絡)
   - `isOwner`/`canPreview` **list 條目即返回**(文檔稱僅 detail)——模型兩處都收,列表目前不渲染 isOwner,無影響
   - `fileSize` 單位實證為 bytes(535558 → 523.0KB ✓);`createdAt` 為 "2026-05-27 16:19" 字串直接展示 ✓
   - 實測 viewNum:list 425 → detail 426,**開詳情即 +1**,證明「詳情返回刷新列表」設計必要 ✓
   - 官網源碼(ResumeDetailView bundle)證實:upload 走 FormData + `code!==200` 即錯(與本批一致);download 要求 `h.data?.downloadURL`(與本批一致);detail/update 直接 `return r.json()`(支援裸物件判斷)
2. **downloadURL 有效性未驗證**:capture #125 為「未實測(源碼推導)」,回應僅記「(文件流/下載地址)」。本批依官網源碼取 `data.downloadURL` 後立即 url_launcher 外開、不緩存;該 URL 是否可直接瀏覽器打開(是否含簽名/是否短時效)需真機實測
3. **update 回應形態存疑**:官網源碼 `return r.json()`、docs 稱「回應即新 detail」、capture(未實測)標 `{code:200}`。本批容錯:裸 detail 物件 ✓ / 包絡 data ✓;若後端真回 `{code:200}` 無 detail,編輯會顯示「保存失败」但實際已保存(刷新可見)——真機實測確認形態後如需再調
4. **上傳 15s timeout 風險**:10MB 檔在慢網可能逾時(規格統一 15s,未得上傳例外授權);失敗訊息為通用「上传失败,请重试」
5. file_picker 11.0.3 為 **2025-03 版本**(非最新 12.x):12.x 的 `windows_file_picker→win32 ^6.3.0` 與 `package_info_plus 8.x→win32 <6` 衝突;依「唯一新依賴、不動既有依賴」原則選 11.0.3(pub.dev stable)。API 差異:11.x 為靜態 `FilePicker.pickFiles()`(無 `.platform`);11.x 的 Dart/Flutter 下限(3.4/3.22)與 pubspec 宣稱一致,12.x 反而會抬升

## 十、修改後的維護性評估

- **結構**:沿用專案既有分層(models 容錯解析/api 無狀態服務/views 頁面本地實例化),零新抽象、零全域改動;三頁自包含於 `lib/views/resume/`,與 ranking/post 頁同構,後續維護者可循既有模式讀懂
- **服務層**:6 方法一檔,15s/headers/錯誤處理模式與 post_service 統一;三個結果類語義明確(upload 成功/後端 msg、detail 不存在/錯誤分流、download url 即用即棄),頁面端不需重複判 code
- **耦合面**:workbench 僅 +1 enum 值 +1 case +1 import,對 B 線領地零侵入;副檔名→圖標映射在列表/詳情各有一份小 switch(刻意不抽共用元件:兩處語義獨立、抽离收益低,符合專案「三行相似優於過早抽象」慣例)
- **風險點**:update/download 回應形態未實測(九.2/九.3)為主要不確定性;B6 (B) 線接入小秋後 workbench 註釋需再同步一輪
- **文檔**:AI_ARCHITECTURE.md 已同步至 12 檔現況,含既有漏項修復,後續批次基準更準
