import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:sse_market_x/core/api/resume_service.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 上传简历页（对应官网 /resume/upload）
///
/// 标题必填 ≤50 字、简介 ≤500 字、匿名开关、file_picker 选档；
/// 前端校验副檔名白名单与 10MB 上限；「每人最多 5 份」为后端规则，
/// 失败时原样展示后端 msg。
class ResumeUploadPage extends StatefulWidget {
  const ResumeUploadPage({super.key});

  @override
  State<ResumeUploadPage> createState() => _ResumeUploadPageState();
}

class _ResumeUploadPageState extends State<ResumeUploadPage> {
  final ResumeService _resumeService = ResumeService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  static const int _maxFileSize = 10 * 1024 * 1024;
  static const List<String> _allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final file = result.files.first;
    // 选择器已过滤，这里再验一次兜底（部分平台可绕过选择器过滤）
    final ext = (file.extension ?? '').toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      SnackBarHelper.show(context, '不支持的文件格式');
      return;
    }
    if (file.size > _maxFileSize) {
      SnackBarHelper.show(context, '文件大小不能超过 10MB');
      return;
    }
    if (file.bytes == null) {
      SnackBarHelper.show(context, '无法读取文件，请重新选择');
      return;
    }
    setState(() {
      _pickedFile = file;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      SnackBarHelper.show(context, '请输入标题');
      return;
    }
    final file = _pickedFile;
    if (file == null || file.bytes == null) {
      SnackBarHelper.show(context, '请选择简历文件');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    final result = await _resumeService.uploadResume(
      fileBytes: file.bytes!,
      fileName: file.name,
      title: title,
      description: _descController.text.trim(),
      isAnonymous: _isAnonymous,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      SnackBarHelper.show(context, '上传成功');
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
      });
      SnackBarHelper.show(
        context,
        result.msg.isNotEmpty ? result.msg : '上传失败，请重试',
      );
    }
  }

  String _formatSize(int bytes) {
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
    return '${(kb / 1024).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('上传简历'),
        backgroundColor: context.surfaceColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildNotice(context),
          const SizedBox(height: 16),
          _buildFieldLabel(context, '标题 *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: '例如：2025 前端实习简历',
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel(context, '简介'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descController,
            hint: '简单介绍一下这份简历',
            maxLength: 500,
            maxLines: 4,
            minLines: 3,
          ),
          const SizedBox(height: 16),
          _buildAnonymousRow(context),
          const SizedBox(height: 16),
          _buildFieldLabel(context, '简历文件 *'),
          const SizedBox(height: 8),
          _buildFilePicker(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('上传简历'),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部格式/大小/份数提示
  Widget _buildNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '支持 PDF、Word、JPG、PNG、WebP、GIF，单文件不超过 10MB，每人最多 5 份',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: context.textPrimaryColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    int maxLines = 1,
    int minLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 14, color: context.textPrimaryColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: context.textTertiaryColor),
        counterStyle: TextStyle(
          fontSize: 11,
          color: context.textTertiaryColor,
        ),
        filled: true,
        fillColor: context.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }

  Widget _buildAnonymousRow(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _isAnonymous = !_isAnonymous),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) =>
                    setState(() => _isAnonymous = value ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  '匿名展示（他人看不到你的用户名）',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    final file = _pickedFile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(file == null ? '选择文件' : '重新选择'),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatSize(file.size),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
