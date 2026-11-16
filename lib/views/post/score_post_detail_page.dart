import 'package:flutter/material.dart';
import 'package:sse_market_x/core/api/api_service.dart';
import 'package:sse_market_x/views/post/post_detail_page.dart';
import 'package:sse_market_x/core/services/storage_service.dart';
import 'package:sse_market_x/shared/components/utils/snackbar_helper.dart';
import 'package:sse_market_x/shared/components/stats/rating_distribution.dart';

import 'package:sse_market_x/core/models/post_model.dart';

/// 打分帖子详情页 - 复用PostDetailPage的结构，添加评分功能
class ScorePostDetailPage extends StatefulWidget {
  final int postId;
  final ApiService apiService;
  final PostModel? initialPost;

  const ScorePostDetailPage({
    super.key,
    required this.postId,
    required this.apiService,
    this.initialPost,
  });

  @override
  State<ScorePostDetailPage> createState() => _ScorePostDetailPageState();
}

class _ScorePostDetailPageState extends State<ScorePostDetailPage> {
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
    // 新版打分接口：详情里直接带 stars / averageRating / userStar。
    final detail = await widget.apiService.getRatingPostDetail(widget.postId);
    if (!mounted || detail.id == 0) return;

    setState(() {
      _stars = detail.stars.length == 5 ? detail.stars : [0, 0, 0, 0, 0];
      _userRating = detail.userRating;
      _averageRating = detail.rating;
    });
  }

  Future<void> _handleRatingClick(int rating) async {
    final oldRating = _userRating;
    setState(() {
      _userRating = rating;
    });

    try {
      if (StorageService().user?.phone.isEmpty ?? true) {
        SnackBarHelper.show(context, '请先登录');
        setState(() {
          _userRating = oldRating;
        });
        return;
      }

      final success = await widget.apiService.submitRatingStar(
        widget.postId,
        rating,
      );

      if (success) {
        // 重新获取详情，刷新星级分布与平均分
        await _loadRatingData();
        if (mounted) {
          SnackBarHelper.show(context, '评分成功');
        }
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
      apiService: widget.apiService,
      postType: 'rating',
      loadPost: (postId, userPhone) =>
          widget.apiService.getRatingPostDetail(postId),
      loadComments: (postId, userPhone) =>
          widget.apiService.getRatingComments(postId),
      likePost: (postId, userPhone) => widget.apiService.likeRatingPost(postId),
      likeComment: (commentId, userPhone) =>
          widget.apiService.likeRatingComment(commentId),
      topContent: RatingDistribution(
        stars: _stars,
        averageRating: _averageRating,
        userRating: _userRating,
        isMobile: MediaQuery.of(context).size.width < 600,
        showUserRating: true,
        onRatingClick: _handleRatingClick,
      ),
      onSendComment: (content) async {
        if (StorageService().user?.phone.isEmpty ?? true) {
          SnackBarHelper.show(context, '请先登录');
          return false;
        }
        if (_userRating <= 0) {
          SnackBarHelper.show(context, '请先选择星级再评论');
          return false;
        }
        return await widget.apiService.createRatingComment(
          widget.postId,
          content,
          _userRating,
        );
      },
    );
  }
}
