# 發帖(原始標題:「发帖」)

- 路由:`/post`(name: Post,meta.layoutFill 全幅)
- 來源:JS bundle 分析(PostView-B38Sf7-N.js、editPost-D6teKpmQ.js、lottery-CPKAEkrM.js、utils-1MCYKXOd.js、MarkdownEditor-Crn0WEBH.js)

## 用途
發布普通帖或抽奖帖;含 IndexedDB 草稿箱(20 秒自動儲存)與圖片上傳。

## UI 結構
- 頁首:「发帖」+ 說明「支持 Markdown · 图片可粘贴或从工具栏插入」;送出鈕「发送」/「发送中…」。
- 帖子类型 tablist:「普通帖」/「抽奖帖」。
- 表單:
  - 「标题」input(maxlength 30,placeholder「写一个吸引人的标题（最多 30 字）」)
  - 「分区」select(主頁 + 10 分區)
  - 分区=课程专区時:「课程标签」select(老師,getTags)
  - 核取:「仅自己可见（发帖后也可在帖子卡片上修改）」、「匿名发帖（隐藏我的昵称、头像与等级）」、主頁限定「同时置顶 1 小时（每人仅 1 个置顶帖，全站共 5 个名额）」
  - MarkdownEditor(placeholder「在这里写下正文…」;工具列:预览/编辑、图片上傳(「图片」按鈕+貼上支援)、格式鈕「标题/粗体/斜体/删除线/引用/无序列表/有序列表/表格/分割线/代码块」)
- 抽奖設定(抽奖帖,折疊面板「抽奖设置」):
  - 抽奖模式 radiogroup:「随机抽奖」(到期後隨機抽)/「许愿抽奖」(評論含關鍵詞即參與;提示「评论含对应关键词即可参与该奖品奖池；每个奖池仅计一次；到期自动开奖。」)
  - 「开奖时间」datetime-local(送出格式 `YYYY-MM-DD HH:mm:00`)
  - 「奖品」清單:每項「奖品名称」+「份数」(number,min 1;許願模式再加「关键词」);「添加」/刪除鈕
- 側欄「草稿箱」(PC 寬 ≥769 自動展開):「清空」「更新」「保存」按鈕;提示「手动保存后，每 20 秒自动保存」;空狀態「暂无草稿」;草稿項標題 fallback「无标题」+ 前 48 字。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/post | POST | `{content, partition, photos:"", tagList, title, userTelephone, isPrivate, isAnonymous, pinned}` | 送出普通帖 | — | 回應讀 `.msg` 判斷成敗;**photos 恆空字串**(圖走內文 markdown) |
| /api/auth/lottery/create | POST | `{title, content, partition, userTelephone, mode:"random"/"wish", drawAt, prizes:[{name, quantity, wishKeyword}], isPrivate}` | 送出抽奖帖 | — | 回 `{code, msg, data.postID}` |
| /api/auth/uploadPhotos | POST | FormData(`file`) | 圖片插入/貼上 | — | 原生 fetch + Bearer;回 `{fileURL,…}` → 插入 `![名](fileURL)` |
| /api/auth/getTags?type=course | GET | — | 分区=课程专区 | 擷取檔#119 | 老師標籤 |

## 分頁
無(表單頁)。

## 導向
普通帖成功 → `/`;抽奖帖成功 → `/postdetail/<postID>`。

## 需登入?
是。

## 顯示資料/草稿
草稿存 IndexedDB:db `drafts`(v1)、store `drafts_store`(keyPath `id` autoIncrement,索引 `title`);API add/getAll/get(id|title)/update/delete。正文上限 10000 字(code points 計)。

## 未確認事項
- `tagList` 的分隔格式(課程標籤單選;多標籤情境由 SmartXiaoQiu 草稿卡送出時以 `"|"` 連接 — 推測同格式)。
- 伺服器對置頂名額(5)與每人 1 帖限制的錯誤回應格式(僅知前端 toast「置顶失败」)。
- `pinned:true` 的帖子是否同時佔用普通發帖(合併為一帖)——從回應只讀 msg,未確認。
