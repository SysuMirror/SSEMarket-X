import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/product_model.dart';

/// 闲置商品 API 服务
class ShopService {
  final ApiClient _client;

  ShopService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  /// 获取商品列表
  /// [type] - 'home' 热门商品, 'history' 我的商品
  Future<List<ProductModel>> getProducts(String searchSort) async {
    if (token.isEmpty) return [];

    final uri = Uri.parse('${_client.baseUrl}/auth/getProducts');
    final body = jsonEncode(<String, dynamic>{
      'searchinfo': '',
      'searchsort': searchSort,
      'limit': 1000,
      'offset': 0,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => ProductModel.fromDynamic(e)).toList();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => ProductModel.fromDynamic(e))
              .toList();
        }
        // 某些接口可能直接返回 Map，如果不是 List 也不是带 data 的 Map，可能就是空列表或者错误格式
        // 这里可以加一个 fallback，比如看看是否有 code 字段等
        if (data is Map) {
           // 尝试解析为单条数据（虽然不太可能）或者如果确实是空数据
           return [];
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('获取商品列表失败: $e');
      return [];
    }
  }

  /// 获取商品详情
  Future<ProductModel> getProductDetail(int productId) async {
    if (token.isEmpty) return ProductModel.empty();

    final uri = Uri.parse('${_client.baseUrl}/auth/getProductDetail');
    final body = jsonEncode(<String, dynamic>{
      'productID': productId,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return ProductModel.fromDynamic(jsonDecode(response.body));
      }
      return ProductModel.empty();
    } catch (e) {
      // ignore: avoid_print
      print('获取商品详情失败: $e');
      return ProductModel.empty();
    }
  }

  /// 发布闲置商品
  Future<bool> postProduct({
    required int userId,
    required int price,
    required String title,
    required String content,
    required List<String> photos,
  }) async {
    if (token.isEmpty || userId == 0) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/postProduct');
    final body = jsonEncode(<String, dynamic>{
      'UserID': userId,
      'Price': price,
      'Title': title,
      'Content': content,
      'Photos': photos,
      'ISAnonymous': false,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('发布商品失败: $e');
      return false;
    }
  }

  /// 标记商品为已售出
  Future<bool> markProductSold(int productId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/saleProduct');
    final body = jsonEncode(<String, dynamic>{
      'productID': productId,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('标记商品售出失败: $e');
      return false;
    }
  }

  /// 删除商品
  Future<bool> deleteProduct(int productId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/deleteProduct');
    final body = jsonEncode(<String, dynamic>{
      'productID': productId,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('删除商品失败: $e');
      return false;
    }
  }
}
