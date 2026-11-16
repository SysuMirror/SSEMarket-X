import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import NotificationPlugin from '../plugins/NotificationPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    // 本地通知插件：Dart 侧 MethodChannel `ssemarket/notifications`
    try {
      flutterEngine.getPlugins()?.add(new NotificationPlugin(this.context))
    } catch (e) {
      console.error('NotificationPlugin register failed: ' + JSON.stringify(e))
    }
  }
}