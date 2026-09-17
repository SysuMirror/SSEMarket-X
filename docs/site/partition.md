# 分区(原始標題:「分区」/ 分區名)

- 路由:`/partitions`(name: Partitions,分區總覽)、`/partition/:name`(name: Partition,單分區資訊流)
- 來源:JS bundle 分析(PartitionListView-CSE1B6lG.js、PartitionView-B1_IJC-K.js、partitions-kzu-dYzH.js)

## 用途
`/partitions`:十大分區的入口列表;`/partition/:name`:單一分區的帖子資訊流。

## UI 結構
- `/partitions`:分區卡列表,每卡含 icon(tabler 系列)、分區名、描述文字。
- `/partition/:name`:標題(h2 = 分區名)+ PostList 資訊流(與主頁同款卡,無排序器、無置頂列、無新帖標記)。

## 顯示資料
分區清單(**前端寫死**,partitions-kzu-dYzH.js):

| 分區名 | key | icon | 描述 |
|---|---|---|---|
| 学习交流 | study | tabler:school | 「知识碰撞，学术思辨。」 |
| 生活日常 | daily-life | tabler:coffee | 「言短情长，抒发心声。」 |
| 社团活动 | club | tabler:users | 「社团联谊，活动共享。」 |
| 实习就业 | internship | tabler:briefcase | 「梦想职路，共创未来。」 |
| 期末资料 | materials | tabler:file-text | 「资料共享，备考互助。」 |
| 宿舍生活 | dormitory | tabler:home | 「同窗共处，生活点滴。」 |
| 技术分享 | tech | tabler:code | 「代码实践，技术交流。」 |
| 课程专区 | course | tabler:book | 「课程内容，分享交流。」 |
| 组团捞人 | team-up | tabler:user-plus | 「组队拼人，结伴同行。」 |
| 其他 | misc | tabler:dots | 「畅所欲言，创意无限。」 |

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/browse | POST | `{limit:15(首載10), offset, partition:<分區名>, searchsort:"home", searchinfo:"", tag:"", orderBy:"time_desc", timeFrom:"", timeTo:"", userTelephone}` | 載入/滾底 | 擷取檔#21 | |
| /api/auth/getPostNum | POST | 同上 | 載入 | 擷取檔#20 | |

## 分頁
同主頁:limit 15(首載 10)+ offset 累加;Postcount 總數;IntersectionObserver 觸底。

## 導向
分區卡 → `/partition/<name>`;帖子卡 → `/postdetail/:id`;`name==="课程专区"` 時導向 `/course`;路由無 name 參數 → `/` + toast「分区不存在」。

## 需登入?
是。

## 未確認事項
- 分區名對伺服器為**精確字串**(簡體),URL 需編碼(如 `/partition/%E8%AF%BE%E7%A8%8B%E4%B8%93%E5%8C%BA`);伺服器是否接受其他別名未確認。
- 伺服器端分區白名單是否等於這十個(發帖 select 用同一清單,推測一致)。
