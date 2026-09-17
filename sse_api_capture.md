# ssemarket.cn API 實測抓包全記錄

> **抓取方式**:Playwright 真實瀏覽器 + 網絡監聽 · **日期**:2026-08-25
> **基址**:`https://ssemarket.cn` · **認證**:`Authorization: Bearer <JWT>`(7 天有效)
> ✅ = 真實捕獲的 Request/Response Body · ⚠️ = 寫入型接口未觸發(避免產生真實副作用),結構由前端源碼推導
> 敏感信息(token/密碼密文/手機號)已遮蔽;數組超過 3 項僅保留前 3 項,完整原始數據見 `C:\Users\chanh\sse-capture\captures2.json`(⚠️ 含活躍 token,勿外傳)

**捕獲統計**:實測 95 個不同請求 + 源碼推導 55 個 = 共 150 項

---

# 認證 Auth

## 1. `POST /api/auth/login`

- **✅ 實測** · HTTP 422

**Request Body:**
```json
{
  "email": "probe_test@example.com",
  "password": "Eb6DhDWByC…[已遮蔽]8Q=="
}
```

**Response Body:**
```json
{
  "code": 422,
  "data": null,
  "msg": "用户不存在"
}
```

---

## 2. `POST /api/auth/login`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "email": "sengc058@gmail.com",
  "password": "+P73a6XXMo…[已遮蔽]8g=="
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "refresh_token": "eyJhbGciOi…[已遮蔽]ShCM",
    "token": "eyJhbGciOi…[已遮蔽]g2lA"
  },
  "msg": "登录成功"
}
```

---

## 3. `GET /api/auth/info`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "user": {
      "userID": 1232,
      "name": "我要巷",
      "avatarURL": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1786760701256951505_圖片_20260815102433_1_1.jpg",
      "phone": "961****4135",
      "email": "sengc058@gmail.com",
      "identity": "student"
    }
  }
}
```

---

## 4. `POST /api/auth/refresh`

- **✅ 實測** · HTTP 401

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOi…[已遮蔽]ShCM"
}
```

**Response Body:**
```json
{
  "code": 401,
  "data": null,
  "msg": "refresh token 无效或已使用"
}
```

---

## 5. `POST /api/auth/getInfo`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "phone": "961****4135"
}
```

**Response Body:**
```json
{
  "avatarURL": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1786760701256951505_圖片_20260815102433_1_1.jpg",
  "ban": "2026-08-14T21:51:35+08:00",
  "email": "sengc058@gmail.com",
  "emailNotificationBlocked": true,
  "emailpush": true,
  "hideProfilePosts": false,
  "intro": "我要巷，原是\"我要卷\"，但发现原来这山出了几十头老虎，一心想从公鸡变成凤凰的我，放弃原本的目标，从\"卷\"变成\"巷\"。呆在巷子里、居在陋室里，自得其乐！",
  "name": "我要巷",
  "phone": "961****4135",
  "punishnum": 0,
  "score": 142,
  "userID": 1232
}
```

---

## 6. `POST /api/auth/getInfo`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "userID": 1232
}
```

**Response Body:**
```json
{
  "avatarURL": "",
  "ban": "2026-07-01T23:26:21+08:00",
  "hideProfilePosts": false,
  "intro": "",
  "name": "匿名用户",
  "phone": "",
  "punishnum": 0,
  "score": 0,
  "userID": 1150
}
```

---

## 7. `POST /api/auth/getInfo`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "userID": 303
}
```

**Response Body:**
```json
{
  "avatarURL": "",
  "ban": "2023-10-21T21:37:43+08:00",
  "hideProfilePosts": false,
  "intro": "",
  "name": "阿哈",
  "phone": "956****3240",
  "punishnum": 0,
  "score": 137,
  "userID": 303
}
```

---

## 8. `POST /api/auth/register`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "CDKey": "邀請碼",
  "email": "user@example.com",
  "name": "暱稱",
  "password": "AES加密後(見 s…[已遮蔽] §3)"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "註冊成功",
  "data": null
}
```

---

## 9. `POST /api/auth/reset`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發;字段名為源碼推斷

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "…[已遮蔽]",
  "code": "郵箱驗證碼"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "重置成功",
  "data": null
}
```

---

## 10. `POST /api/auth/validateEmail`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(發驗證碼),未觸發;mode 區分場景

**Request Body:**
```json
{
  "email": "user@example.com",
  "mode": "register"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "發送成功"
}
```

---

## 11. `POST /api/auth/modifyPassword`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "…[已遮蔽]"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "修改成功"
}
```

---

# 帖子 Posts

## 12. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "主页",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 4043
}
```

---

## 13. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200 ·(同型請求出現 6 次)

**Request Body:**
```json
{
  "limit": 20,
  "offset": 0,
  "partition": "主页",
  "searchsort": "home",
  "searchinfo": "",
  "userTelephone": "961****4135",
  "tag": ""
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5671,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "大三体育有室内然后比较简单的吗",
      "Content": "如题，看了很久有点想选体能，但是怕很累",
      "Like": 0,
      "Comment": 2,
      "Browse": 70,
      "Heat": 65,
      "PostTime": "2026-08-25T00:44:41+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15393,
        "userID": 20,
        "userName": "明月挤石油",
        "content": "击剑挺好的 ，给分也不错。不过上学期一般都在做体测",
        "likeNum": 0,
        "createdAt": "2026-08-25T00:50:10+08:00"
      }
    },
    {
      "PostID": 5670,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "朋友圈趋势",
      "Content": "主包感觉现在朋友圈都很同质化，仿佛复制粘贴套模版一般，是大家只会发出所谓积极的那一部分吗，都好像",
      "Like": 2,
      "Comment": 12,
      "Browse": 164,
      "Heat": 181,
      "PostTime": "2026-08-25T00:00:10+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15392,
        "userID": 905,
        "userName": "Jalen-lai",
        "content": "感觉朋友圈变成了认识新朋友的CV一样 会稍微克制一点 发发积极一点的（我个人来说） 我平时要是想发牢骚什么的就发发动态 还挺有意思的",
        "likeNum": 4,
        "createdAt": "2026-08-25T00:22:46+08:00"
      }
    },
    {
      "PostID": 5669,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "现在荔18宿舍可以住了吗",
      "Content": "有人在学校吗 现在荔18可以回去住了吗 ",
      "Like": 0,
      "Comment": 4,
      "Browse": 113,
      "Heat": 94,
      "PostTime": "2026-08-24T22:55:28+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15386,
        "userID": 32,
        "userName": "夜神月",
        "content": "暑假不都是有人留吗",
        "likeNum": 0,
        "createdAt": "2026-08-24T23:44:20+08:00"
      }
    },
    "…(共 20 項,完整數據見 captures2.json)"
  ],
  "total": 0
}
```

