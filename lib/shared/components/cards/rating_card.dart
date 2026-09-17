import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sse_market_x/core/models/rating_model.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/theme/app_colors.dart';

/// 评分帖卡片（对齐官网 RatingCard：标题 / 人评·评·阅 meta / 右侧综合评分 /
/// 愛心讚（卡内乐观更新，失败回滚 + SnackBar）/ 分類連結）
class RatingCard extends StatefulWidget {
  final RatingPost ratingPost;

  /// 隐藏分类链接（如浏览历史页用户已在对应分类下）
  final bool hideCategory;
  final VoidCallback? onTap;
  final ValueChanged<String>? onCategoryTap;
  final Future<bool> Function()? onLikeTap;

  const RatingCard({
    super.key,
    required this.ratingPost,
    this.hideCategory = false,
    this.onTap,
    this.onCategoryTap,
    this.onLikeTap,
  });

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.ratingPost.isLiked;
    _likeCount = widget.ratingPost.like;
  }

  @override
  void didUpdateWidget(covariant RatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ratingPost.ratingPostId != widget.ratingPost.ratingPostId) {
      _isLiked = widget.ratingPost.isLiked;
      _likeCount = widget.ratingPost.like;
    }
  }

  Future<void> _handleLikeTap() async {
    if (widget.onLikeTap == null) return;

    final wasLiked = _isLiked;
    final oldCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : (_likeCount - 1).clamp(0, 999999);
    });

    try {
      final success = await widget.onLikeTap!();
      if (!success && mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount = oldCount;
        });
        SnackBarHelper.show(context, '操作失败');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount = oldCount;
        });
        SnackBarHelper.show(context, '操作失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.ratingPost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title.isEmpty ? '未命名评分' : post.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${post.totalRatings} 人评 · ${post.comment} 评 · ${post.browse} 阅',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildScoreBadge(context, post),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (post.categoryName.isNotEmpty && !widget.hideCategory)
                      Flexible(child: _buildCategoryLink(context, post)),
                    const Spacer(),
                    _buildLikeButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 右侧综合评分徽章
  Widget _buildScoreBadge(BuildContext context, RatingPost post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            post.averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  /// 分类链接（点击切换到该分类）
  Widget _buildCategoryLink(BuildContext context, RatingPost post) {
    return GestureDetector(
      onTap: widget.onCategoryTap == null
          ? null
          : () => widget.onCategoryTap!(post.categoryName),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 14,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              post.categoryName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 愛心讚（乐观更新在卡内，同 PostCard 慣例；失败回滚 + SnackBar）
  Widget _buildLikeButton(BuildContext context) {
    return GestureDetector(
      onTap: _handleLikeTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            _isLiked
                ? 'assets/icons/ic_like_filled.svg'
                : 'assets/icons/ic_like.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              _isLiked ? Colors.red : context.textSecondaryColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$_likeCount',
            style: TextStyle(
              fontSize: 13,
              color: _isLiked ? Colors.red : context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
