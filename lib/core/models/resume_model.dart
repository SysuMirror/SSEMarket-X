// 简历数据模型
//
// 对应 /auth/resume/list（裸陣列条目）与 /auth/resume/detail（data 整包）。
// 字段容错解析（参考 rating_model.dart 写法）；isOwner/canPreview 仅
// detail 返回，list 条目为默认值；canPreview 本批不渲染，仅接收备用。

int _readInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

String _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String) return v;
  }
  return '';
}

bool _readBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
  }
  return false;
}

/// 副檔名四類（官网 ResumeCard 语义）
enum ResumeFileCategory { pdf, word, image, other }

class ResumeModel {
  final int resumeId;
  final String title;
  final String description;
  final String uploader;
  final bool isAnonymous;
  final String fileExt;
  final int fileSize;
  final int viewNum;
  final int downloadNum;
  final String createdAt;

  /// 仅 detail 返回
  final bool isOwner;

  /// 仅 detail 返回；官网语义未确认，本批不渲染
  final bool canPreview;

  const ResumeModel({
    required this.resumeId,
    required this.title,
    required this.description,
    required this.uploader,
    required this.isAnonymous,
    required this.fileExt,
    required this.fileSize,
    required this.viewNum,
    required this.downloadNum,
    required this.createdAt,
    this.isOwner = false,
    this.canPreview = false,
  });

  /// 统一小写、去点号的副檔名
  String get normalizedFileExt =>
      fileExt.trim().toLowerCase().replaceAll('.', '');

  ResumeFileCategory get category {
    switch (normalizedFileExt) {
      case 'pdf':
        return ResumeFileCategory.pdf;
      case 'doc':
      case 'docx':
        return ResumeFileCategory.word;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return ResumeFileCategory.image;
      default:
        return ResumeFileCategory.other;
    }
  }

  /// 官网公式：fileSize/1024 → <1024KB 显示 x.xKB，否则 x.xMB
  String get formattedFileSize {
    final kb = fileSize / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
    return '${(kb / 1024).toStringAsFixed(1)}MB';
  }

  /// 编辑保存后本地更新标题/简介（update 端点仅改这两项）
  ResumeModel copyWith({String? title, String? description}) {
    return ResumeModel(
      resumeId: resumeId,
      title: title ?? this.title,
      description: description ?? this.description,
      uploader: uploader,
      isAnonymous: isAnonymous,
      fileExt: fileExt,
      fileSize: fileSize,
      viewNum: viewNum,
      downloadNum: downloadNum,
      createdAt: createdAt,
      isOwner: isOwner,
      canPreview: canPreview,
    );
  }

  factory ResumeModel.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const ResumeModel(
        resumeId: 0,
        title: '',
        description: '',
        uploader: '',
        isAnonymous: false,
        fileExt: '',
        fileSize: 0,
        viewNum: 0,
        downloadNum: 0,
        createdAt: '',
      );
    }
    final map = raw.cast<String, dynamic>();
    return ResumeModel(
      resumeId: _readInt(map, ['resumeID', 'ResumeID', 'resumeId', 'id']),
      title: _readString(map, ['title', 'Title']),
      description: _readString(map, ['description', 'Description']),
      uploader: _readString(map, ['uploader', 'Uploader']),
      isAnonymous: _readBool(map, ['isAnonymous', 'IsAnonymous']),
      fileExt: _readString(map, ['fileExt', 'FileExt', 'fileext']),
      fileSize: _readInt(map, ['fileSize', 'FileSize']),
      viewNum: _readInt(map, ['viewNum', 'ViewNum']),
      downloadNum: _readInt(map, ['downloadNum', 'DownloadNum']),
      createdAt: _readString(map, ['createdAt', 'CreatedAt', 'created_at']),
      isOwner: _readBool(map, ['isOwner', 'IsOwner']),
      canPreview: _readBool(map, ['canPreview', 'CanPreview']),
    );
  }
}