---

## 14. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "主页",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5671,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "大三体育有室内然后比较简单的吗",
      "Content": "如题，看了很久有点想选体能，但是怕很累",
      "Like": 0,
      "Comment": 2,
      "Browse": 70,
      "Heat": 65,
      "PostTime": "2026-08-25T00:44:41+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15393,
        "userID": 20,
        "userName": "明月挤石油",
        "content": "击剑挺好的 ，给分也不错。不过上学期一般都在做体测",
        "likeNum": 0,
        "createdAt": "2026-08-25T00:50:10+08:00"
      }
    },
    {
      "PostID": 5670,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "朋友圈趋势",
      "Content": "主包感觉现在朋友圈都很同质化，仿佛复制粘贴套模版一般，是大家只会发出所谓积极的那一部分吗，都好像",
      "Like": 2,
      "Comment": 12,
      "Browse": 164,
      "Heat": 181,
      "PostTime": "2026-08-25T00:00:10+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15392,
        "userID": 905,
        "userName": "Jalen-lai",
        "content": "感觉朋友圈变成了认识新朋友的CV一样 会稍微克制一点 发发积极一点的（我个人来说） 我平时要是想发牢骚什么的就发发动态 还挺有意思的",
        "likeNum": 4,
        "createdAt": "2026-08-25T00:22:46+08:00"
      }
    },
    {
      "PostID": 5669,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "现在荔18宿舍可以住了吗",
      "Content": "有人在学校吗 现在荔18可以回去住了吗 ",
      "Like": 0,
      "Comment": 4,
      "Browse": 113,
      "Heat": 94,
      "PostTime": "2026-08-24T22:55:28+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15386,
        "userID": 32,
        "userName": "夜神月",
        "content": "暑假不都是有人留吗",
        "likeNum": 0,
        "createdAt": "2026-08-24T23:44:20+08:00"
      }
    },
    "…(共 15 項,完整數據見 captures2.json)"
  ],
  "total": 0
}
```

---

## 15. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "课程专区",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 352
}
```

---

## 16. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "课程专区",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5012,
      "Partition": "课程专区",
      "UserID": 637,
      "UserName": "👿",
      "UserScore": 920,
      "UserTelephone": "277****3730",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1779102742319697681_1000009249.jpg",
      "UserIdentity": "student",
      "Title": "软需课件😭",
      "Content": "哪里可以获得完整的课件啊？有些忘记下载已经过期了😭",
      "Like": 0,
      "Comment": 1,
      "Browse": 381,
      "Heat": 212,
      "PostTime": "2026-06-04T14:46:14+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 13672,
        "userID": 539,
        "userName": "dlm",
        "content": "蹲",
        "likeNum": 0,
        "createdAt": "2026-06-05T13:26:36+08:00"
      }
    },
    {
      "PostID": 5006,
      "Partition": "课程专区",
      "UserID": 855,
      "UserName": "在干什么",
      "UserScore": 432,
      "UserTelephone": "510****0779",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1749095691279511391_Screenshot_2025_0603_204448.png",
      "UserIdentity": "student",
      "Title": "计网实验报告",
      "Content": "计网实验报告可以把那些实验步骤什么的删除吗，只留回答的部分",
      "Like": 1,
      "Comment": 2,
      "Browse": 476,
      "Heat": 277,
      "PostTime": "2026-06-02T20:10:15+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 13561,
        "userID": 55,
        "userName": "Tlipped",
        "content": "可以的，但记得标注题目",
        "likeNum": 0,
        "createdAt": "2026-06-02T22:11:23+08:00"
      }
    },
    {
      "PostID": 4987,
      "Partition": "课程专区",
      "UserID": 1021,
      "UserName": "空条承太郎",
      "UserScore": 194,
      "UserTelephone": "648****2918",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1758513456165863119_Camera_1040g3k831hm4psho3ih05osdbhc7qp06kev25rg.jpg",
      "UserIdentity": "student",
      "Title": "ys这周布置的课堂作业是啥啊",
      "Content": "rt",
      "Like": 0,
      "Comment": 5,
      "Browse": 333,
      "Heat": 213,
      "PostTime": "2026-05-30T14:49:16+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 13455,
        "userID": 883,
        "userName": "乐奈",
        "content": "推导这个![1000035508.jpg](https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1780136216728322181_1000035508.jpg)",
        "likeNum": 0,
        "createdAt": "2026-05-30T18:17:01+08:00"
      }
    },
    "…(共 15 項,完整數據見 captures2.json)"
  ],
  "total": 0
}
```

---

## 17. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "收藏",
  "searchsort": "save",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 3
}
```

---

