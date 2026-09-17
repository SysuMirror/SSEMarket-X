# SSEMarket 網站逆向文件 — 總覽(INDEX)

> 產出:2026-09-04 · 編寫:Claude(本機環境,網路直抓)
> **證據來源**:全部結論來自實際抓取的網站資源 —— `https://ssemarket.cn/new/` 首頁 HTML、94 個前端 JS/CSS chunk(存於 `site_crawl/raw/`),以及對安全 GET 端點的線上實測。輔助來源:`sse_api_capture.md`(使用者 2026-08-25 Playwright 抓包紀錄,以下稱「擷取檔」,項目編號 #N)。
> **抓取方法**:`curl -L` + 瀏覽器 UA,每請求間隔 ≥1 秒,總請求約 110 次;只實測 GET,POST 僅靜態分析。
> **免責**:文件供重建客戶端參考;「未確認」表示無法從公開資源推得,嚴禁腦補。

## 1. 技術棧摘要

| 項目 | 結論 | 出處 |
|---|---|---|
| 前端框架 | **Vue 3**(Composition API、`<script setup>`、Pinia 式自建 store) | index.html `<div id="app">` + chunk 內 `__name`/`setup()` 結構 |
| 打包工具 | **Vite**(檔名 `index-<hash>.js`、`__vite__mapDeps`、modulepreload) | index.html L18-20、各 chunk 首行 |
| 路由 | Vue Router,`createWebHistory("/new/")`;標題格式 `` `${name} | SSE` `` | index-pcgjWmeH.js(router 定義段) |
| 網站型態 | SPA(HTML 空殼);PWA 支援(manifest.json、usePWA、service worker 反註冊舊版) | index.html、usePWA-BSJwe7Zs.js |
| source map | **無**(.map 全數 404) | fetch_site.ps1 探測結果 |
| robots.txt / sitemap.xml | **無效**——兩者皆回傳同一個 HTML 部落格頁(SSEMARKET官方博客),非真正的 robots/sitemap | raw/robots.txt 與 sitemap.xml 內容比對(逐 byte 相同) |
| API host | 同源,前綴 **`/api`**(request wrapper `fetch("/api"+path)`) | index-pcgjWmeH.js `const w="/api"` |
| API 風格 | JSON REST;**絕大多數讀取也用 POST**;少數 GET、一個 PATCH;WSS 一條 | 全部 chunk |
| 認證 | `Authorization: Bearer <JWT>`;access token 前端計時 7 天−1 小時、refresh token 30 天;401 → 自動 refresh 一次 → 重試 → 再失敗登出 | index-pcgjWmeH.js(request wrapper `I`) |
| 圖床 | 騰訊雲 COS `sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com`;縮圖路徑 `/src/images/resized/…` ↔ 原圖 `/src/images/uploads/…`(`strHandler("postImg")` 做字串互換) | ShopView、strHandler-B3Lupr7P.js |
| 通知/聊天 | WebSocket `wss://ssemarket.cn/websocket/auth/chat?token=<JWT>`;30 秒心跳;另有 60 秒輪詢新帖 | noticeStore-DYTmEZcC.js、newPostsStore-RIIPDiZl.js |
| UI 元件庫 | 無大型組件庫;圖示用 **Tabler Icons**(inline)+ icons8 外鏈圖;markdown-it + KaTeX + DOMPurify + Prism;pdf.js 站內 worker `/new/pdf.worker.min.js` | 各 chunk import |

### 共用前端基建(重建客戶端必讀)

- **request wrapper**(index-pcgjWmeH.js export `r`):`r(path, {method, headers, body, query}, needAuth=true)` →
  `fetch("/api"+path+"?"+URLSearchParams(query), {method, headers:{..., Authorization:"Bearer "+token}, body:JSON.stringify(body)})`;
  query 為 undefined 時 URL 尾帶 `?`。401 → 單飛(single-flight)`POST /auth/refresh {refresh_token}` → 重試一次;無 token 無 refresh → toast「登录过期，请重新登录」並導向 `/auth/login`。
- **token 儲存**:記憶體變數;`rememberMe==="true"` 時 refreshToken 寫 localStorage(`refreshToken`、`refreshTokenExpiry`);啟動時清除舊 key `oneAPIKey/oneAPIModel/oneAPIKeyExpiry`。
- **路由守衛**:`/auth/*` 與 `meta.public` 放行;`/annual2025` 限時 2026-01-20 00:00 ~ 2026-02-27 23:59(「不在活动时间内」);未登入 → `/auth/login?redirect=<path>&<原query>`。
- **回應包絡三態**(客戶端需分別處理):
  1. `{code, data, msg}`(多數;code 200=成功、401=权限不足、201=通知沒有更多、422=驗證錯)
  2. **裸陣列 / 裸物件**(browse 可能回 `{pinned,posts,total}` 或裸陣列、getProducts、resume/list、showPcomments、rating 三個 list、calculateHeat、getNoticeNum、userProfilePosts、workbench/apps)
  3. `{ok:…}`(rag-local)、`{code:0,…}`(agent)
- **全站 toast**:6 秒自動消失;操作防抖 `debounced()`:執行中「提交中，请稍候…」、1 秒內重複「操作太频繁，请稍候」。

## 2. 完整路由樹

由 index-pcgjWmeH.js 路由表逐條解出(元件 = 對應 lazy chunk):

```
/new/  (base)
└─ / (DefaultLayout:頂欄 SSE MARKET + PC/Mobile header + 底欄)
   ├─ ""            Home          HomeView-DVrGWK-2.js        主页(資訊流+置頂+排序)
   ├─ course        Course        CourseView-ve4sG_yC.js     课程专区(老師下拉+資訊流)
   ├─ save          Save          SaveView-C-q46mIm.js       收藏
   ├─ history       History       HistoryView-DTMiPXE1.js    发帖历史
   ├─ rating        Rating        RatingView-C85Mtae4.js     打分专区(?category= 分類)
   ├─ rating/category/new   RatingCategoryNew  …CreateView-_L7_Qvjl.js  创建打分分区
   ├─ rating/post   RatingPost    …CreateView-D2oyeA4f.js    发布评分
   ├─ rating/:id    RatingDetail  RatingDetailView-D5mYBIR2.js 评分帖详情
   ├─ partition/打分  → redirect /rating
   ├─ resume        Resume        ResumeView-D9KFnLkR.js     简历专区(searchsort=home)
   ├─ resume/my     ResumeMy      ResumeView(同 chunk)       我的简历(searchsort=my)
   ├─ resume/upload ResumeUpload  ResumeUploadView-HM_lhI5d.js
   ├─ resume/:id    ResumeDetail  ResumeDetailView-CTfSZJBj.js(含 pdf.js 預覽)
   ├─ search        Search        SearchView-BqyCMKxq.js     搜索(?sinfo&partition&smart&timeFrom&timeTo)
   ├─ rag-preview   → redirect /search(?sinfo&q&smart=1)
   ├─ partitions    Partitions    PartitionListView-CSE1B6lG.js  分区總覽
   ├─ post          Post          PostView-B38Sf7-N.js       發帖(meta.layoutFill;普通帖/抽奖帖;IndexedDB 草稿)
   ├─ partition/:name  Partition  PartitionView-B1_IJC-K.js  單分區資訊流
   ├─ postdetail/:id  Postdetail  PostDetailView-NDYwTIOd.js 帖子詳情(+評論+抽獎盒)
   ├─ messages      Messages      MessagesView-BgX7eSVX.js   互動通知+私信(meta.layoutFill;?tab&user&anonymous)
   ├─ notice        → redirect /messages?tab=notice
   ├─ chat          → redirect /messages?tab=chat
   ├─ heat          Heat          HeatView-B5UpQ4j6.js       热榜
   ├─ vote          Vote          VoteView-BtHeL9B9.js       投票
   ├─ ranking       Ranking       RankingView-CiX2HN4a.js    排行榜(优质榜/用户榜)
   ├─ feedback      Feedback      FeedbackView-BRN0Q9N3.js   反馈
   ├─ options       Options       OptionsView-DPVbWHBh.js    设置(資料/安全/SSO/通用/開發者 PAT)
   ├─ user/:id      UserProfile   UserProfileView-ks65Mbfl.js 個人主頁
   ├─ smart-xiaoqiu SmartXiaoQiu  SmartXiaoQiuView-BZJ8RVGu.js 智能小秋 AI(meta.layoutFill)
   ├─ workbench     Workbench     WorkbenchView-TftrVydq.js  工作台(應用入口)
   ├─ shop          ShopLayout    ShopLayout-BQo_YhaB.js
   │  ├─ ""         Shop          ShopView-Db8M2mH5.js       逛逛好物(searchsort=home)
   │  ├─ myproducts MyProducts    ShopView(同 chunk)        我的商品(searchsort=history)
   │  ├─ productdetail/:ProductID  Productdetail  ProductView-AUCfPioN.js
   │  └─ sale       Sale          SaleView-DnijuNK_.js      发布商品
   ├─ connect       Connect       ConnectView-DRpjlNQO.js    第三方 OAuth 授權頁
   ├─ annual2025    (限時開放)    AnnualReportView-Bc9XX0sE.js 年度报告
   ├─ /auth/ (AuthLayout)
   │  ├─ login      Login         LoginView-CaDFsgn_.js
   │  ├─ register   Register      RegisterView-CM7vXlYJ.js
   │  ├─ sso/result SsoResult     SsoResultView-GRFG-V3V.js
   │  ├─ sso/bind   SsoBind       SsoBindView-mIzSVBBe.js
   │  └─ reset      Reset         ResetView-CnyuNJA0.js
   └─ /:catchAll(.*)  → redirect /
```

**導覽選單結構**(DefaultLayout + PcHeader/BottomNavbar/MobileHeader/PartitionList/ShopLayout):
- PC 頂欄(PcHeader):「发帖」/post・「分区」/partitions・「课程专区」/course・「反馈」/feedback・「商城」/shop・「打分」/rating・「智能小秋」/smart-xiaoqiu・搜尋框(模式切換「切换普通/切换智能」+ 熱詞輪播)・右側「收藏」/save・「历史」/history・「消息」/messages(未讽徽章)・使用者名稱 → /options
- Mobile 頂欄(MobileHeader):搜尋框 + 智能小秋圖示;PartitionList 橫條:「主页・小秋・分区・打分・商城」;BottomNavbar 五鈕:「主页・消息・发帖(中央)・工作台・我的(/options)」
- 商店內導覷(ShopLayout):Mobile tabs「商城・我的・发布・消息」;PC 側欄「商城首页・我的商品・发布商品・消息・返回主页」

## 3. API 端點總表

method 以程式碼呼叫方式為準;「加密」= password 欄位經 AES(見 §4);「實測」= 線上打過(✅ 成功、❌ 401/5xx 形狀亦為實測證據)。

### 認證 / 帳號
| 端點 | Method | 隸屬頁面 | auth | 加密 | 實測 | 出處 JS |
|---|---|---|---|---|---|---|
| /api/auth/login | POST {email, password} | 登入 | 否 | AES | 擷取檔#1 | index-pcgjWmeH.js |
| /api/auth/register | POST {CDKey, email, name, password, password2, phone:"", valiCode} | 註冊 | 否 | AES | — | RegisterView |
| /api/auth/validateEmail | POST {email, mode:0註冊/1重設} | 註冊/重設(發驗證碼) | 否 | - | 擷取檔#10 | index-pcgjWmeH.js |
| /api/auth/modifyPassword | POST {email, password, password2, valiCode} | 忘記密碼/改密碼 | 否 | AES | — | forgetPwd |
| /api/auth/refresh | POST {refresh_token} | wrapper 自動 | 否 | - | 擷取檔#4 | index-pcgjWmeH.js |
| /api/auth/info | GET | 全域(本人資訊) | 是 | - | ❌401「权限不足」 | index-pcgjWmeH.js |
| /api/auth/getInfo | POST {userID} | 用戶卡/賣家名/授權頁 | 是 | - | 擷取檔#5 | index-pcgjWmeH.js |
| /api/auth/updateUserInfo | POST {avatarURL, intro, name, userID, hideProfilePosts} | 设置→账号资料 | 是 | - | — | OptionsView |
| /api/auth/changeEmailPush | POST {user_id} | 设置→禁用邮箱推送 | 是 | - | — | OptionsView |
| /api/auth/uploadAvatar | POST FormData(file) | 设置→頭像 | 是 | - | — | OptionsView(原生fetch) |
| /api/auth/uploadPhotos | POST FormData(file) → {fileURL} | 發帖/商品/草稿圖片 | 是 | - | — | utils-1MCYKXOd.js(原生fetch) |
| /api/auth/sso/login | GET(瀏覽器跳轉) | 登入頁「使用 UniSSO 登录」 | 否 | - | — | sso-CXPZUCtz.js |
| /api/sso/exchange | POST {ticket} | SSO 回跳 | 否 | - | — | sso-CXPZUCtz.js |
| /api/sso/bind | POST {ticket, email, password} | SSO 綁定 | 否 | AES | — | sso-CXPZUCtz.js |
| /api/sso/bind/start | POST {} → data.authorize_url | 设置→SSO 綁定 | 是 | - | — | sso-CXPZUCtz.js |
| /api/sso/status | GET | 设置→SSO 狀態 | 是 | - | — | sso-CXPZUCtz.js |
| /api/sso/unbind | POST {password} | 设置→SSO 解綁 | 是 | AES | — | sso-CXPZUCtz.js |

### 論壇
| 端點 | Method | 隸屬頁面 | auth | 實測 | 出處 JS |
|---|---|---|---|---|---|
| /api/auth/browse | POST {limit, offset, partition, searchsort, searchinfo, tag, orderBy, timeFrom, timeTo, userTelephone} | 主页/分區/收藏/历史/搜尋/课程 | 是 | 擷取檔#13+ | getPost-Dau8qLQa.js |
| /api/auth/getPostNum | POST(同上條件)→ {Postcount} | 同上 | 是 | 擷取檔#12+ | getPost-Dau8qLQa.js |
| /api/auth/showDetails | POST {postID, userTelephone} | 帖子詳情 | 是 | 擷取檔#27 | getPost-Dau8qLQa.js |
| /api/auth/updateBrowseNum | POST {postID, userTelephone} | 帖子詳情(+瀏覽數) | 是 | 擷取檔#28 | getPost-Dau8qLQa.js |
| /api/auth/post | POST {content, partition, photos:"", tagList, title, userTelephone, isPrivate, isAnonymous, pinned} | 發帖 | 是 | — | editPost-D6teKpmQ.js |
| /api/auth/deletePost | POST {postID} | 刪帖 | 是 | — | editPost |
| /api/auth/updatePostPrivacy | POST {postID, userTelephone, isPrivate} | 設私密 | 是 | — | editPost |
| /api/auth/pinPost / unpinPost | POST {postID} | 置頂1小時 | 是 | — | getPost |
| /api/auth/updateLike | POST {postID, userTelephone} | 讚 | 是 | — | UserButton |
| /api/auth/updateSave | POST {postID, userTelephone} → data.isSaved | 收藏 | 是 | — | UserButton |
| /api/auth/toggleWatch | POST {postID, userTelephone} → data.watched | 「码住」追蹤 | 是 | — | PostDetailView |
| /api/auth/showPcomments | POST {postID, userTelephone, postType:"post"} | 評論列表 | 是 | 擷取檔#38 | PostDetailView |
| /api/auth/postPcomment | POST {content, postID, userTelephone} | 發一級評論 | 是 | — | CommentToolbar |
| /api/auth/postCcomment | POST(子評論物件,呼叫端組裝) | 發二級回覆 | 是 | — | CommentToolbar |
| /api/auth/deletePcomment | POST {pcommentID} | 刪一級 | 是 | — | CommentToolbar |
| /api/auth/deleteCcomment | POST {ccommentID} | 刪二級 | 是 | — | CommentToolbar |
| /api/auth/updatePcommentLike | POST {pcommentID, userTelephone} | 一級讚 | 是 | — | UserButton |
| /api/auth/updateCcommentLike | POST {ccommentID, userTelephone} | 二級讚 | 是 | — | UserButton |
| /api/auth/resolveMentions | POST {names[]} → data.users[{name,userID}] | @提及解析 | 是 | — | MarkdownContainer |
| /api/auth/calculateHeat | GET → [{PostID,Title}] | 热榜 | 是 | ❌401 | getPost |
| /api/auth/getTags?type=course | GET → data.tags[{TagID,Name}] | 發帖/课程專區(老師) | 是 | 擷取檔#119 | getTeacher-BPJhlnJH.js |

### 抽獎 / 投票 / 排行
| 端點 | Method | 隸屬頁面 | auth | 出處 JS |
|---|---|---|---|---|
| /api/auth/lottery/create | POST {title, content, partition, userTelephone, mode:"random"/"wish", drawAt:"YYYY-MM-DD HH:mm:00", prizes:[{name,quantity,wishKeyword}], isPrivate} | 發帖→抽奖帖 | 是 | lottery-CPKAEkrM.js |
| /api/auth/lottery/detail | POST {postID, userTelephone} | 帖子詳情(抽獎盒) | 是 | lottery |
| /api/auth/lottery/participate | POST {postID, userTelephone} | 參與抽獎 | 是 | lottery |
| /api/auth/searchPostsByTitle | POST {keyword, userTelephone} → data.posts | 投票頁搜帖 | 是 | vote-5X4zdHkL.js |
| /api/auth/submitVote | POST {postID, userTelephone} → data.voted | 投票 | 是 | vote |
| /api/auth/checkUserVoted | POST {postID, userTelephone} → data.voted | 投票狀態 | 是 | vote |
| /api/auth/postRanking | GET → data.ranking | 排行榜(帖) | 是 | vote |
| /api/auth/userRanking | GET → data.ranking | 排行榜(人) | 是 | vote |

### 打分
| 端點 | Method | 隸屬頁面 | auth | 出處 JS |
|---|---|---|---|---|
| /api/auth/rating/category/list | POST {} → 裸陣列 | 打分首頁 | 是 | categories-MnUjG2zL.js |
| /api/auth/rating/category/create | POST {name, description, syncFeedPost} | 创建分区 | 是 | categories |
| /api/auth/rating/post/list | POST {categoryID, searchinfo, limit, offset} → 裸陣列 | 分類列表 | 是 | posts-BoUHqj2b.js |
| /api/auth/rating/post/detail | POST {ratingPostID} | 評分帖詳情 | 是 | posts |
| /api/auth/rating/post/create | POST {categoryID, title, content} → ratingPostID | 发布评分 | 是 | posts |
| /api/auth/rating/post/delete | POST {ratingPostID} | 刪除 | 是 | posts |
| /api/auth/rating/post/like | POST {ratingPostID} | 讚 | 是 | posts |
| /api/auth/rating/comment/list | POST {ratingPostID} → 裸陣列 | 評論列表 | 是 | comments-CzMsPPuk.js |
| /api/auth/rating/comment/create | POST {ratingID?ratingPostID, content, starNum} | 發評論(可帶星) | 是 | comments |
| /api/auth/rating/comment/like | POST {commentID} | 評論讚 | 是 | comments |
| /api/auth/rating/star/submit | POST {ratingPostID, starNum} | 給星 | 是 | RatingDetailView |

### 商店 / 簡歷 / 課程
| 端點 | Method | 隸屬頁面 | auth | 出處 JS |
|---|---|---|---|---|
| /api/auth/getProducts | POST {searchinfo, searchsort:"home"/"history", limit, offset} → 裸陣列 | 商店列表 | 是 | queries-DQfBsA89.js |
| /api/auth/getProductDetail | POST {productID} | 商品詳情 | 是 | queries |
| /api/auth/postProduct | POST {UserID, Price, Title, Content, Photos[], ISAnonymous, syncFeedPost} | 上架 | 是 | mutations-C00mKXf9.js |
| /api/auth/deleteProduct | POST {productID} | 刪商品 | 是 | mutations |
| /api/auth/saleProduct | POST {productID} | 標記售出 | 是 | mutations |
| /api/auth/resume/list | POST {searchinfo, searchsort:"home"/"my", limit:200, offset:0} → 陣列 | 簡歷列表 | 是 | ResumeView |
| /api/auth/resume/upload | POST FormData(file, title, description, isAnonymous) | 上傳簡歷 | 是(原生fetch) | ResumeUploadView |
| /api/auth/resume/detail | POST {resumeID} | 簡歷詳情 | 是 | ResumeDetailView |
| /api/auth/resume/update | POST {resumeID, title, description} | 編輯 | 是 | ResumeDetailView |
| /api/auth/resume/delete | POST {resumeID} | 刪除 | 是 | ResumeDetailView |
| /api/auth/resume/download | POST {resumeID} → data.downloadURL/fileName | 下載 | 是 | ResumeDetailView |
| /api/auth/resume/preview/stream/{resumeID} | GET(串流,PDF arrayBuffer/圖 blob) | 預覽 | 是(原生fetch) | ResumeDetailView |

### 訊息 / 通知(WebSocket 見 §5)
| 端點 | Method | 隸屬頁面 | auth | 出處 JS |
|---|---|---|---|---|
| /api/auth/getChatNotice | GET ?userID → data.noticeNum | 未讀輪詢 | 是 | noticeStore |
| /api/auth/getChatHistory | GET ?senderUserID&targetUserID&threadAnonymous → data.chatHistoryList | 對話記錄 | 是 | noticeStore |
| /api/auth/leaveChatView | GET ?senderUserID&targetUserID&threadAnonymous | 離開對話 | 是 | noticeStore |
| /api/auth/recallChatMessage | POST {chatMsgID} → data.message | 撤回(24h內) | 是 | noticeStore |
| /api/auth/getNoticeNum | GET → {totalNum, unreadTotalNum, readTotalNum} | 未讀數 | 是 | noticeStore |
| /api/auth/getNotice | GET ?requireID&pageSize&read → {code,data:{noticeList,lastID},msg} | 通知列表 | 是 | noticeStore |
| /api/auth/readNotice/{noticeID} | PATCH | 標已讀 | 是 | noticeStore |

### 用戶 / 雜項 / 令牌 / AI
| 端點 | Method | 隸屬頁面 | auth | 實測 | 出處 JS |
|---|---|---|---|---|---|
| /api/auth/userProfilePostNum | POST {targetUserID} → {Postcount} | 個人主頁 | 是 | — | UserProfileView |
| /api/auth/userProfilePosts | POST {targetUserID, limit:15, offset} → 裸陣列 | 個人主頁 | 是 | 擷取檔#26 | UserProfileView |
| /api/auth/submitFeedback | POST {ftext, attachment:""} | 反馈 | 是 | — | FeedbackView |
| /api/auth/statistics | POST {} → 年報 data | 年度报告 | 是 | — | AnnualReportView |
| /api/auth/connect/check | POST {app_id} → data{app_name,app_icon,description} | OAuth 授權頁 | 是 | — | ConnectView |
| /api/auth/connect/authorize | POST {app_id, redirect_uri, response_type, scope, state} → data.redirect_url | OAuth 授權頁 | 是 | — | ConnectView |
| /api/auth/workbench/apps | GET → 裸陣列 | 工作台 | **否** | ✅200 | WorkbenchView |
| /api/auth/token/scopes | GET → data.scopes[{name,description}] | 设置→开发者 | 是 | — | OptionsView |
| /api/auth/token/create | POST {name, scopes[]} → data.token(明文僅一次) | 设置→开发者 | 是 | — | OptionsView |
| /api/auth/token/list | GET ?page(1起)&page_size(50) → data.records[] | 设置→开发者 | 是 | — | OptionsView |
| /api/auth/token/revoke | POST {token_id} | 设置→开发者 | 是 | — | OptionsView |
| /api/auth/token/delete | POST {token_id} | 设置→开发者 | 是 | — | OptionsView |
| /api/rag-local/hot-queries | GET ?limit → {ok,data[{query,count,last_seen,recommend_score}]} | 搜尋框熱詞 | **否** | ✅200 | ragSearch-CYOwrorG.js |
| /api/rag-local/search | GET ?q&limit&source | 智慧搜尋 | **否** | ❌502(服務異常) | ragSearch |
| /api/v1/agent/conversation/bootstrap | GET → code 0 + data{session_id,segment_seq,archived,messages[]} | 智能小秋 | 是(JWT) | ❌502(服務異常) | SmartXiaoQiuView |
| /api/v1/agent/conversation/close | POST {session_id} | 智能小秋 | 是 | — | SmartXiaoQiuView |
| /api/v1/agent/task/sse | POST {session_id, task}(SSE 串流) | 智能小秋 | 是 | — | SmartXiaoQiuView |
| /api/v1/agent/mcp | POST(JSON-RPC 2.0,MCP 2025-06-18) | 外部工具(PAT) | 是(**PAT**, `sk_xq_` 開頭) | — | OptionsView 內嵌文件 |

## 4. 加密/簽名機制摘要(已完全解出)

**唯一加密:登入類密碼欄位 AES** —— 出處 index-pcgjWmeH.js 函式 `le(e,t="16bit secret key")`(壓縮名),用於 login / register / reset(modifyPassword)/ sso bind / sso unbind 的 `password`(與 `password2`)欄位。其餘請求無任何簽名(無 sign/timestamp/nonce)。

```
key = Utf8.parse("16bit secret key")          // 17 bytes
      → ZeroPadding.pad(keyWA, 4)             // 補零至 32 bytes → AES-256
iv  = Utf8.parse( SHA256("16bit secret key").toString() )
      // = 64 字元 hex 字串的 ASCII;CBC 僅用前 16 bytes
mode = CBC(CryptoJS 預設)  padding = Pkcs7(CryptoJS 預設)
輸出 = AES.encrypt(明文, key, {iv}).toString()   // Base64(無 Salted__ 頭,raw key 模式)
```

- 金鑰字串出處:呼叫端一律寫死 `le(t,"16bit secret key")`(index、RegisterView、forgetPwd、sso chunk 皆有)。
- 等價實作已用 Node `crypto` 驗證來回一致(本機測試向量:`"Abc123!$"` → `G0C4PjGmVAa1yPXpiHQuQA==`)。
- 擷取檔密文樣本(已遮蔽中段)均為 Base64 尾 `==` 且**非** `U2FsdGVkX1` 開頭 → 與 raw-key 模式一致(交叉佐證)。
- JWT:Header `Authorization: Bearer <JWT>`;WebSocket 走 query 參數 `?token=<JWT>`;PAT 走 `Authorization: Bearer sk_xq_…`。token 效期由前端常數推得 access≈7天、refresh=30天。

## 5. WebSocket 幀格式(聊天)

`wss://ssemarket.cn/websocket/auth/chat?token=<JWT>`(noticeStore-DYTmEZcC.js):

| 方向 | 幀 | 內容 |
|---|---|---|
| C→S | 心跳(30s) | `{userID, beat:1}` |
| C→S | 訊息 | `{senderUserID, targetUserID, content, isAnonymous, threadAnonymous}` |
| S→C | 聊天訊息 | `{chatMsgID, senderUserID, targetUserID, content, isAnonymous, threadAnonymous, createdAt}`(無 type 欄位) |
| S→C | 撤回 | `{type:"recall", recall:{chatMsgID,…}}` |
| S→C | 會話列表同步 | `{relevantUsers:[{userID,name,avatarURL,unRead,threadAnonymous,peerMasked,lastMessagePreview,lastMessageAt,…}]}` |
| S→C | ACK | `{code, msg}`;code 0 = 成功(伺服器剔除 pending) |

匿名機制:`conversationKey = ${userID}_anon / ${userID}_direct`;匿名顯示「匿名用户」、peer 遮蔽時 email/identity 清空;撤回視窗 24 小時、僅限本人訊息;重連指數退避(初始 1s、最多 5 次)。

## 6. 分頁機制彙總

| 域 | 參數 | 總數來源 | 補充 |
|---|---|---|---|
| 論壇資訊流(browse) | `limit`(首頁初始 10→後續 15;課程/收藏/历史 15)+ `offset`(項目偏移,0 起算,前端累加) | getPostNum → `Postcount`;browse 回應內 `total` 恆 0 不可用 | 無限滾動(IntersectionObserver rootMargin 240px);`hasMore = 本頁筆數 ≥ limit`;orderBy 六值 time/like/comment × asc/desc |
| 評級帖(rating/post/list) | `limit:20`(頁面實值;API 層預設 15)+ `offset` | **無**(裸陣列)→「加载更多」按鈕 | `hasMore = 本頁 20 筆` |
| 商品(getProducts) | `limit:80`(shop)/12(首頁輪播取圖)/1000(API 預設)+ `offset:0` | 無 | 單頁式,不滾動 |
| 簡歷(resume/list) | `limit:200, offset:0` | 無 | 一次大包 |
| 個人主頁(userProfilePosts) | `limit:15` + `offset` | userProfilePostNum → `Postcount` | 無限滾動 |
| 通知(getNotice) | `requireID`(游標,首頁 0,之後帶上頁 `lastID`)+ `pageSize:20` + `read`(0/1) | getNoticeNum(unread/read/total) | `code 201`「没有更多通知」=到底 |
| 令牌(token/list) | `page`(1 起算頁碼)+ `page_size:50` | data.records | 全站唯一 page/page_size 制 |
| 評論(showPcomments / rating comment/list) | **無分頁**,一次全載,前端排序 asc/desc(CommentTime+ID) | — | — |
| 熱榜/排行 | 無參數(伺服器固定前 100 名) | — | — |

## 7. 頁面清單(各頁 md)

| 檔案 | 頁面(路由) |
|---|---|
| [home.md](home.md) | 主页 `/` |
| [partition.md](partition.md) | 分区總覽 `/partitions` 與單分區 `/partition/:name` |
| [course.md](course.md) | 课程专区 `/course` |
| [post-create.md](post-create.md) | 發帖 `/post` |
| [post-detail.md](post-detail.md) | 帖子詳情 `/postdetail/:id` |
| [save-history.md](save-history.md) | 收藏 `/save`、历史 `/history` |
| [search.md](search.md) | 搜索 `/search`(含智能模式) |
| [rating.md](rating.md) | 打分专区 `/rating` |
| [rating-create.md](rating-create.md) | 创建分区 `/rating/category/new`、发布评分 `/rating/post` |
| [rating-detail.md](rating-detail.md) | 评分帖详情 `/rating/:id` |
| [resume.md](resume.md) | 简历专区 `/resume`、`/resume/my` |
| [resume-upload.md](resume-upload.md) | 上傳簡歷 `/resume/upload` |
| [resume-detail.md](resume-detail.md) | 简历详情 `/resume/:id` |
| [shop.md](shop.md) | 商店 `/shop`、`/shop/myproducts` |
| [shop-product-detail.md](shop-product-detail.md) | 商品详情 `/shop/productdetail/:ProductID` |
| [shop-sale.md](shop-sale.md) | 发布商品 `/shop/sale` |
| [messages.md](messages.md) | 消息中心 `/messages`(通知+私信) |
| [vote.md](vote.md) | 投票 `/vote` |
| [ranking-heat.md](ranking-heat.md) | 排行榜 `/ranking`、热榜 `/heat` |
| [feedback.md](feedback.md) | 反馈 `/feedback` |
| [options.md](options.md) | 设置 `/options`(含 PAT/MCP) |
| [user-profile.md](user-profile.md) | 個人主頁 `/user/:id` |
| [workbench.md](workbench.md) | 工作台 `/workbench` |
| [smart-xiaoqiu.md](smart-xiaoqiu.md) | 智能小秋 `/smart-xiaoqiu`(AI) |
| [annual-report.md](annual-report.md) | 年度报告 `/annual2025` |
| [auth.md](auth.md) | 登入/註冊/重設 `/auth/*` 與 SSO |
| [connect.md](connect.md) | OAuth 授權 `/connect` |

## 8. 全域未確認事項彙總

1. **`/auth/reset` 端點**:擷取檔 #9 出現過,但現行 bundle 的忘記密碼流程實際呼叫 `/auth/modifyPassword`(forgetPwd chunk);`/auth/reset` 在 LoginView 僅作為**路由連結**字串出現。推測 `/auth/reset` 為舊版端點,現況未確認。
2. **`postCcomment` 完整欄位**:呼叫端(CommentCard)組裝的子評論物件未逐欄確認(組裝程式在 404 的 CCommentCard chunk 相關鏈)——已知含 content 與 pcommentID 關聯,其餘欄位未確認。
3. **`CCommentCard-CKv2iCcT.js` 伺服器 404**:chunk 被引用但伺服器無此檔(部署不一致);子評論卡相關細節自此檔不可得。
4. **rag-local/search 與 agent 服務**:實測時後端 502(「HTTP Error 500」/ 502 頁);請求/回應結構由前端程式碼推導,欄位意義標「未確認」處見各頁。
5. **JWT 伺服器實際效期**:前端常數 access≈7天−1h、refresh 30天;伺服器簽發值未直接驗證。
6. **workbench/apps 回應欄位** `groupName/source/invokerSlug/sortOrder/isVisible/createdAt` 伺服器有回但前端未使用 → 意義從名稱推斷。
7. **圖片上傳的伺服器限制**(格式/大小上限):前端無檢查,僅簡歷頁標示 10MB/5份;uploadPhotos/uploadAvatar 的伺服器限制未確認。
8. **聊天「會話列表」初始來源**:連線後伺服器主動推 `relevantUsers` 幀;若無幀則由收件動態建立(前端邏輯),伺服器行為細節未確認。
9. **`getNotice` 的 `data.noticeList` 單筆完整欄位**:列表由 MessagesView 渲染,已知含 noticeID 與分類文字;完整欄位集未逐一確認(見 messages.md)。
10. **付費/管理類後台**(ban 處罰通知、舉報處理等):僅從通知分類文字得知存在,對應端點未見。
