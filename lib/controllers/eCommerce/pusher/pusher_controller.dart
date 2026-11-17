import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:itrsp_shop/controllers/eCommerce/message/message_controller.dart';
import 'package:itrsp_shop/models/eCommerce/message_model/messages.dart';
import 'package:itrsp_shop/services/common/hive_service_provider.dart';
import 'package:itrsp_shop/services/eCommerce/pusher/pusher_service.dart';

final pusherControllerProvider =
    StateNotifierProvider<PusherController, void>((ref) {
  return PusherController(ref);
});

class PusherController extends StateNotifier<void> {
  final Ref ref;
  final PusherService _pusherService = PusherService();
  Future<void>? _initialization;

  PusherController(this.ref) : super(null);

  /// Initialize Pusher and connect
  Future<void> init() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    await _pusherService.init(
      onEvent: _handleEvent,
      onConnectionChange: _handleConnectionChange,
      onError: _handleError,
    );

    // Subscribe to authenticated user's channel
    final user = await ref.read(hiveServiceProvider).getUserInfo();
    if (user?.id != null) {
      await subscribeToUser(user!.id!);
    }
  }

  /// Subscribe to user's personal channel
  Future<void> subscribeToUser(int userId) async {
    final channel = "chat_user_$userId";
    debugPrint("Subscribing to channel: $channel");
    await _pusherService.subscribe(channel);
  }

  /// Handle incoming events
  void _handleEvent(PusherEvent event) {
    debugPrint("Event: ${event.eventName}");
    debugPrint("Data: ${event.data}");

    try {
      if (event.data.isEmpty) {
        debugPrint("No data received");
        return;
      }
      final decoded = jsonDecode(event.data);
      final dynamic messageData = decoded is Map<String, dynamic>
          ? decoded["message"] ?? decoded
          : decoded;
      final Map<String, dynamic> messageMap = messageData is String
          ? jsonDecode(messageData) as Map<String, dynamic>
          : Map<String, dynamic>.from(messageData as Map);
      final message = Messages.fromMap(messageMap);
      debugPrint("Parsed message: ${message.toMap()}");

      final activeShopId = ref.read(activeChatShopIdProvider);
      if (activeShopId != null) {
        if (message.shop?.id == activeShopId) {
          ref
              .read(getMessageControllerProvider.notifier)
              .addNewMessage(message);
        } else if (message.shop?.id == null) {
          ref.read(getMessageControllerProvider.notifier).getMessage(
                shopId: activeShopId,
                isInitial: true,
              );
        }
      }
      ref.read(getShopsControllerProvider.notifier).getShops();
      ref.invalidate(getTotalUnreadMessagesControllerProvider);
    } catch (e, stk) {
      debugPrint("Error parsing message: $e | $stk");
      return;
    }
  }

  /// Connection change
  void _handleConnectionChange(String? current, String? previous) {
    debugPrint("🔌 Pusher state: $previous → $current");
  }

  /// Error
  void _handleError(String? message, int? code, dynamic error) {
    debugPrint("Pusher error: $message | code: $code");
  }
}
