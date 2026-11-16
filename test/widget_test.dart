// 帖子音乐占位渲染测试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sse_market_x/shared/components/markdown/latex_markdown.dart';
import 'package:sse_market_x/views/miniprogram/mini_program_pull_down.dart';

void main() {
  testWidgets('帖子里的 ::music 占位渲染为音乐卡片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LatexMarkdown(data: '::music 47::'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('音频已失效'), findsOneWidget);
  });

  testWidgets('首页下拉时列表跟随下移并露出小程序面板', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniProgramPullDownHost(
            topOffset: 0,
            panelBuilder: (context, close) => const SizedBox(
              child: Center(child: Text('MINI PANEL')),
            ),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: 20,
              itemBuilder: (context, index) => SizedBox(
                height: 80,
                child: Text('item $index'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 260));
    await tester.pumpAndSettle();

    expect(find.text('MINI PANEL'), findsOneWidget);
  });
}
