import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sse_market_x/core/api/resume_service.dart';
import 'package:sse_market_x/core/models/resume_model.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 简历详情页（对应官网 /resume/detail）
///
/// 信息区 + 底部操作栏：下载（url_launcher 外部打开，不缓存链接）、
/// 删除/编辑仅 isOwner 可见；编辑为标题/简介行内编辑。
class ResumeDetailPage extends StatefulWidget {
  const ResumeDetailPage({super.key, required this.resumeId});

  final int resumeId;

  @override
  State<ResumeDetailPage> createState() => _ResumeDetailPageState();
}

class _ResumeDetailPageState extends State<ResumeDetailPage> {
  final ResumeService _resumeService = ResumeService();
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editDescController = TextEditingController();

  ResumeModel? _resume;
  bool _isLoading = true;
  bool _hasError = false;
  bool _notFound = false;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _editTitleController.dispose();
    _editDescController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _notFound = false;
    });
    final result = await _resumeService.getResumeDetail(widget.resumeId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.resume != null) {
        _resume = result.resume;
      } else if (result.notFound) {
        _notFound = true;
      } else {
        _hasError = true;
      }
    });
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _download() async {
    final resume = _resume;
    if (resume == null) return;
    if (!await _confirm('确定要下载这份简历吗？')) return;

    final info = await _resumeService.downloadResume(resume.resumeId);
    if (!mounted) return;
    if (info == null) {
      SnackBarHelper.show(context, '获取下载链接失败');
      return;
    }
    // downloadURL 有效期未确认，取到后立即使用，不缓存
    await _launchExternal(info.downloadUrl);
  }

  // 与 workbench_page._launchExternal 同款：不以 canLaunchUrl 预检作唯一
  // 闸门，直接外部打开，失败退回平台默认，仍失败才提示
  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (mounted) {
          SnackBarHelper.show(context, '无法打开链接');
        }
      }
    }
  }

  Future<void> _delete() async {
    final resume = _resume;
    if (resume == null || _isDeleting) return;
    if (!await _confirm('确定删除这份简历吗？')) return;

    setState(() {
      _isDeleting = true;
    });
    final ok = await _resumeService.deleteResume(resume.resumeId);
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.show(context, '已删除');
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDeleting = false;
      });
      SnackBarHelper.show(context, '删除失败，请重试');
    }
  }

  void _startEdit() {
    final resume = _resume;
    if (resume == null) return;
    _editTitleController.text = resume.title;
    _editDescController.text = resume.description;
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveEdit() async {
    final resume = _resume;
    if (resume == null || _isSaving) return;

    final title = _editTitleController.text.trim();
    if (title.isEmpty) {
      SnackBarHelper.show(context, '请输入标题');
      return;
    }

    setState(() {
      _isSaving = true;
    });
    final updated = await _resumeService.updateResume(
      resumeId: resume.resumeId,
      title: title,
      description: _editDescController.text.trim(),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _resume = updated;
        _isEditing = false;
        _isSaving = false;
      });
      SnackBarHelper.show(context, '已保存');
    } else {
      setState(() {
        _isSaving = false;
      });
      SnackBarHelper.show(context, '保存失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (_notFound) {
      body = _buildNotFoundView(context);
    } else if (_hasError || _resume == null) {
      body = _buildErrorView(context);
    } else {
      body = _buildContentView(context, _resume!);
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('简历详情'),
        backgroundColor: context.surfaceColor,
      ),
      body: body,
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.highlight_off_outlined,
            size: 48,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '简历不存在或已删除',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回列表'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: context.textTertiaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '获取简历详情失败',
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(BuildContext context, ResumeModel resume) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _isEditing
                  ? _buildEditCard(context, resume)
                  : _buildInfoCard(context, resume),
            ],
          ),
        ),
        if (!_isEditing) _buildBottomBar(context, resume),
      ],
    );
  }

  /// 浏览态信息卡：图标/标题/标签 + 简介 + 统计
  Widget _buildInfoCard(BuildContext context, ResumeModel resume) {
    final uploader = resume.uploader.isNotEmpty ? resume.uploader : '匿名用户';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExtIcon(context, resume),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.title.isNotEmpty ? resume.title : '未命名简历',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (resume.isAnonymous) _buildTag(context, '匿名'),
                        _buildTag(context, _typeLabel(resume)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.dividerColor),
          const SizedBox(height: 16),
          Text(
            '简介',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resume.description.isNotEmpty ? resume.description : '暂无简介',
            style: TextStyle(
              fontSize: 14,
              color: resume.description.isNotEmpty
                  ? context.textPrimaryColor
                  : context.textTertiaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.dividerColor),
          const SizedBox(height: 16),
          _buildStatRow(context, '上传者', uploader),
          _buildStatRow(context, '大小', resume.formattedFileSize),
          _buildStatRow(context, '浏览', '${resume.viewNum} 次'),
          _buildStatRow(context, '下载', '${resume.downloadNum} 次'),
          _buildStatRow(context, '时间', resume.createdAt),
        ],
      ),
    );
  }

  /// 编辑态：标题/简介行内编辑 + 保存/取消
  Widget _buildEditCard(BuildContext context, ResumeModel resume) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '标题 *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _editTitleController,
            maxLength: 50,
            style: TextStyle(fontSize: 14, color: context.textPrimaryColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.backgroundColor,
              counterStyle: TextStyle(
                fontSize: 11,
                color: context.textTertiaryColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '简介',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _editDescController,
            maxLength: 500,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(fontSize: 14, color: context.textPrimaryColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.backgroundColor,
              counterStyle: TextStyle(
                fontSize: 11,
                color: context.textTertiaryColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEdit,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEdit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResumeModel resume) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(
            top: BorderSide(color: context.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('下载'),
                ),
              ),
            ),
            if (resume.isOwner) ...[
              const SizedBox(width: 12),
              IconButton.outlined(
                tooltip: '编辑',
                onPressed: _startEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                tooltip: '删除',
                onPressed: _isDeleting ? null : _delete,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.textTertiaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 副檔名四类图标（与列表页同款映射）
  Widget _buildExtIcon(BuildContext context, ResumeModel resume) {
    final IconData icon;
    final Color color;
    switch (resume.category) {
      case ResumeFileCategory.pdf:
        icon = Icons.picture_as_pdf;
        color = AppColors.error;
      case ResumeFileCategory.word:
        icon = Icons.description;
        color = AppColors.primary;
      case ResumeFileCategory.image:
        icon = Icons.image;
        color = AppColors.secondary;
      case ResumeFileCategory.other:
        icon = Icons.insert_drive_file;
        color = context.textTertiaryColor;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.primary),
      ),
    );
  }

  String _typeLabel(ResumeModel resume) {
    switch (resume.category) {
      case ResumeFileCategory.pdf:
        return 'PDF';
      case ResumeFileCategory.word:
        return 'Word';
      case ResumeFileCategory.image:
        return '图片';
      case ResumeFileCategory.other:
        return resume.normalizedFileExt.isNotEmpty
            ? resume.normalizedFileExt.toUpperCase()
            : '文件';
    }
  }
}
