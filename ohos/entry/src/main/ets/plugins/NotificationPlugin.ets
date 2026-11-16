import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import notificationManager from '@ohos.notificationManager';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

/**
 * 新帖本地通知的 HarmonyOS 原生实现。
 *
 * Dart 侧通过 MethodChannel `ssemarket/notifications` 调用：
 * - requestPermission：弹出系统通知授权框
 * - show：发布一条普通文本通知
 */
export default class NotificationPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  getUniqueClassName(): string {
    return 'NotificationPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'ssemarket/notifications');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'requestPermission') {
      this.requestPermission(result);
    } else if (call.method === 'areEnabled') {
      notificationManager.isNotificationEnabled()
        .then((enabled: boolean) => result.success(enabled))
        .catch((_err: BusinessError) => result.success(false));
    } else if (call.method === 'show') {
      this.show(call, result);
    } else {
      result.notImplemented();
    }
  }

  private requestPermission(result: MethodResult): void {
    // 先创建通知通道，再请求授权；重复创建由系统幂等处理。
    notificationManager.addSlot(notificationManager.SlotType.CONTENT_INFORMATION)
      .catch((_err: BusinessError) => {});
    notificationManager.requestEnableNotification(this.context)
      .then(() => result.success(true))
      .catch((_err: BusinessError) => result.success(false));
  }

  private show(call: MethodCall, result: MethodResult): void {
    const id = (call.argument('id') as number) ?? 41001;
    const title = (call.argument('title') as string) ?? 'SSE 集市';
    const text = (call.argument('text') as string) ?? '';
    notificationManager.publish({
      id: id,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
          additionalText: ''
        }
      }
    })
      .then(() => result.success(true))
      .catch((_err: BusinessError) => result.success(false));
  }
}