## 18. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "收藏",
  "searchsort": "save",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5634,
      "Partition": "主页",
      "UserID": 612,
      "UserName": "ᨐ",
      "UserScore": 52,
      "UserTelephone": "427****7532",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1758516421264450919_1000015101.png",
      "UserIdentity": "student",
      "Title": "求人工智能二课件",
      "Content": "楼主想报人工智能三的专选，想看看二的课件补一补课，有没有好心人愿意分享一下",
      "Like": 0,
      "Comment": 2,
      "Browse": 253,
      "Heat": 137,
      "PostTime": "2026-08-20T11:18:00+08:00",
      "IsSaved": true,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15300,
        "userID": 582,
        "userName": "華工",
        "content": "https://www.jianguoyun.com/p/DZ7j80oQyoLZDRjxqaQGIAA",
        "likeNum": 0,
        "createdAt": "2026-08-20T11:58:47+08:00"
      }
    },
    {
      "PostID": 5624,
      "Partition": "主页",
      "UserID": 957,
      "UserName": "资深追剧狂魔流浪在外",
      "UserScore": 528,
      "UserTelephone": "050****1589",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1767631790782051222_IMG_7436.jpeg",
      "UserIdentity": "student",
      "Title": "南校食堂大测评",
      "Content": "这一篇帖子是煮啵吃了半年食堂总结出来的，包括具体位置和菜品名称[吧唧R]感觉食堂还是有很多好吃的，就是也有很多坑特别难吃，好多同学可能吃过一次难吃就不吃了[扯脸H]\n——夯——🥳\n1.春晖园二楼：湘菜",
      "Like": 4,
      "Comment": 10,
      "Browse": 401,
      "Heat": 254,
      "PostTime": "2026-08-19T12:52:34+08:00",
      "IsSaved": true,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15276,
        "userID": 923,
        "userName": "事情会做完的",
        "content": "建议新生多试试，实在不知道吃啥再看别人的攻略。比如我就觉得学一烧腊拉完了",
        "likeNum": 3,
        "createdAt": "2026-08-19T13:41:51+08:00"
      }
    },
    {
      "PostID": 5600,
      "Partition": "主页",
      "UserID": 620,
      "UserName": "Donald J. Trump",
      "UserScore": 4514,
      "UserTelephone": "385****6226",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1729406361899670322_748ee3bc087a5a3db17a4fb19d0843d.jpg",
      "UserIdentity": "student",
      "Title": "假如让我重新安排我的大一大二（理想很美好版）",
      "Content": "看着我现在的绩点，痛定思痛。但是如果能对各位有点帮助的话，也算是对自己的安慰了。假如能回到大一的话，我会这样安排我的大一大二：\n大一：\n0.不要一股脑直接买新书！部分书籍可以买二手书/找电子书！部分书",
      "Like": 40,
      "Comment": 26,
      "Browse": 879,
      "Heat": 625,
      "PostTime": "2026-08-17T12:33:14+08:00",
      "IsSaved": true,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 15217,
        "userID": 627,
        "userName": "Hugging Face",
        "content": "阴帅，等你们下学期学到医物你们就享福了",
        "likeNum": 10,
        "createdAt": "2026-08-17T12:35:51+08:00"
      }
    }
  ],
  "total": 0
}
```

---

## 19. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 15,
  "partition": "主页",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 4043
}
```

---

## 20. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "历史",
  "searchsort": "history",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 2
}
```

---

## 21. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "历史",
  "searchsort": "history",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5598,
      "Partition": "主页",
      "UserID": 1232,
      "UserName": "我要巷",
      "UserScore": 142,
      "UserTelephone": "961****4135",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1786760701256951505_圖片_20260815102433_1_1.jpg",
      "UserIdentity": "student",
      "Title": "Vibe coding 的使用者",
      "Content": "现在vibe coding 的大时代，想问问各位大佬在vibe coding的过程中是一个怎样的角色？\n1. Yes/No 工程师\n2. 真的会去看代码的原理（但没系统化学习\n3. 会写，但不写\n本人",
      "Like": 2,
      "Comment": 5,
      "Browse": 655,
      "Heat": 295,
      "PostTime": "2026-08-17T11:33:08+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": true,
      "isPinned": false,
      "hotComment": {
        "id": 15211,
        "userID": 278,
        "userName": "秋",
        "content": "review工程师，每天都在review，ai给出来的架构方案要一点一点看，给出来的接口字段要一个一个看，哭",
        "likeNum": 5,
        "createdAt": "2026-08-17T11:48:49+08:00"
      }
    },
    {
      "PostID": 5582,
      "Partition": "主页",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "重回大一，你會怎樣做？",
      "Content": "假如各位學長學姐重回到大一，你們會怎樣去規劃自己的大學生活？",
      "Like": 0,
      "Comment": 24,
      "Browse": 910,
      "Heat": 486,
      "PostTime": "2026-08-15T10:23:23+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": true,
      "isPinned": false,
      "hotComment": {
        "id": 15150,
        "userID": 582,
        "userName": "華工",
        "content": "珍惜广州的生活，不对学习太过压力但也不要完全摆大烂，享受105楼下50m就是学五和200m就是东门的时光",
        "likeNum": 11,
        "createdAt": "2026-08-15T10:35:20+08:00"
      }
    }
  ],
  "total": 0
}
```

---

## 22. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 2,
  "partition": "历史",
  "searchsort": "history",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [],
  "total": 0
}
```

---

## 23. `POST /api/auth/getPostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "学习交流",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "Postcount": 835
}
```

---

## 24. `POST /api/auth/browse`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "limit": 15,
  "offset": 0,
  "partition": "学习交流",
  "searchsort": "home",
  "searchinfo": "",
  "tag": "",
  "orderBy": "time_desc",
  "timeFrom": "",
  "timeTo": "",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "pinned": [],
  "posts": [
    {
      "PostID": 5436,
      "Partition": "学习交流",
      "UserID": 0,
      "UserName": "匿名用户",
      "UserScore": 0,
      "UserTelephone": "",
      "UserAvatar": "",
      "UserIdentity": "",
      "Title": "大一绩点5%",
      "Content": "\n想问问大一绩点百分之五大概是多少呀\n",
      "Like": 0,
      "Comment": 0,
      "Browse": 742,
      "Heat": 360,
      "PostTime": "2026-07-20T22:53:22+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": true,
      "isOwner": false,
      "isPinned": false
    },
    {
      "PostID": 5414,
      "Partition": "学习交流",
      "UserID": 1008,
      "UserName": "三叶草王国魔法帝",
      "UserScore": 81,
      "UserTelephone": "715****5472",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1778559061946767901_mmexport1778292315370.jpg",
      "UserIdentity": "student",
      "Title": "公选严肃选课中",
      "Content": "公选课咋整，有没有有意思的课，或者比较简单，要求不高的课推荐！",
      "Like": 0,
      "Comment": 0,
      "Browse": 230,
      "Heat": 166,
      "PostTime": "2026-07-19T12:38:33+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false
    },
    {
      "PostID": 5409,
      "Partition": "学习交流",
      "UserID": 840,
      "UserName": "szcoast",
      "UserScore": 70,
      "UserTelephone": "753****5426",
      "UserAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1782469459472537477_1000008407.jpg",
      "UserIdentity": "student",
      "Title": "体育课代课怎么找",
      "Content": "帮朋友问的，主播是不可能干得出来逃课这种事的，我也坚决反对这种行为",
      "Like": 2,
      "Comment": 6,
      "Browse": 534,
      "Heat": 294,
      "PostTime": "2026-07-18T03:08:49+08:00",
      "IsSaved": false,
      "IsLiked": false,
      "IsWatched": false,
      "Photos": "",
      "Tag": "",
      "IsPrivate": false,
      "isAnonymous": false,
      "isOwner": false,
      "isPinned": false,
      "hotComment": {
        "id": 14777,
        "userID": 952,
        "userName": "lllllllx",
        "content": "可以在校园集市里发贴找长期，也可以用集市里的跑腿功能",
        "likeNum": 0,
        "createdAt": "2026-07-18T23:35:14+08:00"
      }
    },
    "…(共 15 項,完整數據見 captures2.json)"
  ],
  "total": 0
}
```

