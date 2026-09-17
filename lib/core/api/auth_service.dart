import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/services/storage_service.dart';

class LoginResult {
  final String token;
  final String refreshToken;

  LoginResult({required this.token, this.refreshToken = ''});
}

/// 认证 API 服务
class AuthService {
  final ApiClient _client;

  AuthService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => StorageService().token;

  void setToken(String token) => StorageService().setToken(token);

  Future<LoginResult?> login(String email, String password) async {
    final encryptedPassword = _encryptPassword(password, '16bit secret key');

    final uri = Uri.parse('${_client.baseUrl}/auth/login');
    final body = jsonEncode(<String, dynamic>{
      'email': email,
      'password': encryptedPassword,
    });

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'];
    if (data is Map<String, dynamic> && data['token'] is String) {
      final token = data['token'] as String;
      final refreshToken = data['refresh_token'] is String
          ? data['refresh_token'] as String
          : '';
      return LoginResult(token: token, refreshToken: refreshToken);
    }

    return null;
  }

  String _encryptPassword(String data, String key) {
    final keyBytes = _zeroPaddedKey(key, 16);

    final sha = dart_crypto.sha256.convert(utf8.encode(key));
    final ivHex = sha.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final ivUtf8 = utf8.encode(ivHex);
    final ivBytes = Uint8List.fromList(ivUtf8.sublist(0, 16));

    final aesKey = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(data, iv: iv);
    final result = encrypted.base64;

    return result;
  }

  Uint8List _zeroPaddedKey(String key, int length) {
    final keyBytes = utf8.encode(key);
    if (keyBytes.length == length) {
      return Uint8List.fromList(keyBytes);
    }
    if (keyBytes.length > length) {
      return Uint8List.fromList(keyBytes.sublist(0, length));
    }
    final result = Uint8List(length);
    for (var i = 0; i < keyBytes.length; i++) {
      result[i] = keyBytes[i];
    }
    return result;
  }

  /// 发送验证码
  /// [mode] 0: 注册, 1: 重置密码
  Future<String> sendCode(String email, int mode) async {
    final uri = Uri.parse('${_client.baseUrl}/auth/validateEmail');
    final body = jsonEncode(<String, dynamic>{
      'email': email,
      'mode': mode,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200) {
          return ''; // 成功
        }
        return json['msg'] ?? '发送验证码失败';
      }
      return '发送验证码失败: ${response.statusCode}';
    } catch (e) {
      return '发送验证码失败: $e';
    }
  }

  /// 注册
  Future<String> register(Map<String, dynamic> data) async {
    final uri = Uri.parse('${_client.baseUrl}/auth/register');

    // 加密密码
    if (data['password'] != null) {
      data['password'] = _encryptPassword(data['password'], '16bit secret key');
    }
    if (data['password2'] != null) {
      data['password2'] = _encryptPassword(data['password2'], '16bit secret key');
    }

    final body = jsonEncode(data);

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200) {
          return ''; // 成功
        }
        return json['msg'] ?? '注册失败';
      }
      return '注册失败: ${response.statusCode}';
    } catch (e) {
      return '注册失败: $e';
    }
  }

  /// 重置密码
  Future<String> resetPassword(String email, String password, String password2, String valiCode) async {
    final uri = Uri.parse('${_client.baseUrl}/auth/modifyPassword');

    final encryptedPassword = _encryptPassword(password, '16bit secret key');
    final encryptedPassword2 = _encryptPassword(password2, '16bit secret key');

    final body = jsonEncode(<String, dynamic>{
      'email': email,
      'password': encryptedPassword,
      'password2': encryptedPassword2,
      'valiCode': valiCode,
    });

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] == 200) {
          return ''; // 成功
        }
        return json['msg'] ?? '重置密码失败';
      }
      return '重置密码失败: ${response.statusCode}';
    } catch (e) {
      return '重置密码失败: $e';
    }
  }
}
