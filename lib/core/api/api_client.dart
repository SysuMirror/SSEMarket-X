import 'package:sse_market_x/core/api/api_config.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

/// API 共用層基底客戶端
class ApiClient {
  const ApiClient();

  String get baseUrl => ApiConfig.baseUrl;

  String get token => StorageService().token;

  /// 获取当前用户手机号（从存储服务）
  Future<String> getUserPhone() async {
    final storage = StorageService();
    final user = storage.user;
    return user?.phone ?? '';
  }
}
