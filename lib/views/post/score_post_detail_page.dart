import 'package:flutter/material.dart';
import 'package:sse_market_x/core/api/comment_service.dart';
import 'package:sse_market_x/core/api/post_service.dart';
import 'package:sse_market_x/views/post/post_detail_page.dart';
import 'package:sse_market_x/core/services/storage_service.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/components/stats/rating_distribution.dart';

import 'package:sse_market_x/core/models/post_model.dart';

/// 打分帖子详情页 - 复用PostDetailPage的结构，添加评分功能
class ScorePostDetailPage extends StatefulWidget {
  final int postId;
  final PostModel? initialPost;

  const ScorePostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<ScorePostDetailPage> createState() => _ScorePostDetailPageState();
}

class _ScorePostDetailPageState extends State<ScorePostDetailPage> {
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  // 评分相关状态
  List<int> _stars = [0, 0, 0, 0, 0];
  double _averageRating = 0.0;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      if (widget.initialPost!.stars.length == 5) {
        _stars = widget.initialPost!.stars;
      } else {
        _stars = [0, 0, 0, 0, 0];
      }
      _averageRating = widget.initialPost!.rating;
      _userRating = widget.initialPost!.userRating;
    }
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    final detail = await _postService.getRatingPostDetail(widget.postId);

    if (!mounted || detail == null) return;

    setState(() {
      _stars = detail.stars;
      _averageRating = detail.averageRating;
      _userRating = detail.userStar;
    });
  }

  Future<void> _handleRatingClick(int rating) async {
    final oldRating = _userRating;
    setState(() {
      _userRating = rating;
    });

    try {
      // 评分接口通过 Bearer token 识别用户，无需手机号
      if (StorageService().user == null) {
        SnackBarHelper.show(context, '请先登录');
        setState(() {
          _userRating = oldRating;
        });
        return;
      }

      final success = await _postService.submitRating(
        widget.postId,
        rating,
      );

      if (success) {
        // 重新获取评分详情（分布、平均分、用户评分）
        final detail = await _postService.getRatingPostDetail(widget.postId);

        if (mounted) {
          setState(() {
            if (detail != null) {
              _stars = detail.stars;
              _averageRating = detail.averageRating;
              _userRating = detail.userStar;
            }
          });
        }
        SnackBarHelper.show(context, '评分成功');
      } else {
        if (mounted) {
          setState(() {
            _userRating = oldRating;
          });
        }
        SnackBarHelper.show(context, '评分失败');
      }
    } catch (e) {
      debugPrint('Submit rating error: $e');
      if (mounted) {
        setState(() {
          _userRating = oldRating;
        });
        SnackBarHelper.show(context, '评分失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PostDetailPage(
      postId: widget.postId,
      postType: 'rating',
      topContent: RatingDistribution(
        stars: _stars,
        averageRating: _averageRating,
        userRating: _userRating,
        isMobile: MediaQuery.of(context).size.width < 600,
        showUserRating: true,
        onRatingClick: _handleRatingClick,
      ),
      onSendComment: (content) async {
        // 评论接口通过 Bearer token 识别用户，无需手机号
        if (StorageService().user == null) {
          SnackBarHelper.show(context, '请先登录');
          return false;
        }
        return await _commentService.sendRatingComment(
          content,
          widget.postId,
          _userRating,
        );
      },
    );
  }
}
