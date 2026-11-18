import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/config/app_constants.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/user.dart';

class GoogleLoginException implements Exception {
  final String message;
  const GoogleLoginException(this.message);
}

class GoogleAuthSession {
  final User user;
  final String accessToken;
  final String message;

  const GoogleAuthSession({
    required this.user,
    required this.accessToken,
    required this.message,
  });
}

class GoogleAuthService {
  final Dio _dio;
  final Future<String?> Function() _getDeviceToken;

  GoogleAuthService({Dio? dio, Future<String?> Function()? getDeviceToken})
    : _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
      _getDeviceToken =
          getDeviceToken ?? (() => FirebaseMessaging.instance.getToken());

  Future<GoogleAuthSession> exchangeAuthorizationCode({
    required String code,
  }) async {
    String? deviceToken;
    try {
      deviceToken = await _getDeviceToken().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Push registration is optional and must not prevent authentication.
    }

    // Keep one-time OAuth codes and returned session tokens out of the shared
    // API client's request/response logger and global unauthorized redirect.
    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        AppConstants.googleLoginUrl,
        data: {
          'code': code,
          'data': <String, dynamic>{},
          if (deviceToken != null && deviceToken.isNotEmpty)
            'device_key': deviceToken,
          'device_type': Platform.isIOS ? 'ios' : 'android',
        },
        options: Options(
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            HttpHeaders.contentTypeHeader: 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
          followRedirects: false,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const GoogleLoginException(
        'Could not connect. Please check your internet and try again.',
      );
    }

    final body = response.data;
    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = body is Map ? body['message'] : null;
      throw GoogleLoginException(
        (response.statusCode ?? 500) < 500 &&
                message is String &&
                message.isNotEmpty
            ? message
            : 'Google sign-in could not be completed. Please try again.',
      );
    }
    final data = body is Map ? body['data'] : null;
    final userData = data is Map ? data['user'] : null;
    final access = data is Map ? data['access'] : null;
    final token = access is Map ? access['token'] : null;
    if (userData is! Map || token is! String || token.trim().isEmpty) {
      throw const GoogleLoginException(
        'Google sign-in could not be completed. Please try again.',
      );
    }
    final user = User.fromMap(Map<String, dynamic>.from(userData));
    if (user.id == null) {
      throw const GoogleLoginException(
        'Google sign-in could not be completed. Please try again.',
      );
    }
    return GoogleAuthSession(
      user: user,
      accessToken: token,
      message: body['message'] is String
          ? body['message'] as String
          : 'Logged in successfully.',
    );
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);