---

## 25. `POST /api/auth/userProfilePostNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "userTelephone": "961****4135",
  "targetUserID": 1150
}
```

**Response Body:**
```json
{
  "Postcount": 0
}
```

---

## 26. `POST /api/auth/userProfilePosts`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "userTelephone": "961****4135",
  "targetUserID": 1150,
  "limit": 15,
  "offset": 0
}
```

**Response Body:**
```json
[]
```

---

## 27. `POST /api/auth/showDetails`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "PostID": 5671,
  "UserID": 0,
  "UserName": "匿名用户",
  "UserScore": 0,
  "UserTelephone": "",
  "UserAvatar": "",
  "UserIdentity": "",
  "Title": "大三体育有室内然后比较简单的吗",
  "Content": "如题，看了很久有点想选体能，但是怕很累",
  "Like": 0,
  "Comment": 2,
  "Browse": 104,
  "Heat": 84,
  "PostTime": "2026-08-25T00:44:41+08:00",
  "IsSaved": false,
  "IsLiked": false,
  "IsWatched": false,
  "Photos": "",
  "Tag": "",
  "IsPrivate": false,
  "isAnonymous": true,
  "isOwner": false,
  "IsLottery": false,
  "isPinned": false
}
```

---

## 28. `POST /api/auth/updateBrowseNum`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
"(body 不可讀)"
```

---

## 29. `POST /api/auth/post`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(發帖),未觸發

**Request Body:**
```json
{
  "content": "正文",
  "partition": "主页",
  "photos": "url1|url2",
  "tagList": [],
  "title": "標題",
  "userTelephone": "961****4135",
  "isPrivate": false,
  "isAnonymous": false,
  "pinned": false
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "發布成功",
  "data": {
    "postID": 0
  }
}
```

---

## 30. `POST /api/auth/deletePost`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "postID": 5671
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "刪除成功"
}
```

---

## 31. `POST /api/auth/pinPost`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(置頂),未觸發

**Request Body:**
```json
{
  "postID": 5671
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 32. `POST /api/auth/unpinPost`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "postID": 5671
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 33. `POST /api/auth/updateLike`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(點讚),未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 34. `POST /api/auth/updateSave`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(收藏),未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 35. `POST /api/auth/toggleWatch`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(關注),未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 36. `POST /api/auth/updatePostPrivacy`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135",
  "isPrivate": true
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 37. `POST /api/auth/searchPostsByTitle`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 投票頁搜索用,未觸發

**Request Body:**
```json
{
  "keyword": "關鍵詞",
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "ok",
  "data": {
    "posts": [
      {
        "postID": 0,
        "title": "…",
        "partition": "…",
        "postTime": "…",
        "voteCount": 0
      }
    ]
  }
}
```

---

# 評論 Comments

## 38. `POST /api/auth/showPcomments`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135",
  "postType": "post"
}
```

**Response Body:**
```json
[
  {
    "PcommentID": 15393,
    "AuthorID": 20,
    "Author": "明月挤石油",
    "AuthorTelephone": "245****9638",
    "AuthorScore": 39,
    "AuthorAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1762879891416173421_IMG_0142.jpeg",
    "AuthorIdentity": "student",
    "CommentTime": "2026-08-25T00:50:10+08:00",
    "Content": "击剑挺好的 ，给分也不错。不过上学期一般都在做体测",
    "LikeNum": 0,
    "DenyNum": 0,
    "SubComments": [
      {
        "ccommentID": 10836,
        "author": "匿名用户",
        "authorID": 0,
        "authorScore": 0,
        "authorTelephone": "",
        "authorAvatar": "",
        "authorIdentity": "",
        "commentTime": "2026-08-25T00:50:46+08:00",
        "content": "@明月挤石油 我大二选过了现在没有了😭😭",
        "likeNum": 0,
        "denyNum": 0,
        "isLiked": false,
        "isDenied": false,
        "userTargetName": "",
        "showMenu": false
      }
    ],
    "IsLiked": false,
    "IsDenied": false
  }
]
```

---

## 39. `POST /api/auth/postPcomment`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(一級評論),未觸發

**Request Body:**
```json
{
  "content": "評論內容",
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 40. `POST /api/auth/postCcomment`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(二級回覆),未觸發;字段為源碼推斷

**Request Body:**
```json
{
  "content": "回覆內容",
  "pcommentID": 15393,
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 41. `POST /api/auth/deletePcomment`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "pcommentID": 15393
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 42. `POST /api/auth/deleteCcomment`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "ccommentID": 0
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 43. `POST /api/auth/updatePcommentLike`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "pcommentID": 15393,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 44. `POST /api/auth/updateCcommentLike`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "ccommentID": 0,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# 打分 Rating

## 45. `POST /api/auth/rating/category/list`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{}
```

**Response Body:**
```json
[
  {
    "categoryID": 11,
    "name": "中珠外卖",
    "description": "欢迎大家share一下自己的午饭和晚饭",
    "postCount": 4,
    "isOfficial": false,
    "sortOrder": 102
  },
  {
    "categoryID": 9,
    "name": "中珠校内各食堂窗口",
    "description": "欢迎大家share一下自己非常喜欢的饭菜或者非常避雷的窗口",
    "postCount": 3,
    "isOfficial": false,
    "sortOrder": 100
  },
  {
    "categoryID": 7,
    "name": "其他",
    "description": "未归类主题",
    "postCount": 14,
    "isOfficial": true,
    "sortOrder": 99
  }
]
```

---

## 46. `POST /api/auth/rating/post/list`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "categoryID": 0,
  "searchinfo": "",
  "limit": 20,
  "offset": 0
}
```

**Response Body:**
```json
[
  {
    "ratingPostID": 4545,
    "categoryID": 7,
    "categoryName": "其他",
    "userID": 815,
    "userName": "苏书",
    "userScore": 3632,
    "userTelephone": "370****9254",
    "userAvatar": "",
    "userIdentity": "student",
    "title": "学院是否应当削减学分（包括专选和专必学分）",
    "content": "选“是”：打五颗星\n选“不是”：打一颗星\n选“观望/钝角”：打三颗星\n\n当前软件工程专业专必学分 88 个，专选学分 24 个。\n\n支持削减的理由：\n1、单个专选课程的学分普遍较少，导致学生需要选很多专选课程来满足毕业要求，导致专选某种程度上变成了“必选”，削减专选学分可以让学生把精力集中在自己想学的东西上。\n2、部分专必课程设计陈旧，任课老师也觉得是水课，浪费大家的时间。\n3、减少不必要的课业压力，留出时间给学生做科研、实习，前者可以帮助学生升学，后者可以帮助学生就业，在 AI时代，实践带给学生的成长要远比上课高。（AI 使得“编程”这项技能的价值变低，做产品/做研究的能力的相对价值变高。）\n4、减少老师的授课压力，给老师留出更多时间做横向/做科研。\n\n支持不削减的理由：\n1、未知的可能的学校教务阻力\n2、对自控力弱的学生“托底”作用降低，部分学生可能直接开摆（但其实如果课程水水的，给学生体验闲适的大学生活也没什么不好？）\n3、教育部/省厅的本科教学评估硬性指标\n4、教师的“课时费”和“教学工作量”考核指标无法完成\n5、其他学生视角不可知的理由",
    "like": 2,
    "comment": 2,
    "browse": 383,
    "createdAt": "2026-06-29T19:14:59+08:00",
    "isLiked": false,
    "photos": "",
    "averageRating": 4.6,
    "stars": [
      0,
      0,
      9,
      "…(共 5 項,完整數據見 captures2.json)"
    ],
    "raterCount": 45
  },
  {
    "ratingPostID": 4544,
    "categoryID": 11,
    "categoryName": "中珠外卖",
    "userID": 278,
    "userName": "秋",
    "userScore": 8021,
    "userTelephone": "077****0231",
    "userAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1760621207455106317_Image_295162979911204.jpg",
    "userIdentity": "student",
    "title": "三叔粥铺",
    "content": "炒米粉还可以，价钱很便宜，偶尔清淡点可以吃粥，健康早餐这一块属于是",
    "like": 0,
    "comment": 1,
    "browse": 106,
    "createdAt": "2026-05-23T02:42:26+08:00",
    "isLiked": false,
    "photos": "",
    "averageRating": 4.5,
    "stars": [
      0,
      1,
      0,
      "…(共 5 項,完整數據見 captures2.json)"
    ],
    "raterCount": 6
  },
  {
    "ratingPostID": 4543,
    "categoryID": 11,
    "categoryName": "中珠外卖",
    "userID": 501,
    "userName": "    ",
    "userScore": 805,
    "userTelephone": "869****1107",
    "userAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1727625234407544627_BeA2tKmig.jpg",
    "userIdentity": "student",
    "title": "缓归岭南融合菜 酸菜鱼",
    "content": "鱼的肉质不错，汤很鲜美，辣度适中，饭用的米也属上等，唯一的缺点是小贵。很推荐",
    "like": 0,
    "comment": 0,
    "browse": 72,
    "createdAt": "2026-05-22T19:42:41+08:00",
    "isLiked": false,
    "photos": "",
    "averageRating": 4,
    "stars": [
      0,
      1,
      0,
      "…(共 5 項,完整數據見 captures2.json)"
    ],
    "raterCount": 3
  },
  "…(共 20 項,完整數據見 captures2.json)"
]
```

---

## 47. `POST /api/auth/rating/post/detail`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "ratingPostID": 4545
}
```

