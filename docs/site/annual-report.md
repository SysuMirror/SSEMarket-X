# 年度报告(原始標題:「集市年度报告」)

- 路由:`/annual2025`(限時開放:2026-01-20 00:00 ~ 2026-02-27 23:59,逾時 alert「不在活动时间内」→ `/`;搜尋框輸入「年度报告」亦為入口)
- 來源:JS bundle 分析(AnnualReportView-Bc9XX0sE.js、level-DzluOJG1.js)

## 用途
個人年度數據回顧(7 頁投影片,全 CSS 賽博風格,無圖表庫)+ 長圖導出。

## UI 結構(投影片)
0. 封面:「2025」「集市年度报告」+ 頭像/暱稱/簡介,「轻触界面/向下滚动以继续」。
1. 「缘起」:註冊天數(`durationTime` 換算)`日夜`;分級文案(≥365「一整年的陪伴，感谢有你」…<30「欢迎新朋友，期待你的精彩」)。
2. 「你的输出 / YOUR OUTPUT」:「本年度发布 N 帖子」、「累计发布」、「累计获赞」、「今年收获了 N 次点赞」。
3. 「你的时刻 / YOUR MOMENT」:HUD 三卡「最多点赞 MAX LIKES / 最多观看 MAX VIEWS / 最多评论 MAX COMMENTS」+ 進度條。
4. 「你的回响 / YOUR RESONANCE」:九宮格「评论/回复/收藏」+「被收藏/被热议/被回应」。
5. 「你的私信 / YOUR CHAT」:「发送了 N 条消息」;「年度私信」卡(maxSayUser + N 条消息);「你也私信了——」頭像列(前 4)。
6. 「未终」:「当前等级」+「经验值: N」;「新的一年，软工集市与你同在」「INITIATING 2026 SEQUENCE...」;按鈕「再看一次」「导出图片」「返回首页」。
- 互動:點擊前進/滑動(>50px)/7 個指示列;背景音樂 `https://music.163.com/song/media/outer/url?id=2723954830.mp3`(含微信 WeixinJSBridge autoplay 處理);導出:Canvas 繪 750×7000 長圖 → 下載 `SSEMARKET_年度报告_{年}.png`(失敗 alert「导出失败，请稍后再试」)。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/statistics | POST | `{}`(空 body) | 載入 | — | `code===200` → data(下述欄位) |

## 顯示資料
`{name, intro, avatarUrl, durationTime(ms), thisYearPostCnt, totalPostCnt, totalPostLikeNum, thisYearLikeNum, maxLikeNum, maxBrowseNum, maxCommentNum, pCommentCnt, ccommentCnt, savedCount, beSavedCount, beCommentedCount, repliedCount, chatCount, maxSayUser{userID,name,avatarURL}, maxSayUserCnt, relevantRespUsers[{userID,avatarURL}], score}`;等級由 score 經 level 模組換算。

## 分頁
無。

## 導向
「返回首页」→ `/`。

## 需登入?
是 + 限時開放。

## 未確認事項
- 年度統計的統計區間定義(自然年 2025?durationTime 起點 = 註冊時間?)未確認。
- 2026 年版路由是否改為 `/annual2026`(目前僅見 2025)。
