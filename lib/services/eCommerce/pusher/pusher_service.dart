import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:ready_ecommerce/config/app_constants.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  late PusherChannelsFlutter _pusher;
  bool _isInitialized = false;
  bool _isConnected = false;
  final Set<String> _subscribedChannels = <String>{};

  Future<void> init({
    required void Function(PusherEvent) onEvent,
    void Function(String?, String?)? onConnectionChange,
    void Function(String?, int?, dynamic)? onError,
  }) async {
    if (!_isInitialized) {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher.init(
        apiKey: AppConstants.pusherApiKey,
        cluster: AppConstants.pusherCluster,
        onEvent: onEvent,
        onConnectionStateChange: onConnectionChange,
        onError: onError,
      );
      _isInitialized = true;
    }

    if (!_isConnected) {
      await _pusher.connect();
      _isConnected = true;
    }
  }

  Future<void> subscribe(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;
    await _pusher.subscribe(channelName: channelName);
    _subscribedChannels.add(channelName);
    debugPrint("Subscribed to channel: $channelName");
  }
}