**Response Body:**
```json
{
  "ratingPostID": 4545,
  "categoryID": 7,
  "categoryName": "其他",
  "userID": 815,
  "userName": "苏书",
  "userScore": 3632,
  "userTelephone": "370****9254",
  "userAvatar": "",
  "userIdentity": "student",
  "title": "学院是否应当削减学分（包括专选和专必学分）",
  "content": "选“是”：打五颗星\n选“不是”：打一颗星\n选“观望/钝角”：打三颗星\n\n当前软件工程专业专必学分 88 个，专选学分 24 个。\n\n支持削减的理由：\n1、单个专选课程的学分普遍较少，导致学生需要选很多专选课程来满足毕业要求，导致专选某种程度上变成了“必选”，削减专选学分可以让学生把精力集中在自己想学的东西上。\n2、部分专必课程设计陈旧，任课老师也觉得是水课，浪费大家的时间。\n3、减少不必要的课业压力，留出时间给学生做科研、实习，前者可以帮助学生升学，后者可以帮助学生就业，在 AI时代，实践带给学生的成长要远比上课高。（AI 使得“编程”这项技能的价值变低，做产品/做研究的能力的相对价值变高。）\n4、减少老师的授课压力，给老师留出更多时间做横向/做科研。\n\n支持不削减的理由：\n1、未知的可能的学校教务阻力\n2、对自控力弱的学生“托底”作用降低，部分学生可能直接开摆（但其实如果课程水水的，给学生体验闲适的大学生活也没什么不好？）\n3、教育部/省厅的本科教学评估硬性指标\n4、教师的“课时费”和“教学工作量”考核指标无法完成\n5、其他学生视角不可知的理由",
  "like": 2,
  "comment": 2,
  "browse": 384,
  "createdAt": "2026-06-29T19:14:59+08:00",
  "isLiked": false,
  "photos": "",
  "averageRating": 4.6,
  "stars": [
    0,
    0,
    9,
    "…(共 5 項,完整數據見 captures2.json)"
  ],
  "raterCount": 45,
  "userStar": 0
}
```

---

