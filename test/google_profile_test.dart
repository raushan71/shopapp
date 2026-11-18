import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itrsp_shop/components/ecommerce/profile_avatar.dart';
import 'package:itrsp_shop/config/app_constants.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/controllers/common/other_controller.dart';
import 'package:itrsp_shop/controllers/common/master_controller.dart';
import 'package:itrsp_shop/models/common/master_model.dart';
import 'package:itrsp_shop/models/common/all_country_model/country.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/user.dart';
import 'package:itrsp_shop/services/common/hive_service_provider.dart';
import 'package:itrsp_shop/utils/user_country_defaults.dart';
import 'package:itrsp_shop/views/eCommerce/more/layouts/more_layout.dart';
import 'package:itrsp_shop/views/eCommerce/profile/layouts/profile_layout.dart';

User googleUser() => User.fromMap({
  'id': 42,
  'name': 'Google Customer',
  'email': 'customer@example.test',
});

class TestProfileController extends ProfileInfoController {
  TestProfileController(super.ref, {bool failed = false}) {
    state = failed
        ? AsyncError(StateError('Offline'), StackTrace.current)
        : AsyncData(googleUser());
  }
  int calls = 0;
  @override
  Future<void> getProfileInfo() async {
    calls++;
    state = AsyncData(googleUser());
  }
}

Future<void> showPage(
  WidgetTester tester,
  ProviderContainer container,
  Widget page,
) async {
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
          home: page,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final folder = await Directory(
      'build/google-profile-fixtures',
    ).create(recursive: true);
    final fixture = await folder.createTemp('run-');
    Hive.init(fixture.absolute.path);
    await Hive.openBox(AppConstants.appSettingsBox);
    await Hive.openBox(AppConstants.authBox);
    await Hive.openBox(AppConstants.userBox);
    await (FontLoader(
      'Mulish',
    )..addFont(rootBundle.load('assets/font/Mulish-Regular.ttf'))).load();
  });
  tearDownAll(Hive.close);

  test(
    'country defaults preserve saved countries and matching partial data',
    () {
      final india = Country(name: 'India', phoneCode: '91');
      final saved = googleUser().copyWith(
        country: 'United Kingdom',
        phoneCode: '44',
      );
      expect(withDefaultCountry(saved, india).country, 'United Kingdom');
      expect(withDefaultCountry(saved, india).phoneCode, '44');
      expect(
        withDefaultCountry(
          googleUser().copyWith(country: 'India'),
          india,
        ).phoneCode,
        '91',
      );
      expect(
        withDefaultCountry(
          googleUser().copyWith(phoneCode: '+91'),
          india,
        ).country,
        'India',
      );
      expect(
        withDefaultCountry(
          googleUser().copyWith(phoneCode: '44'),
          india,
        ).country,
        isNull,
      );
      expect(withDefaultCountry(googleUser(), null).country, isNull);
    },
  );
  setUp(() async {
    await Hive.box(AppConstants.userBox).clear();
    await Hive.box(
      AppConstants.userBox,
    ).put(AppConstants.userData, googleUser().toMap());
    await Hive.box(
      AppConstants.authBox,
    ).put(AppConstants.authToken, 'test-session');
  });

  ProviderContainer profileContainer({bool failed = false}) =>
      ProviderContainer(
        overrides: [
          profileInfoControllerProvider.overrideWith(
            (ref) => TestProfileController(ref, failed: failed),
          ),
        ],
      );

  testWidgets('account page renders a Google user without phone or photo', (
    tester,
  ) async {
    final container = profileContainer();
    addTearDown(container.dispose);
    await showPage(tester, container, const EcommerceMoreLayout());
    expect(find.text('Google Customer'), findsOneWidget);
    expect(find.text('customer@example.test'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'profile form loads Google name and email with an empty phone field',
    (tester) async {
      final container = profileContainer();
      addTearDown(container.dispose);
      await showPage(tester, container, const ProfileLayout());
      final values = tester
          .widgetList<FormBuilderTextField>(find.byType(FormBuilderTextField))
          .map((field) => field.controller?.text)
          .toList();
      expect(
        values,
        containsAll(['Google Customer', 'customer@example.test', '']),
      );
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('profile failure shows retry and recovers without a blank page', (
    tester,
  ) async {
    final container = profileContainer(failed: true);
    addTearDown(container.dispose);
    await showPage(tester, container, const ProfileLayout());
    expect(
      find.text('Unable to load your profile. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(FormBuilder), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('avatar handles absent and blank image URLs', (tester) async {
    for (final photo in [null, '', '   ']) {
      await tester.pumpWidget(
        MaterialApp(home: ProfileAvatar(size: 72, imageUrl: photo)),
      );
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'profile selects defaults when settings arrive and preserves user selection',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileInfoControllerProvider.overrideWith(
            (ref) => TestProfileController(ref),
          ),
          masterControllerProvider.overrideWith(
            (ref) => CountryMasterController(ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      await showPage(tester, container, const ProfileLayout());
      final fields = tester
          .widgetList<FormBuilderTextField>(find.byType(FormBuilderTextField))
          .toList();
      final country = fields
          .firstWhere((field) => field.name == 'Country')
          .controller!;
      expect(country.text, isEmpty);
      final master =
          container.read(masterControllerProvider.notifier)
              as CountryMasterController;
      master.selectDefault(Country(name: 'India', phoneCode: '91'));
      await tester.pump();
      expect(country.text, 'India');
      expect(find.text('91'), findsOneWidget);
      country.text = 'United Kingdom';
      master.selectDefault(Country(name: 'India', phoneCode: '91'));
      await tester.pump();
      expect(country.text, 'United Kingdom');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'leaving profile while the cached user loads does not update disposed state',
    (tester) async {
      final pending = Completer<User?>();
      final container = ProviderContainer(
        overrides: [
          profileInfoControllerProvider.overrideWith(
            (ref) => TestProfileController(ref),
          ),
          hiveServiceProvider.overrideWith(
            (ref) => DelayedHiveService(ref, pending.future),
          ),
        ],
      );
      addTearDown(container.dispose);
      await showPage(tester, container, const ProfileLayout());
      await tester.pumpWidget(const SizedBox());
      pending.complete(googleUser());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

class DelayedHiveService extends HiveService {
  DelayedHiveService(super.ref, this.pending);
  final Future<User?> pending;
  @override
  Future<User?> getUserInfo() => pending;
}

class CountryMasterController extends MasterController {
  CountryMasterController(super.ref);
  Country? selected;
  void selectDefault(Country country) {
    selected = country;
    state = !state;
  }

  @override
  MasterModel get materModel => MasterModel(
    message: '',
    data:
        Data(
            currency: Currency.empty(),
            paymentGateways: [],
            isMultiVendor: false,
            defaultCountry: selected,
          )
          ..phoneRequired = false
          ..phoneMinLength = 9
          ..phoneMaxLength = 16
          ..registerOtpType = 'email',
  );
}
