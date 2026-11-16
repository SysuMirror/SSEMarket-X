import 'package:flutter_test/flutter_test.dart';
import 'package:sse_market_x/core/services/new_posts_service.dart';

void main() {
  group('NewPostsService.diffNewPostIds', () {
    test('首次拉取（previous 为空）只建立基线，不产生新帖', () {
      expect(
          NewPostsService.diffNewPostIds(const [], const [1, 2, 3]), isEmpty);
    });

    test('返回新增 ID 并保持接口顺序', () {
      expect(
        NewPostsService.diffNewPostIds(const [1, 2, 3], const [4, 1, 5, 2]),
        const [4, 5],
      );
    });

    test('没有新增时返回空列表', () {
      expect(
        NewPostsService.diffNewPostIds(const [1, 2, 3], const [3, 2, 1]),
        isEmpty,
      );
    });

    test('重复 ID 只算一次（按集合比较）', () {
      expect(
        NewPostsService.diffNewPostIds(const [1], const [2, 2, 1]),
        const [2],
      );
    });
  });

  group('NewPostsState', () {
    test('count / hasUnread 与 ID 数量一致', () {
      const state = NewPostsState(newPostIds: [11, 12], isVisible: true);
      expect(state.count, 2);
      expect(state.hasUnread, isTrue);
      expect(const NewPostsState().hasUnread, isFalse);
    });
  });
}
