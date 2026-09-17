# 登入 / 註冊 / 重設密碼 / SSO(原始標題:「欢迎回来」「创建账号」「重置密码」等)

- 路由:`/auth/login`(Login)、`/auth/register`(Register)、`/auth/reset`(Reset)、`/auth/sso/result`(SsoResult)、`/auth/sso/bind`(SsoBind)
- 來源:JS bundle 分析(LoginView、RegisterView、ResetView、SsoResultView、SsoBindView、forgetPwd、sso、index-pcgjWmeH.js)

## 用途
帳號認證全家:郵箱+密碼登入(AES)、註冊(邀請碼+驗證碼)、忘記密碼、UniSSO 單點登入與綁定。

## UI 結構
- **登入**:FormContainer title「欢迎回来」subtitle「使用邮箱登录你的账号」;欄位「邮箱」「密码」;checkbox「记住我」(rememberMe → localStorage 持久化 refresh token);連結「注册账号」「忘记密码」;按鈕「使用 UniSSO 登录」(→ `/api/sso/login` 跳轉);送出「登录」。toast:「请填写完整信息」「登录失败」。
- **註冊**:title「创建账号」subtitle「填写信息完成注册，验证码将发送至邮箱」;欄位「用户名」「邮箱」「密码」「确认密码」「验证码」+「发送验证码」(先驗郵箱「请先填写有效邮箱」)、「邀请码」(CDKey);「记住我/下次自动登录」;「已有账号」。成功:「注册成功，已自动登录」(自動調 login)或「注册成功，但登录信息异常，请手动登录」。
- **重設**:title「重置密码」subtitle「验证邮箱后设置新密码」;欄位「邮箱」「新密码」「确认新密码」「验证码」+「发送验证码」;密碼規則提示「密码需含大小写字母、数字与特殊字符，长度 8–12 位，且两次输入一致」(regex:`^(?![a-zA-Z]+$)(?![A-Z0-9]+$)(?![A-Z\W_]+$)(?![a-z0-9]+$)(?![a-z\W_]+$)(?![0-9\W_]+$)[\s\S]{8,12}`);「确认重置」「返回登录」。
- **SSO 結果頁**(`/auth/sso/result?ticket=&error=`):僅「正在处理 SSO 登录结果…」;錯誤映射:「state→登录状态已过期或已使用…」「exchange→SSO 服务暂时不可用…」「conflict→该 SSO 账号已绑定其他集市账号」(預設「SSO 登录失败，请重试」)。
- **SSO 綁定頁**(`/auth/sso/bind?ticket&sso_email&sso_username`):title「绑定集市账号」;「当前 SSO 身份：{sso_username||sso_email||未知}」;欄位「集市账号邮箱」(預填 sso_email)、「集市账号密码」;說明「输入已注册的集市账号邮箱与密码，验证通过即完成绑定并登录。」「还没有账号？先注册，注册后可在「设置 → 账号绑定」中绑定此 SSO。」;按鈕「验证并绑定」。

## API 呼叫
| 端點 | Method | 參數 | 觸發時機 | 是否實測 | 備註 |
|---|---|---|---|---|---|
| /api/auth/login | POST | `{email, password:AES(密碼)}` | 登入/註冊後自動登入 | 擷取檔#1 | 回 `data.token`+`data.refresh_token` |
| /api/auth/register | POST | `{CDKey, email, name, password:AES, password2:AES, phone:"", valiCode}` | 註冊 | — | |
| /api/auth/validateEmail | POST | `{email, mode:0(註冊)/1(重設)}` | 發送驗證碼 | 擷取檔#10 | |
| /api/auth/modifyPassword | POST | `{email, password:AES, password2:AES, valiCode}` | 重設密碼 | — | **忘記密碼實際走此端點** |
| /api/sso/login | GET(跳轉) | — | 「使用 UniSSO 登录」 | — | 組 URL 後 location 跳轉 |
| /api/sso/exchange | POST | `{ticket}`(無auth) | SSO 回跳 result 頁 | — | 回 `data`:type "bind_needed"(→ 綁定頁)/ "bound" + token 組 |
| /api/sso/bind | POST | `{ticket, email, password:AES}`(無auth) | 綁定頁送出 | — | 回 token 組;錯誤「绑定凭证已失效，请重新发起 SSO 登录」「绑定失败」 |

## 登入後流程
setToken/setRefreshToken(rememberMe=true 時持久化)→ GET `/auth/info` 補 userInfo → `replace(redirect 参数或 "/")`。

## 分頁
無。

## 導向
登入成功 → `redirect` 參數或 `/`;SSO 綁定成功 → `/`;錯誤 → 停留/回 `/auth/login`。

## 需登入?
否(此區為公開路由;router guard 放行 `/auth/*`)。

## 未確認事項
- `/auth/reset` 端點(擷取檔 #9 出現)在現行 bundle 未见呼叫——推測舊版遺留;密碼欄位在舊版也可能名為 `password` 而非現行 AES 密文,**未確認**。
- CDKey(邀請碼)格式規則。
- SSO ticket 的有效期與單次性(由錯誤文案推得單次有效)。
