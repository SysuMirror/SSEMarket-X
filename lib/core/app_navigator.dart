import 'package:flutter/material.dart';

/// 全局 Navigator key：供非 Widget 层（如小程序运行时）弹授权确认框。
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