## 48. `POST /api/auth/rating/comment/list`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "ratingPostID": 4545
}
```

**Response Body:**
```json
[
  {
    "commentID": 12795,
    "authorID": 286,
    "author": "yxsu",
    "authorTelephone": "548****1438",
    "authorScore": 2576,
    "authorAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1737340555369280154_休息者.png",
    "authorIdentity": "teacher",
    "commentTime": "2026-06-30T22:14:49+08:00",
    "content": "我来说几条扎老登们心的事：从25级开始，大二开始专必课学分开始降一些了，比如软需由3分降至2分，操作系统由4分降至3分，数据库由3分降至2分。从26级开始，专选课将不受限制，可以全校范围内任选。极端情况下，只要学分修够，一门软工的专选都不选，也可以拿软工毕业证。",
    "likeNum": 6,
    "isLiked": false,
    "authorRating": 0
  },
  {
    "commentID": 12794,
    "authorID": 278,
    "author": "秋",
    "authorTelephone": "077****0231",
    "authorScore": 8021,
    "authorAvatar": "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/resized/1760621207455106317_Image_295162979911204.jpg",
    "authorIdentity": "student",
    "commentTime": "2026-06-29T19:32:53+08:00",
    "content": "如果多一些像实训这样，通过交成果来获取学分的方式将不知道有多爽😋不过跟我们老登是无缘了，新的课程安排其实感觉还挺与时俱进的，院长他们应该也是下了不少功夫的，改革效率这一块软工是真的顶",
    "likeNum": 13,
    "isLiked": false,
    "authorRating": 5
  }
]
```

---

## 49. `POST /api/auth/rating/category/create`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "name": "分類名",
  "description": "描述",
  "syncFeedPost": true
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 50. `POST /api/auth/rating/post/create`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發;字段為源碼推斷

**Request Body:**
```json
{
  "categoryID": 1,
  "title": "標題",
  "content": "內容"
}
```

**Response Body:**
```json
{
  "ratingPostID": 0
}
```

---

## 51. `POST /api/auth/rating/post/delete`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "ratingPostID": 4545
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 52. `POST /api/auth/rating/post/like`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "ratingPostID": 4545
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 53. `POST /api/auth/rating/comment/create`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "ratingPostID": 4545,
  "content": "評論",
  "starNum": 5
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 54. `POST /api/auth/rating/comment/like`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "commentID": 0
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 55. `POST /api/auth/rating/star/submit`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(打分),未觸發

**Request Body:**
```json
{
  "ratingPostID": 4545,
  "starNum": 4
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# 搜索 RAG

## 56. `GET /api/rag-local/hot-queries`
Query: `?limit=8`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "ok": true,
  "data": [
    {
      "query": "六级",
      "count": 9,
      "last_seen": 1787540735,
      "recommend_score": 93
    },
    {
      "query": "进组报销",
      "count": 8,
      "last_seen": 1787387741,
      "recommend_score": 83
    },
    {
      "query": "进组导师推荐",
      "count": 6,
      "last_seen": 1787583900,
      "recommend_score": 63
    },
    "…(共 8 項,完整數據見 captures2.json)"
  ]
}
```

---

## 57. `GET /api/rag-local/search`
Query: `?q=%E5%85%AD%E7%BA%A7&limit=5&source=manual`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發;查詢參數 q/limit/source

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "ok": true,
  "results": [
    "(RAG 檢索結果,需實測確認字段)"
  ]
}
```

---

# 商店 Shop

## 58. `POST /api/auth/getProducts`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "searchinfo": "",
  "searchsort": "home",
  "limit": 80,
  "offset": 0
}
```

**Response Body:**
```json
[
  {
    "SellerID": 303,
    "ProductID": 51,
    "Seller": "阿哈",
    "Price": 2,
    "Name": "床头置物架",
    "Description": "床头置物架，2元1个\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728676320018256_IMG_20260629_182219.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728677309905880_IMG_20260629_182210.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-29T18:24:38+08:00"
  },
  {
    "SellerID": 303,
    "ProductID": 50,
    "Seller": "阿哈",
    "Price": 15,
    "Name": "流萤，开拓者徽章",
    "Description": "同人徽章 流萤10元，开拓者7元。一起买15元\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399431389279444_MVIMG_20260625_225355_1.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399433544654810_MVIMG_20260625_224350.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399435433432661_MVIMG_20260625_224350.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-25T22:57:16+08:00"
  },
  {
    "SellerID": 303,
    "ProductID": 49,
    "Seller": "阿哈",
    "Price": 15,
    "Name": "崩铁古茗联动徽章",
    "Description": "13元2个徽章，8元1个徽章。徽章套子随送，可以方便挂在书包上\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399129314864143_MVIMG_20260625_223230.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-25T22:52:10+08:00"
  },
  "…(共 31 項,完整數據見 captures2.json)"
]
```

---

## 59. `POST /api/auth/getProducts`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "searchinfo": "",
  "searchsort": "home",
  "limit": 12,
  "offset": 0
}
```

**Response Body:**
```json
[
  {
    "SellerID": 303,
    "ProductID": 51,
    "Seller": "阿哈",
    "Price": 2,
    "Name": "床头置物架",
    "Description": "床头置物架，2元1个\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728676320018256_IMG_20260629_182219.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728677309905880_IMG_20260629_182210.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-29T18:24:38+08:00"
  },
  {
    "SellerID": 303,
    "ProductID": 50,
    "Seller": "阿哈",
    "Price": 15,
    "Name": "流萤，开拓者徽章",
    "Description": "同人徽章 流萤10元，开拓者7元。一起买15元\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399431389279444_MVIMG_20260625_225355_1.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399433544654810_MVIMG_20260625_224350.jpg",
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399435433432661_MVIMG_20260625_224350.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-25T22:57:16+08:00"
  },
  {
    "SellerID": 303,
    "ProductID": 49,
    "Seller": "阿哈",
    "Price": 15,
    "Name": "崩铁古茗联动徽章",
    "Description": "13元2个徽章，8元1个徽章。徽章套子随送，可以方便挂在书包上\nwx：hhhxin233",
    "Photos": [
      "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782399129314864143_MVIMG_20260625_223230.jpg"
    ],
    "ISSold": false,
    "ISAnonymous": false,
    "PostTime": "2026-06-25T22:52:10+08:00"
  },
  "…(共 12 項,完整數據見 captures2.json)"
]
```

---

## 60. `POST /api/auth/getProducts`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "searchinfo": "",
  "searchsort": "history",
  "limit": 80,
  "offset": 0
}
```

**Response Body:**
```json
[]
```

---

## 61. `POST /api/auth/getProductDetail`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "productID": 51
}
```

**Response Body:**
```json
{
  "SellerID": 303,
  "ProductID": 51,
  "Seller": "阿哈",
  "Price": 2,
  "Name": "床头置物架",
  "Description": "床头置物架，2元1个\nwx：hhhxin233",
  "Photos": [
    "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728676320018256_IMG_20260629_182219.jpg",
    "https://sse-market-source-1320172928.cos.ap-guangzhou.myqcloud.com/src/images/uploads/1782728677309905880_IMG_20260629_182210.jpg"
  ],
  "ISSold": false,
  "ISAnonymous": false,
  "PostTime": "2026-06-29T18:24:38+08:00"
}
```

---

## 62. `POST /api/auth/postProduct`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(上架),未觸發

