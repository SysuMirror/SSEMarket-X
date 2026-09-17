/// API 全域設定
///
/// [baseUrl] 原本寫死在 api_service.dart 的 `_baseUrl`。
/// 未來應改用 `--dart-define` 支援環境切換(本次不做)。
class ApiConfig {
  static const String baseUrl = 'https://ssemarket.cn/api';
}
