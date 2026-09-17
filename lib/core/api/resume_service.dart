import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:sse_market_x/core/api/api_client.dart';
import 'package:sse_market_x/core/models/resume_model.dart';

/// 上传结果：成功时 resumeId 非空；失败时 msg 为后端信息（可能为空）
class ResumeUploadResult {
  final int? resumeId;
  final String msg;

  const ResumeUploadResult({this.resumeId, this.msg = ''});

  bool get isSuccess => resumeId != null;
}

/// 详情加载结果：resume 非空 = 成功；notFound = 服务器明确表示不存在；
/// 两者都不是 = 网络错误（页面显示错误态可重试）
class ResumeDetailResult {
  final ResumeModel? resume;
  final bool notFound;
  final String msg;

  const ResumeDetailResult({this.resume, this.notFound = false, this.msg = ''});
}

/// 下载信息：downloadURL 有效期未确认，取到后立即使用，不缓存
class ResumeDownloadInfo {
  final String downloadUrl;
  final String fileName;

  const ResumeDownloadInfo({required this.downloadUrl, required this.fileName});
}

/// 简历 API 服务（对应官网 /resume 系列 6 个端点，全部 POST + Bearer）
class ResumeService {
  final ApiClient _client;

  ResumeService({ApiClient client = const ApiClient()}) : _client = client;

  String get token => _client.token;

  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> get _jsonHeaders => <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  MediaType? _mediaTypeFor(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return null;
    }
  }

  /// 简历列表（对应 /auth/resume/list，回裸陣列；容错兼容 {data:[...]} 包络）
  /// [searchsort]："home"=全部简历 / "my"=我的简历（服务器从 JWT 判断）
  /// 固定 limit:200 offset:0 一次取回，无分页
  Future<List<ResumeModel>?> getResumeList({
    required String searchsort,
    String searchinfo = '',
  }) async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/list');

    try {
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{
              'searchinfo': searchinfo.trim(),
              'searchsort': searchsort,
              'limit': 200,
              'offset': 0,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      List? rawList;
      if (json is List) {
        rawList = json;
      } else if (json is Map && json['data'] is List) {
        rawList = json['data'] as List;
      }
      if (rawList == null) return null;

      return rawList.map((e) => ResumeModel.fromDynamic(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('获取简历列表失败: $e');
      return null;
    }
  }

  /// 上传简历（对应 /auth/resume/upload，FormData：file/title/description/
  /// isAnonymous 字串），MultipartRequest 模式参考 uploadPhoto
  Future<ResumeUploadResult> uploadResume({
    required List<int> fileBytes,
    required String fileName,
    required String title,
    String description = '',
    required bool isAnonymous,
  }) async {
    if (token.isEmpty) {
      return const ResumeUploadResult(msg: '请先登录');
    }

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/upload');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['description'] = description
        ..fields['isAnonymous'] = isAnonymous ? 'true' : 'false'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
            contentType: _mediaTypeFor(fileName),
          ),
        );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.isEmpty) return const ResumeUploadResult();

      final dynamic json = jsonDecode(response.body);
      if (json is Map && json['code'] == 200) {
        final data = json['data'];
        final rawId = data is Map ? data['resumeID'] : json['resumeID'];
        final int? resumeId = rawId is int
            ? rawId
            : rawId is num
                ? rawId.toInt()
                : int.tryParse('${rawId ?? ''}');
        if (resumeId != null) {
          final msg = json['msg'];
          return ResumeUploadResult(
            resumeId: resumeId,
            msg: msg is String ? msg : '',
          );
        }
        return const ResumeUploadResult();
      }
      final msg = json is Map && json['msg'] is String ? json['msg'] as String : '';
      return ResumeUploadResult(msg: msg);
    } catch (e) {
      // ignore: avoid_print
      print('上传简历失败: $e');
      return const ResumeUploadResult();
    }
  }

  /// 简历详情（对应 /auth/resume/detail，{resumeID} → data 整包）
  Future<ResumeDetailResult> getResumeDetail(int resumeId) async {
    if (token.isEmpty) return const ResumeDetailResult();

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/detail');

    try {
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{'resumeID': resumeId}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return const ResumeDetailResult();

      final dynamic json = jsonDecode(response.body);
      if (json is! Map) return const ResumeDetailResult();

      // 實測(sse_api_capture #122):detail 回裸物件;容錯相容 {code,data}
      final resume = _parseDetail(json);
      if (resume != null) {
        return ResumeDetailResult(resume: resume);
      }

      if (json['code'] == 200) {
        // 包络成功但 data 解不出 → 视为格式错误
        return const ResumeDetailResult();
      }
      final msg = json['msg'];
      return ResumeDetailResult(
        notFound: true,
        msg: msg is String ? msg : '',
      );
    } catch (e) {
      // ignore: avoid_print
      print('获取简历详情失败: $e');
      return const ResumeDetailResult();
    }
  }

  /// 取下载链接（对应 /auth/resume/download，{resumeID} →
  /// data.{downloadURL, fileName}）；下载本身由调用方以 url_launcher 处理
  Future<ResumeDownloadInfo?> downloadResume(int resumeId) async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/download');

    try {
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{'resumeID': resumeId}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! Map || json['code'] != 200) return null;
      final data = json['data'];
      if (data is! Map) return null;

      final rawUrl = data['downloadURL'] ?? data['downloadUrl'];
      if (rawUrl is! String || rawUrl.isEmpty) return null;
      final rawName = data['fileName'];
      return ResumeDownloadInfo(
        downloadUrl: rawUrl,
        fileName: rawName is String ? rawName : '',
      );
    } catch (e) {
      // ignore: avoid_print
      print('获取简历下载链接失败: $e');
      return null;
    }
  }

  /// 编辑简历（对应 /auth/resume/update，{resumeID, title, description}；
  /// 回应即新 detail）
  Future<ResumeModel?> updateResume({
    required int resumeId,
    required String title,
    required String description,
  }) async {
    if (token.isEmpty) return null;

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/update');

    try {
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{
              'resumeID': resumeId,
              'title': title,
              'description': description,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final dynamic json = jsonDecode(response.body);
      if (json is! Map) return null;
      // 官網源碼:回應即 json 本體(detail 實測為裸物件,update 同形);
      // _parseDetail 同時容錯 {code:200,data:{...}} 包絡
      return _parseDetail(json);
    } catch (e) {
      // ignore: avoid_print
      print('编辑简历失败: $e');
      return null;
    }
  }

  /// 删除简历（对应 /auth/resume/delete，{resumeID}，code==200 为成功）
  Future<bool> deleteResume(int resumeId) async {
    if (token.isEmpty) return false;

    final uri = Uri.parse('${_client.baseUrl}/auth/resume/delete');

    try {
      final response = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{'resumeID': resumeId}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return false;

      final dynamic json = jsonDecode(response.body);
      return json is Map && json['code'] == 200;
    } catch (e) {
      // ignore: avoid_print
      print('删除简历失败: $e');
      return false;
    }
  }

  /// detail/update 共用的 data 解包：优先 data 子对象，兼容裸物件回应；
  /// resumeID 非正数视为解析失败
  ResumeModel? _parseDetail(Map json) {
    final data = json['data'];
    final ResumeModel parsed;
    if (data is Map) {
      parsed = ResumeModel.fromDynamic(data);
    } else if (json.containsKey('resumeID')) {
      parsed = ResumeModel.fromDynamic(json);
    } else {
      return null;
    }
    return parsed.resumeId > 0 ? parsed : null;
  }
}
