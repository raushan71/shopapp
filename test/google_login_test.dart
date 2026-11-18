import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/controllers/common/master_controller.dart';
import 'package:itrsp_shop/controllers/common/other_controller.dart';
import 'package:itrsp_shop/controllers/eCommerce/address/address_controller.dart';
import 'package:itrsp_shop/controllers/eCommerce/authentication/authentication_controller.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/common/master_model.dart';
import 'package:itrsp_shop/models/common/all_country_model/country.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/user.dart';
import 'package:itrsp_shop/models/eCommerce/common/common_response.dart';
import 'package:itrsp_shop/services/common/google_sign_in_service.dart';
import 'package:itrsp_shop/services/common/hive_service_provider.dart';
import 'package:itrsp_shop/services/common/other_service_provider.dart';
import 'package:itrsp_shop/services/eCommerce/auth_service/google_auth_service.dart';
import 'package:itrsp_shop/utils/api_client.dart';
import 'package:itrsp_shop/views/common/authentication/layouts/login_layout.dart';

const webClientId = 'shop-web-client.apps.googleusercontent.com';
Map<String, dynamic> sessionPayload() => {
  'message': 'Welcome',
  'data': {
    'user': {'id': 42, 'name': 'Customer', 'email': 'customer@example.test'},
    'access': {'token': 'backend-session-token'},
  },
};

GoogleAuthSession session() => GoogleAuthSession(
  user: User.fromMap(sessionPayload()['data']['user']),
  accessToken: 'backend-session-token',
  message: 'Welcome',
);

