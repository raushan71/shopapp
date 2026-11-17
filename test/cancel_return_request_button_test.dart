import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/eCommerce/common/common_response.dart';
import 'package:itrsp_shop/views/eCommerce/return_order/componants/cancel_return_request_button.dart';

Future<void> showCancelButton(
  WidgetTester tester, {
  required Future<CommonResponse> Function() onCancel,
  required VoidCallback onCancelled,
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: Center(
        child: CancelReturnRequestButton(
          onCancel: onCancel,
          onCancelled: onCancelled,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> confirmCancellation(WidgetTester tester) async {
  await tester.tap(find.byType(OutlinedButton));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Cancel return request'));
}

void main() {
  testWidgets('keeping the return request never calls cancellation',
      (tester) async {
    var calls = 0;
    await showCancelButton(tester,
        onCancel: () async {
          calls++;
          return CommonResponse(isSuccess: true, message: 'Cancelled');
        },
        onCancelled: () => fail('The request was kept'));

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this return request?'), findsOneWidget);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Keep request'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull);
  });

  testWidgets('cancelling disables repeat taps and refreshes after success',
      (tester) async {
    var calls = 0;
    var refreshes = 0;
    final request = Completer<CommonResponse>();
    await showCancelButton(tester,
        onCancel: () {
          calls++;
          return request.future;
        },
        onCancelled: () => refreshes++);

    await confirmCancellation(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls, 1);
    expect(refreshes, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull);
    await tester.tap(find.byType(OutlinedButton));
    expect(calls, 1);

    request.complete(CommonResponse(isSuccess: true, message: 'Cancelled'));
    await tester.pumpAndSettle();

    expect(refreshes, 1);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rejected cancellation preserves the request and permits retry',
      (tester) async {
    var calls = 0;
    var refreshes = 0;
    await showCancelButton(tester,
        onCancel: () async {
          calls++;
          return CommonResponse(
            isSuccess: calls > 1,
            message: calls == 1 ? 'Return already approved' : 'Cancelled',
          );
        },
        onCancelled: () => refreshes++);

    await confirmCancellation(tester);
    await tester.pumpAndSettle();
    expect(refreshes, 0);
    expect(find.text('Return already approved'), findsOneWidget);

    await confirmCancellation(tester);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(refreshes, 1);
  });

  testWidgets('network failures restore the cancel button', (tester) async {
    await showCancelButton(
      tester,
      onCancel: () => Future.error(StateError('Offline')),
      onCancelled: () => fail('The cancellation failed'),
    );

    await confirmCancellation(tester);
    await tester.pumpAndSettle();

    expect(find.text('Unable to cancel the return request. Please try again.'),
        findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during cancellation does not update a disposed widget',
      (tester) async {
    final request = Completer<CommonResponse>();
    await showCancelButton(
      tester,
      onCancel: () => request.future,
      onCancelled: () => fail('The user left the screen'),
    );

    await confirmCancellation(tester);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    request.complete(CommonResponse(isSuccess: true, message: 'Cancelled'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
