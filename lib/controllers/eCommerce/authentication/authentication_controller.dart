import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itrsp_shop/controllers/common/master_controller.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/sign_up.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/user.dart';
import 'package:itrsp_shop/models/eCommerce/common/common_response.dart';
import 'package:itrsp_shop/services/common/hive_service_provider.dart';
import 'package:itrsp_shop/services/common/google_sign_in_service.dart';
import 'package:itrsp_shop/services/eCommerce/auth_service/auth_service.dart';
import 'package:itrsp_shop/services/eCommerce/auth_service/google_auth_service.dart';
import 'package:itrsp_shop/utils/api_client.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) => AuthController(ref));

class AuthController extends StateNotifier<bool> {
  final Ref ref;
  AuthController(this.ref) : super(false);

  Future<CommonResponse> loginWithGoogle() async {
    if (state) return CommonResponse(isSuccess: false, message: '');
    final settings = ref
        .read(masterControllerProvider.notifier)
        .materModel
        .data
        .socialAuths
        .google;
    final clientId = settings.clientId?.trim();
    if (!settings.isActive || clientId == null || clientId.isEmpty) {
      return CommonResponse(
        isSuccess: false,
        message:
            'Google sign-in is not available right now. Please try again later.',
      );
    }

    state = true;
    try {
      final code = await ref
          .read(googleSignInServiceProvider)
          .requestAuthorizationCode(serverClientId: clientId);
      if (code == null) return CommonResponse(isSuccess: false, message: '');
      final session = await ref
          .read(googleAuthServiceProvider)
          .exchangeAuthorizationCode(code: code);
      final storage = ref.read(hiveServiceProvider);
      await storage.saveUserInfo(userInfo: session.user);
      await storage.saveUserAuthToken(authToken: session.accessToken);
      ref.read(apiClientProvider).updateToken(token: session.accessToken);
      return CommonResponse(isSuccess: true, message: session.message);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return CommonResponse(isSuccess: false, message: '');
      }
      debugPrint('Google sign-in failed: ${error.code.name}');
      return CommonResponse(
        isSuccess: false,
        message: 'Google sign-in could not be completed. Please try again.',
      );
    } on GoogleLoginException catch (error) {
      return CommonResponse(isSuccess: false, message: error.message);
    } catch (_) {
      return CommonResponse(
        isSuccess: false,
        message: 'Google sign-in could not be completed. Please try again.',
      );
    } finally {
      state = false;
    }
  }

  Future<CommonResponse> singUp({required SingUp singUpInfo}) async {
    state = true;
    final response =
        await ref.read(authServiceProvider).signUp(singUpInfo: singUpInfo);
    final String message = response.data['message'];
    if (response.statusCode == 200) {
      final userInfo = User.fromMap(response.data['data']['user']);
      final accessToken = response.data['data']['access']['token'];
      ref.read(hiveServiceProvider).saveUserInfo(userInfo: userInfo);
      ref.read(hiveServiceProvider).saveUserAuthToken(authToken: accessToken);
      ref.read(apiClientProvider).updateToken(token: accessToken);
      state = false;
      return CommonResponse(isSuccess: true, message: message);
    }
    state = false;
    return CommonResponse(isSuccess: false, message: message);
  }

  Future<CommonResponse> sendOTP(
      {required String phone, required bool isForgot}) async {
    try {
      state = true;
      final response = await ref
          .read(authServiceProvider)
          .sendOTP(phone: phone, isForgot: isForgot);
      final String message = response.data['message'];
       var otp = response.data['data']['otp'];
      state = false;
      return CommonResponse(isSuccess: true, message: message, data: otp);
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> verifyOTP(
      {required String phone, required String otp}) async {
    try {
      state = true;
      final response =
          await ref.read(authServiceProvider).verifyOTP(phone: phone, otp: otp);
      final String message = response.data['message'];
      final String token = response.data['data']['token'];
      state = false;
      return CommonResponse(isSuccess: true, message: message, data: token);
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> resetPassword({
    required String password,
    required String confrimPassword,
    required String forgotPasswordToken,
  }) async {
    try {
      state = true;
      final response = await ref.read(authServiceProvider).resetPassword(
            password: password,
            confirmPassword: confrimPassword,
            forgotPasswordToken: forgotPasswordToken,
          );
      final String message = response.data['message'];

      if (response.statusCode == 200) {
        state = false;
        return CommonResponse(isSuccess: true, message: message);
      }
      state = false;
      return CommonResponse(
        isSuccess: false,
        message: message,
      );
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> login(
      {required String phone, required String password}) async {
    try {
      state = true;
      final response = await ref
          .read(authServiceProvider)
          .login(phone: phone, password: password);
      final String message = response.data['message'];
      final userInfo = User.fromMap(response.data['data']['user']);
      final accessToken = response.data['data']['access']['token'];
      ref.read(hiveServiceProvider).saveUserInfo(userInfo: userInfo);
      ref.read(hiveServiceProvider).saveUserAuthToken(authToken: accessToken);
      ref.read(apiClientProvider).updateToken(token: accessToken);
      state = false;
      return CommonResponse(isSuccess: true, message: message);
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      state = true;
      final response = await ref.read(authServiceProvider).changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
            confirmNewPassword: confirmNewPassword,
          );
      final String message = response.data['message'];
      if (response.statusCode == 200) {
        state = false;
        return CommonResponse(isSuccess: true, message: message);
      } else {
        state = false;
        return CommonResponse(isSuccess: false, message: message);
      }
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> updateProfile(
      {required User userInfo, required File? file}) async {
    try {
      state = true;
      final response = await ref.read(authServiceProvider).updateProfile(
            userInfo: userInfo,
            file: file,
          );
      final String message = response.data['message'];
      final User userData = User.fromMap(response.data['data']['user']);
      ref.read(hiveServiceProvider).saveUserInfo(userInfo: userData);
      state = false;
      return CommonResponse(isSuccess: true, message: message);
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> logout() async {
    try {
      state = true;
      final response = await ref.read(authServiceProvider).logout();
      ref.read(hiveServiceProvider).clearDefaultAddress();
      final String message = response.data['message'];
      state = false;
      return CommonResponse(isSuccess: true, message: message);
    } catch (error) {
      state = false;
      debugPrint(error.toString());
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }
}
