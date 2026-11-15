import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ready_ecommerce/config/theme.dart';
import 'package:ready_ecommerce/controllers/common/master_controller.dart';
import 'package:ready_ecommerce/controllers/eCommerce/authentication/authentication_controller.dart';
import 'package:ready_ecommerce/generated/l10n.dart';
import 'package:ready_ecommerce/models/common/master_model.dart';
import 'package:ready_ecommerce/models/eCommerce/authentication/sign_up.dart';
import 'package:ready_ecommerce/models/eCommerce/common/common_response.dart';
import 'package:ready_ecommerce/services/common/country_service_provider.dart';
import 'package:ready_ecommerce/services/common/master_service_provider.dart';
import 'package:ready_ecommerce/views/common/authentication/layouts/sign_up_layout.dart';

const india = {'id': 77, 'name': 'India', 'phone_code': '91'};
const unitedKingdom = {
  'id': 210,
  'name': 'United Kingdom',
  'phone_code': '44',
};

Map<String, dynamic> masterPayload(Map<String, Object>? defaultCountry) => {
      'message': 'Settings',
      'data': {
        'currency': {
          'name': 'INR',
          'symbol': '₹',
          'rate': 1.0,
          'position': 'prefix',
        },
        'currencies': [],
        'payment_gateways': [],
        'multi_vendor': false,
        'default_country': defaultCountry,
        'app_logo': '',
        'app_name': 'Shop',
        'web_logo': '',
        'cash_on_delivery': true,
        'online_payment': true,
        'register_otp_type': 'email',
        'order_place_account_verify': false,
        'register_otp_verify': false,
        'forgot_otp_type': 'email',
        'social_auths': <String, dynamic>{},
        'theme_colors': {'primary': '#000000'},
        'phone_required': false,
        'phone_min_length': 9,
        'phone_max_length': 16,
      },
    };

Response apiResponse(Object data) => Response(
      requestOptions: RequestOptions(path: '/settings'),
      statusCode: 200,
      data: data,
    );

ProviderContainer signupContainer({Completer<Response>? countriesRequest}) =>
    ProviderContainer(overrides: [
      authControllerProvider
          .overrideWith((ref) => RecordingAuthController(ref)),
      masterServiceProvider.overrideWith((ref) => StubMasterService(ref)),
      countryServiceProvider.overrideWith(
        (ref) => StubCountryService(ref, countriesRequest),
      ),
    ]);

Future<void> showSignup(
    WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(
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
        home: const SignUpLayout(),
      ),
    ),
  ));
  await tester.pump();
}

Object? countryFieldValue(WidgetTester tester) => tester
    .state<FormBuilderState>(find.byType(FormBuilder))
    .fields['country']
    ?.value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Mulish')
      ..addFont(rootBundle.load('assets/font/Mulish-Regular.ttf'));
    await fonts.load();
  });

  test('master settings retain the admin default country and phone code', () {
    final settings = MasterModel.fromJson(masterPayload(india));
    expect(settings.data.defaultCountry?.id, 77);
    expect(settings.data.defaultCountry?.name, 'India');
    expect(settings.data.defaultCountry?.phoneCode, '91');
    expect(settings.toJson()['data']['default_country'], india);
    expect(MasterModel.empty().data.defaultCountry, isNull);
    expect(
        MasterModel.fromJson(masterPayload(null)).data.defaultCountry, isNull);
  });

  testWidgets(
      'signup selects the configured country and displays its dial code',
      (tester) async {
    final container = signupContainer();
    addTearDown(container.dispose);
    await container.read(masterControllerProvider.notifier).getMasterData();

    await showSignup(tester, container);

    expect(countryFieldValue(tester), 77);
    expect(find.text('+91'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup applies defaults when the country list arrives later',
      (tester) async {
    final request = Completer<Response>();
    final container = signupContainer(countriesRequest: request);
    addTearDown(container.dispose);
    await container.read(masterControllerProvider.notifier).getMasterData();
    await showSignup(tester, container);
    expect(find.text('+00'), findsOneWidget);

    request.complete(apiResponse({
      'data': {
        'countries': [india, unitedKingdom]
      },
    }));
    await tester.pump();
    await tester.pump();

    expect(countryFieldValue(tester), 77);
    expect(find.text('+91'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'signup submits the default country and code without selecting it',
      (tester) async {
    final container = signupContainer();
    addTearDown(container.dispose);
    await container.read(masterControllerProvider.notifier).getMasterData();
    await showSignup(tester, container);
    final textFields = tester
        .widgetList<FormBuilderTextField>(find.byType(FormBuilderTextField))
        .toList();
    textFields[0].controller!.text = 'Test Customer';
    textFields[1].controller!.text = '9876543210';
    textFields[2].controller!.text = 'signup@example.com';
    textFields[3].controller!.text = 'test-password';
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    final auth = container.read(authControllerProvider.notifier)
        as RecordingAuthController;
    expect(auth.submitted?.toMap()['country'], 'India');
    expect(auth.submitted?.toMap()['phone_code'], '91');
    expect(auth.submitted?.phone, '9876543210');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'late admin settings update the country and preserve user changes',
      (tester) async {
    final container = signupContainer();
    addTearDown(container.dispose);
    await showSignup(tester, container);
    expect(countryFieldValue(tester), isNull);

    await container.read(masterControllerProvider.notifier).getMasterData();
    await tester.pump();
    expect(countryFieldValue(tester), 77);
    expect(find.text('+91'), findsOneWidget);

    final dropdown = find.byType(FormBuilderDropdown<int>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('United Kingdom').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(countryFieldValue(tester), 210);
    expect(find.text('+44'), findsOneWidget);

    await container.read(masterControllerProvider.notifier).getMasterData();
    await tester.pump();
    expect(countryFieldValue(tester), 210);
    expect(find.text('+44'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class RecordingAuthController extends AuthController {
  RecordingAuthController(super.ref);

  SingUp? submitted;
  final response = Completer<CommonResponse>();

  @override
  Future<CommonResponse> singUp({required SingUp singUpInfo}) {
    submitted = singUpInfo;
    return response.future;
  }
}

class StubMasterService extends MasterServiceProvider {
  StubMasterService(super.ref);

  @override
  Future<Response> getMasterSettings() async =>
      apiResponse(masterPayload(india));
}

class StubCountryService extends CountryServiceProvider {
  StubCountryService(super.ref, this.request);

  final Completer<Response>? request;

  @override
  Future<Response> getAllCountry() async {
    if (request != null) return request!.future;
    return apiResponse({
      'data': {
        'countries': [india, unitedKingdom]
      },
    });
  }
}
