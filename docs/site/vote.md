# 投票(原始標題:「投票」)

- 路由:`/vote`(name: Vote;query `?title=` 預填)
- 來源:JS bundle 分析(VoteView-BtHeL9B9.js、vote-5X4zdHkL.js)

## 用途
以標題關鍵詞搜帖 → 選中 → 投票(每帖一票)。

## UI 結構
- 標題「投票」;副標「输入标题关键字搜索帖子，选中后投票（每帖仅可投一票）」。
- 搜尋框 placeholder「输入标题关键字…」(300ms debounce);「搜索中…」。
- 結果列:「{title} · {partition} · {voteCount} 票」。
- 「已选帖子」;已投提示「您已为该帖投过票」;按鈕「确认投票/已投票/提交中…」。
- 底部連結「查看排行榜 →」→ `/ranking`。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/searchPostsByTitle | POST | `{keyword, userTelephone}` | 輸入(debounce 300ms) | — | 回 `data.posts[{postID,title,partition,postTime,voteCount}]` |
| /api/auth/checkUserVoted | POST | `{postID, userTelephone}` | 選中帖時 | 擷取檔#65+ | 回 `data.voted` |
| /api/auth/submitVote | POST | `{postID, userTelephone}` | 確認投票 | — | 回 `{code,msg,data:{voted}}` |

## 分頁
搜尋結果無分頁(一次回)。

## 導向
「查看排行榜 →」→ `/ranking`;返回 → back。

## 需登入?
是。

## 未確認事項
- searchPostsByTitle 結果筆數上限。
- 投票截止機制(排行榜前 100 名為固定快取?未確認)。