**Request Body:**
```json
{
  "UserID": 1232,
  "Price": 1000,
  "Title": "商品名",
  "Content": "描述",
  "Photos": [],
  "ISAnonymous": false,
  "syncFeedPost": true
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "ProductID": 0
  }
}
```

---

## 63. `POST /api/auth/deleteProduct`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "productID": 51
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 64. `POST /api/auth/saleProduct`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(標記已售),未觸發

**Request Body:**
```json
{
  "productID": 51
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# 投票排行 Vote/Rank/Heat

## 65. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 6 次)

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 66. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5666,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 67. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5656,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 68. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5659,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 69. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5670,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 70. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5653,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 71. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5665,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 72. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5660,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 73. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5658,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 74. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5651,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 75. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5669,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 76. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5668,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 77. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5667,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 78. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5657,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 79. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 5 次)

**Request Body:**
```json
{
  "postID": 5652,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 80. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4917,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 81. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 5012,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 82. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4797,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 83. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4883,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 84. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4893,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 85. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4849,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 86. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4825,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 87. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4801,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 88. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4795,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 89. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4900,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 90. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4811,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 91. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4845,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 92. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 5006,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 93. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4987,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 94. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
```json
{
  "postID": 4961,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 95. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5624,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 96. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5600,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 97. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5634,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 98. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 4 次)

**Request Body:**
```json
{
  "postID": 5582,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 99. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 4 次)

**Request Body:**
```json
{
  "postID": 5598,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 100. `GET /api/auth/calculateHeat`

- **✅ 實測** · HTTP 200

**Request Body:**
_(無)_

**Response Body:**
```json
[
  {
    "PostID": 5665,
    "Title": "六级",
    "Heat": 401
  },
  {
    "PostID": 5667,
    "Title": "26届保研",
    "Heat": 261
  },
  {
    "PostID": 5668,
    "Title": "今年秋招特别难吗",
    "Heat": 232
  },
  "…(共 10 項,完整數據見 captures2.json)"
]
```

---

## 101. `GET /api/auth/postRanking`

- **✅ 實測** · HTTP 200

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "ranking": [
      {
        "postID": 5069,
        "title": "随便抽个奖 3.0",
        "partition": "生活日常",
        "voteCount": 62,
        "postTime": "2026-06-12 16:07:38"
      },
      {
        "postID": 4935,
        "title": "竞赛究竟重要吗？",
        "partition": "学习交流",
        "voteCount": 13,
        "postTime": "2026-05-22 13:52:58"
      },
      {
        "postID": 5030,
        "title": "集市期末资料分类汇总",
        "partition": "期末资料",
        "voteCount": 11,
        "postTime": "2026-06-07 12:40:47"
      },
      "…(共 100 項,完整數據見 captures2.json)"
    ]
  },
  "msg": "ok"
}
```

---

## 102. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5436,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 103. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5414,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 104. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5409,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 105. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5386,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 106. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5384,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 107. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5383,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 108. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5374,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 109. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5369,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 110. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5342,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 111. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5337,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 112. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5300,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 113. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5295,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 114. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5291,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 115. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5240,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 116. `POST /api/auth/checkUserVoted`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
```json
{
  "postID": 5201,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "voted": false
  },
  "msg": "ok"
}
```

---

## 117. `POST /api/auth/submitVote`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(投票),未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "msg": "投票成功",
  "data": {
    "voted": true
  }
}
```

---

## 118. `GET /api/auth/userRanking`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發(排行頁僅調 postRanking)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "ranking": [
      {
        "userID": 0,
        "name": "…",
        "voteCount": 0
      }
    ]
  }
}
```

---

# 課程 Course

## 119. `GET /api/auth/getTags`
Query: `?type=course?`

- **✅ 實測** · HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "tags": [
      {
        "ID": 1,
        "Name": "苏玉鑫",
        "Value": "suyx35@mail.sysu.edu.cn",
        "Type": "course",
        "Num": 0
      },
      {
        "ID": 2,
        "Name": "林建入",
        "Value": "2696834883@qq.com",
        "Type": "course",
        "Num": 0
      },
      {
        "ID": 3,
        "Name": "SSE_MARKET",
        "Value": "wuyh223@mail2.sysu.edu.cn",
        "Type": "course",
        "Num": 0
      },
      "…(共 12 項,完整數據見 captures2.json)"
    ]
  },
  "msg": "获取tag列表成功！"
}
```

---

# 簡歷 Resume

## 120. `POST /api/auth/resume/list`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "searchinfo": "",
  "searchsort": "home",
  "limit": 200,
  "offset": 0
}
```

**Response Body:**
```json
[
  {
    "resumeID": 21,
    "userID": 0,
    "uploader": "匿名用户",
    "title": "暑期实习前端简历",
    "description": "",
    "fileName": "简历.jpg",
    "fileSize": 535558,
    "mimeType": "image/jpeg",
    "fileExt": "jpg",
    "downloadNum": 30,
    "viewNum": 425,
    "isAnonymous": true,
    "isOwner": false,
    "canPreview": true,
    "createdAt": "2026-05-27 16:19"
  },
  {
    "resumeID": 20,
    "userID": 290,
    "uploader": "ciallo~",
    "title": "对游戏开发感兴趣的同学可以看下~",
    "description": "秋招用的简历，现在回头看还是青涩了一点:D",
    "fileName": "简历.png",
    "fileSize": 331149,
    "mimeType": "image/png",
    "fileExt": "png",
    "downloadNum": 23,
    "viewNum": 348,
    "isAnonymous": false,
    "isOwner": false,
    "canPreview": true,
    "createdAt": "2026-05-22 22:39"
  },
  {
    "resumeID": 19,
    "userID": 0,
    "uploader": "匿名用户",
    "title": "大三下cpp",
    "description": "如果让我重来一次，我会建议大伙大一下大二上去弄计算机公开课cmu15445之类的，我前司就有大二双非靠cmu面进来",
    "fileName": "简历.png",
    "fileSize": 796526,
    "mimeType": "image/png",
    "fileExt": "png",
    "downloadNum": 19,
    "viewNum": 490,
    "isAnonymous": true,
    "isOwner": false,
    "canPreview": true,
    "createdAt": "2026-05-21 00:24"
  },
  "…(共 10 項,完整數據見 captures2.json)"
]
```

---

