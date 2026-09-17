import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/workbench_model.dart';

/// 工作台动态应用 API 服务
class WorkbenchService {
  final ApiClient _client;

  WorkbenchService({ApiClient client = const ApiClient()}) : _client = client;

  /// 获取后端动态下发的工作台应用（对应 /auth/workbench/apps）
  ///
  /// 全站唯一匿名 /auth/* 端点：不校验 token、不带 Authorization header。
  /// 响应为裸陣列（非 {code,data,msg} 外层）。失败静默返回空列表，
  /// 页面以内建清单照常可用。
  Future<List<WorkbenchApp>> getWorkbenchApps() async {
    final uri = Uri.parse('${_client.baseUrl}/auth/workbench/apps');

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return [];

      final dynamic json = jsonDecode(response.body);
      if (json is! List) return [];

      return json.map((e) => WorkbenchApp.fromDynamic(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('获取工作台应用失败: $e');
      return [];
    }
  }
}
