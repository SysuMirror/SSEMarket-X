import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sse_market_x/core/models/mini_program_app_model.dart';
import 'package:sse_market_x/core/services/mini_program_catalog.dart';

void main() {
  group('MiniProgramCatalog.webUrl', () {
    test('站内路径补全域名与斜杠', () {
      expect(MiniProgramCatalog.webUrl('/novel'), 'https://ssemarket.cn/novel');
      expect(MiniProgramCatalog.webUrl('novel'), 'https://ssemarket.cn/novel');
    });

    test('完整 URL 原样返回', () {
      expect(
        MiniProgramCatalog.webUrl('https://scholarhub.top/'),
        'https://scholarhub.top/',
      );
    });
  });

  group('MiniProgramCatalog.mergeDynamicApps', () {
    test('动态应用追加在内置入口后，并按名称去重', () {
      final apps = <MiniProgramAppItem>[
        const MiniProgramAppItem(
          appID: 1,
          name: '小说',
          icon: 'tabler:book-2',
          targetType: 'route',
          target: '/novel',
        ),
        const MiniProgramAppItem(
          appID: 2,
          name: '实验室预约',
          icon: 'tabler:flask',
          targetType: 'route',
          target: '/lab',
        ),
      ];

      final merged = MiniProgramCatalog.mergeDynamicApps(apps);
      expect(merged.length, MiniProgramCatalog.builtinEntries.length + 1);
      expect(merged.last.label, '实验室预约');
      expect(merged.last.url, 'https://ssemarket.cn/lab');
      // 内置的「小说」只保留一条。
      expect(merged.where((e) => e.label == '小说').length, 1);
    });

    test('link 类型动态应用保留完整外链', () {
      final apps = <MiniProgramAppItem>[
        const MiniProgramAppItem(
          appID: 9,
          name: '学人汇',
          icon: 'tabler:external-link',
          targetType: 'link',
          target: 'https://scholarhub.top/',
        ),
        const MiniProgramAppItem(
          appID: 10,
          name: '外部站点',
          icon: 'tabler:link',
          targetType: 'link',
          target: 'https://example.com/',
        ),
      ];

      final merged = MiniProgramCatalog.mergeDynamicApps(apps);
      // 学人汇是内置名称，应被去重；外部站点保留。
      expect(merged.where((e) => e.label == '学人汇').length, 1);
      final external = merged.firstWhere((e) => e.label == '外部站点');
      expect(external.action, MiniProgramAction.externalLink);
      expect(external.url, 'https://example.com/');
    });
  });

  group('MiniProgramCatalog.paletteFor', () {
    test('已知 key 返回粉彩配色，未知 key 有回退', () {
      final novel = MiniProgramCatalog.paletteFor('novel', dark: false);
      expect(novel.bg, const Color(0xFFEDE9FE));
      final unknown = MiniProgramCatalog.paletteFor('unknown-key', dark: false);
      expect(unknown.bg, const Color(0xFFF1F3F6));
    });
  });
}