## 121. `POST /api/auth/resume/list`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "searchinfo": "",
  "searchsort": "my",
  "limit": 200,
  "offset": 0
}
```

**Response Body:**
```json
[]
```

---

## 122. `POST /api/auth/resume/detail`

- **✅ 實測** · HTTP 200

**Request Body:**
```json
{
  "resumeID": 21
}
```

**Response Body:**
```json
{
  "resumeID": 21,
  "userID": 0,
  "uploader": "匿名用户",
  "title": "暑期实习前端简历",
  "description": "",
  "fileName": "简历.jpg",
  "fileSize": 535558,
  "mimeType": "image/jpeg",
  "fileExt": "jpg",
  "downloadNum": 30,
  "viewNum": 426,
  "isAnonymous": true,
  "isOwner": false,
  "canPreview": true,
  "createdAt": "2026-05-27 16:19"
}
```

---

## 123. `POST /api/auth/resume/update`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "resumeID": 21,
  "title": "簡歷標題",
  "description": "描述"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 124. `POST /api/auth/resume/delete`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "resumeID": 21
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 125. `POST /api/auth/resume/download`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
```json
{
  "resumeID": 21
}
```

**Response Body:**
```json
"(文件流/下載地址)"
```

---

# 消息聊天 Chat

## 126. `GET /api/auth/getChatNotice`
Query: `?userID=1232`

- **✅ 實測** · HTTP 200 ·(同型請求出現 4 次)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "noticeNum": 0
  },
  "msg": "获取未读消息成功"
}
```

---

## 127. `WEBSOCKET wss://ssemarket.cn/websocket/auth/chat`
Query: `?token=eyJhbGciOi…[已遮蔽]`
> JWT 為登錄返回的 access token(HS256,payload 含 UserID/iss/loginTest/exp,7 天有效)

- **✅ 實測** · 預期 HTTP 200 ·(同型請求出現 2 次)

**Request Body:**
_(無)_

**Response Body:**
```json
"(websocket 連接)"
```

---

## 128. `GET /api/auth/getChatHistory`
Query: `?senderUserID=0&pageSize=20`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發(需打開具體聊天)

**Request Body:**
_(無)_

**Response Body:**
```json
"(聊天記錄數組)"
```

---

## 129. `GET /api/auth/leaveChatView`
Query: `?senderUserID=0`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
_(無)_

**Response Body:**
```json
"(狀態)"
```

---

## 130. `POST /api/auth/recallChatMessage`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(撤回),未觸發

**Request Body:**
```json
{
  "chatMsgID": 0
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# 通知 Notice

## 131. `GET /api/auth/getNoticeNum`

- **✅ 實測** · HTTP 200 ·(同型請求出現 3 次)

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "totalNum": 29,
  "unreadTotalNum": 0,
  "readTotalNum": 29
}
```

---

## 132. `GET /api/auth/getNotice`
Query: `?requireID=0&pageSize=20&read=0`

- **✅ 實測** · HTTP 200

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 201,
  "data": null,
  "msg": "没有更多通知"
}
```

---

## 133. `PATCH /api/auth/readNotice/0`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(已讀),未觸發

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 200
}
```

---

# 抽獎 Lottery

## 134. `POST /api/auth/lottery/create`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發;字段為源碼推斷

**Request Body:**
```json
{
  "postID": 0,
  "prizes": [],
  "participantLimit": 0
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 135. `POST /api/auth/lottery/detail`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發(帖子需帶抽獎)

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {}
}
```

---

## 136. `POST /api/auth/lottery/participate`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型(參與抽獎),未觸發

**Request Body:**
```json
{
  "postID": 5671,
  "userTelephone": "961****4135"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# 用戶與其他 Misc

## 137. `POST /api/auth/updateUserInfo`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "avatarURL": "",
  "intro": "簡介",
  "name": "暱稱",
  "userID": 1232,
  "hideProfilePosts": false
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 138. `POST /api/auth/changeEmailPush`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "user_id": 1232
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 139. `POST /api/auth/submitFeedback`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "ftext": "反饋內容",
  "attachment": ""
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 140. `POST /api/auth/statistics`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發(年報活動期外)

**Request Body:**
_(無)_

**Response Body:**
```json
"(年報統計數據)"
```

---

## 141. `POST /api/auth/resolveMentions`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
```json
{
  "names": [
    "用戶名"
  ]
}
```

**Response Body:**
```json
"(提及解析結果)"
```

---

## 142. `POST /api/auth/connect/authorize`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發;字段為源碼推斷

**Request Body:**
```json
{
  "app_id": "…",
  "scopes": []
}
```

**Response Body:**
```json
"(授權結果)"
```

---

## 143. `POST /api/auth/connect/check`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
```json
{
  "app_id": "…"
}
```

**Response Body:**
```json
"(連接狀態)"
```

---

# 個人令牌 Tokens

## 144. `GET /api/auth/token/list`
Query: `?page=1`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
_(無)_

**Response Body:**
```json
"(個人令牌列表)"
```

---

## 145. `GET /api/auth/token/scopes`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 未觸發

**Request Body:**
_(無)_

**Response Body:**
```json
"(可用 scope 列表)"
```

---

## 146. `POST /api/auth/token/create`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 寫入型,未觸發

**Request Body:**
```json
{
  "name": "令牌名",
  "scopes": []
}
```

**Response Body:**
```json
{
  "code": 200,
  "data": {
    "token": "…[已遮蔽]"
  }
}
```

---

## 147. `POST /api/auth/token/delete`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "token_id": "…[已遮蔽]"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

## 148. `POST /api/auth/token/revoke`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · ⚠️ 破壞性,未觸發

**Request Body:**
```json
{
  "token_id": "…[已遮蔽]"
}
```

**Response Body:**
```json
{
  "code": 200
}
```

---

# AI Agent / MCP

## 149. `GET /api/v1/agent/conversation/bootstrap`

- **✅ 實測** · HTTP 200

**Request Body:**
_(無)_

**Response Body:**
```json
{
  "code": 0,
  "data": {
    "session_id": "1b11af19-d947-4adc-89c3-841fd0d4e7c1",
    "segment_seq": 0,
    "archived": false,
    "messages": []
  },
  "msg": "ok",
  "request_id": "002d60fb-9fb5-4d44-b452-975809dd3d4b"
}
```

---

## 150. `POST /api/v1/agent/mcp`

- **⚠️ 未實測(源碼推導)** · 預期 HTTP 200 · 需個人令牌 Bearer PAT;官方對外 AI 接口

**Request Body:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "client",
      "version": "1.0"
    }
  }
}
```

**Response Body:**
```json
"(MCP JSON-RPC 響應)"
```

---