ProviderContainer loginContainer({
  bool active = true,
  String? clientId = webClientId,
  Country? defaultCountry,
}) => ProviderContainer(
  overrides: [
    masterControllerProvider.overrideWith(
      (ref) => StubMasterController(
        ref,
        active,
        clientId,
        defaultCountry: defaultCountry,
      ),
    ),
    googleSignInServiceProvider.overrideWith((ref) => StubGoogleSignIn()),
    googleAuthServiceProvider.overrideWith((ref) => StubGoogleAuth()),
    hiveServiceProvider.overrideWith((ref) => MemoryHiveService(ref)),
    addressControllerProvider.overrideWith((ref) => StubAddressController(ref)),
    otherServiceProvider.overrideWith((ref) => StubProfileService(ref)),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Mulish',
    )..addFont(rootBundle.load('assets/font/Mulish-Regular.ttf'))).load();
  });

  test(
    'Google code is exchanged for the existing backend user session',
    () async {
      final container = loginContainer();
      addTearDown(container.dispose);
      final auth = container.read(authControllerProvider.notifier);
      final native =
          container.read(googleSignInServiceProvider) as StubGoogleSignIn;
      final backend =
          container.read(googleAuthServiceProvider) as StubGoogleAuth;
      final storage = container.read(hiveServiceProvider) as MemoryHiveService;

      final result = await auth.loginWithGoogle();

      expect(result.isSuccess, isTrue);
      expect(native.clientId, webClientId);
      expect(backend.codes, ['one-time-code']);
      expect(storage.user?.id, 42);
      expect(storage.token, 'backend-session-token');
      expect(
        container.read(apiClientProvider).defaultHeaders['authorization'],
        'Bearer backend-session-token',
      );
      expect(container.read(authControllerProvider), isFalse);
    },
  );

  for (final canceled in [false, true]) {
    test(
      'cancellation is silent and does not create a session ($canceled)',
      () async {
        final container = loginContainer();
        addTearDown(container.dispose);
        final native =
            container.read(googleSignInServiceProvider) as StubGoogleSignIn;
        native.onRequest = () async {
          if (canceled) {
            throw const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            );
          }
          return null;
        };
        final result = await container
            .read(authControllerProvider.notifier)
            .loginWithGoogle();
        expect(result.isSuccess, isFalse);
        expect(result.message, isEmpty);
        expect(
          (container.read(googleAuthServiceProvider) as StubGoogleAuth).codes,
          isEmpty,
        );
        expect(
          (container.read(hiveServiceProvider) as MemoryHiveService).token,
          isNull,
        );
        expect(container.read(authControllerProvider), isFalse);
      },
    );
  }

  test('disabled or missing OAuth configuration never opens Google', () async {
    for (final container in [
      loginContainer(active: false),
      loginContainer(clientId: ''),
    ]) {
      addTearDown(container.dispose);
      final result = await container
          .read(authControllerProvider.notifier)
          .loginWithGoogle();
      expect(result.isSuccess, isFalse);
      expect(
        (container.read(googleSignInServiceProvider) as StubGoogleSignIn).calls,
        0,
      );
      expect(container.read(authControllerProvider), isFalse);
    }
  });

  test(
    'backend rejection resets loading without saving an authenticated user',
    () async {
      final container = loginContainer();
      addTearDown(container.dispose);
      (container.read(googleAuthServiceProvider) as StubGoogleAuth).error =
          const GoogleLoginException('Account is unavailable.');
      final result = await container
          .read(authControllerProvider.notifier)
          .loginWithGoogle();
      expect(result.isSuccess, isFalse);
      expect(result.message, 'Account is unavailable.');
      final storage = container.read(hiveServiceProvider) as MemoryHiveService;
      expect(storage.user, isNull);
      expect(storage.token, isNull);
      expect(container.read(authControllerProvider), isFalse);
    },
  );

  test('repeated taps start one Google authentication request', () async {
    final container = loginContainer();
    addTearDown(container.dispose);
    final pending = Completer<String?>();
    final native =
        container.read(googleSignInServiceProvider) as StubGoogleSignIn;
    native.onRequest = () => pending.future;
    final auth = container.read(authControllerProvider.notifier);
    final first = auth.loginWithGoogle();
    expect(container.read(authControllerProvider), isTrue);
    expect((await auth.loginWithGoogle()).isSuccess, isFalse);
    expect(native.calls, 1);
    pending.complete('one-time-code');
    expect((await first).isSuccess, isTrue);
    expect(container.read(authControllerProvider), isFalse);
  });

  test(
    'new Google user receives the admin default country and dial code',
    () async {
      final container = loginContainer(
        defaultCountry: Country(id: 77, name: 'India', phoneCode: '91'),
      );
      addTearDown(container.dispose);
      final result = await container
          .read(authControllerProvider.notifier)
          .loginWithGoogle();
      expect(result.isSuccess, isTrue);
      final user =
          (container.read(hiveServiceProvider) as MemoryHiveService).user;
      expect(user?.country, 'India');
      expect(user?.phoneCode, '91');
      expect(user?.phone, isNull);
    },
  );

  test(
    'Google login refreshes an existing profile using the new shop token',
    () async {
      final container = loginContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(
        profileInfoControllerProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(profileInfoControllerProvider).value?.id, 1);
      final result = await container
          .read(authControllerProvider.notifier)
          .loginWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(result.isSuccess, isTrue);
      expect(container.read(profileInfoControllerProvider).value?.id, 42);
      final profile =
          container.read(otherServiceProvider) as StubProfileService;
      expect(profile.headers, [null, 'Bearer backend-session-token']);
    },
  );

  test(
    'API sends a server code to the shop endpoint, never a client identity',
    () async {
      final adapter = RecordingAdapter(sessionPayload());
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final service = GoogleAuthService(
        dio: dio,
        getDeviceToken: () async => 'push-token',
      );
      final result = await service.exchangeAuthorizationCode(
        code: 'server-code',
      );
      expect(
        adapter.request?.uri.toString(),
        'https://shop.itrsp.com/api/auth/google/token',
      );
      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.data, {
        'code': 'server-code',
        'data': {},
        'device_key': 'push-token',
        'device_type': 'android',
      });
      expect(adapter.request?.followRedirects, isFalse);
      expect(result.accessToken, 'backend-session-token');
      expect(result.user.email, 'customer@example.test');
    },
  );

  test('push registration failure does not block Google login', () async {
    final adapter = RecordingAdapter(sessionPayload());
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final service = GoogleAuthService(
      dio: dio,
      getDeviceToken: () async => throw StateError('No push permission'),
    );
    expect(
      (await service.exchangeAuthorizationCode(code: 'server-code')).user.id,
      42,
    );
    expect(adapter.request?.data.containsKey('device_key'), isFalse);
  });

  test(
    'API rejects successful HTTP responses without a complete backend session',
    () async {
      for (final payload in [
        '<html>Unexpected page</html>',
        {
          'data': {
            'user': {'id': 42},
            'access': {'token': ''},
          },
        },
        {
          'data': {
            'user': {},
            'access': {'token': 'token'},
          },
        },
        {
          'data': {
            'access': {'token': 'token'},
          },
        },
      ]) {
        final dio = Dio()..httpClientAdapter = RecordingAdapter(payload);
        addTearDown(() => dio.close(force: true));
        final service = GoogleAuthService(
          dio: dio,
          getDeviceToken: () async => null,
        );
        await expectLater(
          service.exchangeAuthorizationCode(code: 'code'),
          throwsA(isA<GoogleLoginException>()),
        );
      }
    },
  );

  test(
    'API reports rejected authorization and hides server failures',
    () async {
      for (final status in [403, 500]) {
        final dio = Dio()
          ..httpClientAdapter = RecordingAdapter({
            'message': 'Account disabled',
          }, status: status);
        addTearDown(() => dio.close(force: true));
        final service = GoogleAuthService(
          dio: dio,
          getDeviceToken: () async => null,
        );
        await expectLater(
          service.exchangeAuthorizationCode(code: 'code'),
          throwsA(
            isA<GoogleLoginException>().having(
              (e) => e.message,
              'message',
              status == 403
                  ? equals('Account disabled')
                  : isNot(contains('Account disabled')),
            ),
          ),
        );
      }
    },
  );

  testWidgets(
    'Google button works with empty password fields and disables repeats',
    (tester) async {
      final container = loginContainer();
      addTearDown(container.dispose);
      final pending = Completer<String?>();
      final native =
          container.read(googleSignInServiceProvider) as StubGoogleSignIn;
      native.onRequest = () => pending.future;
      await showLogin(tester, container);
      final button = find.byKey(const ValueKey('google-login-button'));
      expect(native.prepareCalls, 1);
      expect(native.calls, 0);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(native.calls, 1);
      expect(
        find.byKey(const ValueKey('google-login-progress')),
        findsOneWidget,
      );
      expect(find.text('Signing you in…'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      pending.complete(null);
      await tester.pump();
      await tester.pump();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const ValueKey('google-login-progress')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'successful Google login opens the shop and removes the login route',
    (tester) async {
      final container = loginContainer();
      addTearDown(container.dispose);
      await showLogin(tester, container);
      final button = find.byKey(const ValueKey('google-login-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Shop home'), findsOneWidget);
      expect(find.byType(LoginLayout), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Shop home'))).canPop(),
        isFalse,
      );
      expect(
        (container.read(addressControllerProvider.notifier)
                as StubAddressController)
            .calls,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('admin can hide Google login', (tester) async {
    final container = loginContainer(active: false);
    addTearDown(container.dispose);
    await showLogin(tester, container);
    expect(find.byKey(const ValueKey('google-login-button')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'progress stays visible after account selection until the shop session is ready',
    (tester) async {
      final container = loginContainer();
      addTearDown(container.dispose);
      final backend =
          container.read(googleAuthServiceProvider) as StubGoogleAuth;
      final pendingSession = Completer<GoogleAuthSession>();
      backend.onExchange = () => pendingSession.future;
      await showLogin(tester, container);
      final button = find.byKey(const ValueKey('google-login-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(backend.codes, ['one-time-code']);
      expect(find.text('Signing you in…'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('google-login-progress')),
        findsOneWidget,
      );
      pendingSession.complete(session());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Shop home'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> showLogin(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          theme: getAppTheme(context: context, isDarkTheme: false),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const LoginLayout(),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Shop home')),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class StubMasterController extends MasterController {
  StubMasterController(
    super.ref,
    this.active,
    this.clientId, {
    this.defaultCountry,
  });
  final Country? defaultCountry;
  final bool active;
  final String? clientId;
  @override
  MasterModel get materModel {
    return MasterModel.fromJson({
      'message': 'Settings',
      'data': {
        'currency': {
          'name': 'INR',
          'symbol': 'Rs',
          'rate': 1.0,
          'position': 'prefix',
        },
        'currencies': [],
        'payment_gateways': [],
        'multi_vendor': false,
        'default_country': defaultCountry?.toMap(),
        'app_logo': '',
        'app_name': 'eShop',
        'web_logo': '',
        'cash_on_delivery': true,
        'online_payment': true,
        'register_otp_type': 'email',
        'order_place_account_verify': false,
        'register_otp_verify': false,
        'forgot_otp_type': 'email',
        'social_auths': {
          'google': {'is_active': active, 'client_id': clientId},
        },
        'theme_colors': {'primary': '#000000'},
        'phone_required': false,
        'phone_min_length': 9,
        'phone_max_length': 16,
      },
    });
  }
}

class StubGoogleSignIn extends GoogleSignInService {
  int calls = 0;
  int prepareCalls = 0;
  @override
  Future<void> prepare({required String serverClientId}) async {
    prepareCalls++;
  }

  String? clientId;
  Future<String?> Function() onRequest = () async => 'one-time-code';
  @override
  Future<String?> requestAuthorizationCode({required String serverClientId}) {
    calls++;
    clientId = serverClientId;
    return onRequest();
  }
}

class StubGoogleAuth extends GoogleAuthService {
  final codes = <String>[];
  GoogleLoginException? error;
  Future<GoogleAuthSession> Function()? onExchange;
  @override
  Future<GoogleAuthSession> exchangeAuthorizationCode({
    required String code,
  }) async {
    codes.add(code);
    if (error != null) throw error!;
    if (onExchange != null) return onExchange!();
    return session();
  }
}

class MemoryHiveService extends HiveService {
  MemoryHiveService(super.ref);
  User? user;
  String? token;
  @override
  Future<void> saveUserInfo({required User userInfo}) async => user = userInfo;
  @override
  Future<void> saveUserAuthToken({required String authToken}) async =>
      token = authToken;
  @override
  bool userIsLoggedIn() => token != null;
}

class StubAddressController extends AddressController {
  StubAddressController(super.ref);
  int calls = 0;
  @override
  Future<CommonResponse> getAddress() async {
    calls++;
    return CommonResponse(isSuccess: true, message: '');
  }
}

class StubProfileService extends OtherServiceProvider {
  StubProfileService(super.ref);
  final headers = <Object?>[];
  @override
  Future<Response> getProfileinfo() async {
    final token = ref.read(apiClientProvider).defaultHeaders['authorization'];
    headers.add(token);
    return Response(
      requestOptions: RequestOptions(path: '/profile'),
      statusCode: 200,
      data: {
        'data': {
          'user': {'id': token == null ? 1 : 42, 'name': 'Customer'},
        },
      },
    );
  }
}

class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.payload, {this.status = 200});
  final Object payload;
  final int status;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
