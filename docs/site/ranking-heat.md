# 排行榜 / 热榜(原始標題:「排行榜」、「热榜」)

- 路由:`/ranking`(Ranking)、`/heat`(Heat)
- 來源:JS bundle 分析(RankingView-CiX2HN4a.js、HeatView-B5UpQ4j6.js、vote-5X4zdHkL.js、getPost)

## 用途
`/ranking`:投票產生的帖榜/人榜(前 100);`/heat`:熱帖清單。

## UI 結構
- **排行榜**:標題「排行榜」+ CTA「去投票」→ `/vote`;Tabs「优质榜」(post)/「用户榜」(user);副標「按得票数排序 · 前 100 名」/「获赞与获票合计 · 前 100 名」。
  - 前三名頒獎台(gold/silver/bronze;crown/medal/award 圖示,第 1 名置中);其餘清單名次從 4 起。
  - 帖卡:「{title} + N 票 + partition 標籤」→ `/postdetail/{id}`;用戶列:頭像(fallback 名字首字/「用」)+ 名稱(fallback「匿名用户」)+「赞 N · 票 N · 合计 N」→ `/user/{id}`。
  - 數字格式化:≥1e4 → `x.xw`、≥1e3 → `x.xk`;loading 骨架;空「暂无数据」「投票或互动后，榜单会在这里更新」;錯誤「获取排行榜失败」。
- **热榜**:h2「热榜」;每筆連結 `/postdetail/{PostID}` 顯示 `{Title}`;錯誤 toast「获取热帖失败:{err}」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/postRanking | GET | — | 載入(tab=post) | 擷取檔#101 | 回 `data.ranking[{postID,title,partition,voteCount,postTime}]` |
| /api/auth/userRanking | GET | — | tab=user | — | 回 `data.ranking[{userID,userName,avatarURL,receivedLikeNum,receivedVoteNum,rankScore}]` |
| /api/auth/calculateHeat | GET | — | 热榜載入 | ❌實測 401「权限不足」(帶 token 則通) | 回裸陣列 `[{PostID, Title}]` |

## 分頁
無參數;伺服器固定回前 100 名。

## 導向
帖子 → `/postdetail/:id`;用戶 → `/user/:id`;「去投票」→ `/vote`。

## 需登入?
是(calculateHeat 需 Bearer,實渗無 token 回 401)。

## 未確認事項
- 榜單更新頻率(前端單次載入,無輪詢;伺服器快取策略未知)。
- `rankScore` 計算公式(僅欄位名)。
