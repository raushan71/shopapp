import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itrsp_shop/config/app_constants.dart';
import 'package:itrsp_shop/controllers/eCommerce/order/order_controller.dart';
import 'package:itrsp_shop/controllers/eCommerce/return_policy/return_policy_controller.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/eCommerce/order/order_details_model.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_details_model/return_orders.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_list_model/return_order.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_submit_model.dart';
import 'package:itrsp_shop/services/eCommerce/return_product/return_product_service.dart';
import 'package:itrsp_shop/utils/api_client.dart';
import 'package:itrsp_shop/views/eCommerce/order_details/components/order_return_requests.dart';

const originalOrder = (orderId: 42, orderCode: 'ORDER-42');

Response response(Object data, {int status = 200}) => Response(
      requestOptions: RequestOptions(path: '/return-orders/123/cancel'),
      statusCode: status,
      data: data,
    );

Response cancelledResponse() => response({
      'message': 'Return request cancelled successfully',
      'data': {
        'returnOrder': {
          'id': 123,
          'status': 'Cancelled',
          'can_cancel': false,
        },
      },
    });

ProviderContainer returnContainer() => ProviderContainer(overrides: [
      returnProductServiceProvider
          .overrideWith((ref) => StubReturnService(ref)),
    ]);

Products selectedProduct() => Products(
      id: 7,
      name: 'Leggings',
      brand: null,
      thumbnail: '',
      price: 499,
      orderQty: 1,
      color: null,
      size: null,
      discountPrice: 0,
      rating: null,
      isReturnable: true,
    );

Future<void> showRequests(
    WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: Dialog(
          child: SingleChildScrollView(
            child: OrderReturnRequests(orderId: 42, orderCode: 'ORDER-42'),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> confirmCancel(WidgetTester tester) async {
  // Include the OutlinedButton.icon subclass used by Flutter 3.35.
  await tester.tap(find.bySubtype<OutlinedButton>());
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Cancel return request'));
  await tester.pumpAndSettle();
}

void main() {
  test('both return models use can_cancel rather than inferring from Pending',
      () {
    for (final flag in [true, false, null]) {
      final payload = {
        'id': 123,
        'order_id': 42,
        'status': 'Pending',
        if (flag != null) 'can_cancel': flag,
      };
      final summary = ReturnOrder.fromMap(payload);
      final details = ReturnOrders.fromMap(payload);

      expect(summary.canCancel, flag == true);
      expect(details.canCancel, flag == true);
      expect(summary.orderId, '42');
      expect(details.orderId, '42');
      expect(summary.toMap()['can_cancel'], flag == true);
      expect(details.toMap()['can_cancel'], flag == true);
    }
  });

  test('service posts to the return request ID with no order or item payload',
      () async {
    final client = RecordingApiClient();
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    await container
        .read(returnProductServiceProvider)
        .cancelReturnRequest(returnRequestId: 123);

    expect(client.url, '${AppConstants.baseUrl}/return-orders/123/cancel');
    expect(client.body, isNull);
  });

  test('order details match return requests by original ID or order code',
      () async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    service.extraRequests = [
      {'id': 124, 'order_id': 42, 'can_cancel': true},
      {'id': 42, 'order_id': 'ANOTHER-ORDER', 'can_cancel': true},
    ];

    final requests =
        await container.read(orderReturnRequestsProvider(originalOrder).future);

    expect(requests.map((request) => request.id), [123, 124]);
  });

  test('successful cancellation refreshes order and return data and selections',
      () async {
    var orderDetailsBuilds = 0;
    final container = ProviderContainer(overrides: [
      returnProductServiceProvider
          .overrideWith((ref) => StubReturnService(ref)),
      orderDetailsControllerProvider(42).overrideWith((ref) {
        orderDetailsBuilds++;
        return OrderDetailsController(ref);
      }),
    ]);
    addTearDown(container.dispose);
    container.listen(orderDetailsControllerProvider(42), (_, __) {});
    container.listen(orderReturnRequestsProvider(originalOrder), (_, __) {});
    container.listen(returnOrderDetailsControllerProvider(123), (_, __) {});
    await container.read(orderReturnRequestsProvider(originalOrder).future);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    container
        .read(selectedReturnProductProvider.notifier)
        .toggleProductSelection(selectedProduct());
    service.onCancel = (_) async {
      service.status = 'Cancelled';
      service.canCancel = false;
      return cancelledResponse();
    };

    final result = await container
        .read(returnCancellationControllerProvider.notifier)
        .cancelReturnRequest(returnRequestId: 123);
    final requests =
        await container.read(orderReturnRequestsProvider(originalOrder).future);
    await Future<void>.delayed(Duration.zero);

    expect(result.isSuccess, isTrue);
    expect(service.cancelledIds, [123]);
    expect(requests.single.status, 'Cancelled');
    expect(requests.single.canCancel, isFalse);
    expect(orderDetailsBuilds, 2);
    expect(service.detailsCalls, 2);
    expect(container.read(selectedReturnProductProvider), isEmpty);
    expect(container.read(returnCancellationControllerProvider), isEmpty);
    expect(
        container
            .read(returnOrderListProvider)
            .value!
            .data!
            .returnOrders!
            .single
            .canCancel,
        isFalse);
  });

  test('newly submitted returns appear in already-open order details',
      () async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    service.includeRequest = false;
    container.listen(orderReturnRequestsProvider(originalOrder), (_, __) {});
    expect(
        await container.read(orderReturnRequestsProvider(originalOrder).future),
        isEmpty);

    final result = await container
        .read(returnSubmitControllerProvider.notifier)
        .submitReturnProduct(
          returnOrder: ReturnOrderSubmitModel(
            orderId: 42,
            reason: 'Wrong size',
            retrunAddress: 'Customer address',
            bankAccountNo: '12345678',
            productIds: [7],
          ),
        );
    final requests =
        await container.read(orderReturnRequestsProvider(originalOrder).future);

    expect(result.isSuccess, isTrue);
    expect(requests.single.id, 123);
    expect(requests.single.canCancel, isTrue);
  });

  test('late return-details responses are ignored after disposal', () async {
    final container = returnContainer();
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    final request = Completer<Response>();
    service.onDetails = (_) => request.future;
    container.listen(returnOrderDetailsControllerProvider(123), (_, __) {});
    container.dispose();

    request.complete(response({
      'data': {'returnOrders': service.request}
    }));
    await Future<void>.delayed(Duration.zero);
  });

  test('cancellation can finish after leaving its provider scope', () async {
    final container = returnContainer();
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    final request = Completer<Response>();
    service.onCancel = (_) => request.future;
    final cancellation = container
        .read(returnCancellationControllerProvider.notifier)
        .cancelReturnRequest(returnRequestId: 123);
    container.dispose();

    request.complete(cancelledResponse());
    expect((await cancellation).isSuccess, isTrue);
  });

  for (final status in [401, 404, 422]) {
    test('HTTP $status preserves the request and returns the API error',
        () async {
      final container = returnContainer();
      addTearDown(container.dispose);
      final service =
          container.read(returnProductServiceProvider) as StubReturnService;
      service.onCancel = (_) async => response(
            {'message': 'Cannot cancel ($status)'},
            status: status,
          );
      container
          .read(selectedReturnProductProvider.notifier)
          .toggleProductSelection(selectedProduct());

      final result = await container
          .read(returnCancellationControllerProvider.notifier)
          .cancelReturnRequest(returnRequestId: 123);

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Cannot cancel ($status)');
      expect(container.read(selectedReturnProductProvider), hasLength(1));
      expect(container.read(returnCancellationControllerProvider), isEmpty);
    });
  }

  test('network failure resets loading and allows cancellation to be retried',
      () async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    final controller =
        container.read(returnCancellationControllerProvider.notifier);
    service.onCancel = (_) => Future.error(DioException(
          requestOptions: RequestOptions(path: '/return-orders/123/cancel'),
          type: DioExceptionType.connectionError,
        ));

    expect(
        (await controller.cancelReturnRequest(returnRequestId: 123)).isSuccess,
        isFalse);
    expect(container.read(returnCancellationControllerProvider), isEmpty);

    service.onCancel = null;
    expect(
        (await controller.cancelReturnRequest(returnRequestId: 123)).isSuccess,
        isTrue);
    expect(service.cancelledIds, [123, 123]);
  });

  test('duplicate cancellation does not send a second API request', () async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    final controller =
        container.read(returnCancellationControllerProvider.notifier);
    final request = Completer<Response>();
    service.onCancel = (_) => request.future;

    final first = controller.cancelReturnRequest(returnRequestId: 123);
    final second = await controller.cancelReturnRequest(returnRequestId: 123);
    expect(second.isSuccess, isFalse);
    expect(service.cancelledIds, [123]);
    expect(container.read(returnCancellationControllerProvider), {123});

    request.complete(cancelledResponse());
    expect((await first).isSuccess, isTrue);
    expect(container.read(returnCancellationControllerProvider), isEmpty);
  });

  testWidgets('return modal cancels the request and updates its status',
      (tester) async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    service.onCancel = (_) async {
      service.status = 'Cancelled';
      service.canCancel = false;
      return cancelledResponse();
    };
    await showRequests(tester, container);

    expect(find.bySubtype<OutlinedButton>(), findsOneWidget);
    expect(find.text('Return Status: Pending'), findsOneWidget);
    await confirmCancel(tester);

    expect(service.cancelledIds, [123]);
    expect(find.bySubtype<OutlinedButton>(), findsNothing);
    expect(find.text('Return Status: Cancelled'), findsOneWidget);
    expect(find.text('Return request cancelled successfully'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pending without can_cancel never exposes cancellation',
      (tester) async {
    final container = returnContainer();
    addTearDown(container.dispose);
    (container.read(returnProductServiceProvider) as StubReturnService)
        .canCancel = false;
    await showRequests(tester, container);

    expect(find.text('Return Status: Pending'), findsOneWidget);
    expect(find.bySubtype<OutlinedButton>(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a processed request refreshes eligibility after HTTP 422',
      (tester) async {
    final container = returnContainer();
    addTearDown(container.dispose);
    final service =
        container.read(returnProductServiceProvider) as StubReturnService;
    service.onCancel = (_) async {
      service.status = 'Approved';
      service.canCancel = false;
      return response({'message': 'Return already processed'}, status: 422);
    };
    await showRequests(tester, container);
    await confirmCancel(tester);

    expect(find.text('Return already processed'), findsOneWidget);
    expect(find.text('Return Status: Approved'), findsOneWidget);
    expect(find.bySubtype<OutlinedButton>(), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class RecordingApiClient extends ApiClient {
  String? url;
  dynamic body;

  @override
  Future<Response> post(String url,
      {dynamic data, Map<String, dynamic>? headers}) async {
    this.url = url;
    body = data;
    return cancelledResponse();
  }
}

class StubReturnService extends ReturnProductServiceImpl {
  StubReturnService(super.ref);

  String status = 'Pending';
  bool canCancel = true;
  bool includeRequest = true;
  int detailsCalls = 0;
  List<Map<String, dynamic>> extraRequests = [];
  final List<int> cancelledIds = [];
  Future<Response> Function(int)? onCancel;
  Future<Response> Function(int)? onDetails;

  Map<String, dynamic> get request => {
        'id': 123,
        'order_id': 'ORDER-42',
        'status': status,
        'can_cancel': canCancel,
      };

  @override
  Future<Response> getReturnOrders() async => response({
        'data': {
          'total': (includeRequest ? 1 : 0) + extraRequests.length,
          'returnOrders': [if (includeRequest) request, ...extraRequests],
        },
      });

  @override
  Future<Response> getReturnOrderDetails({required int orderId}) async {
    detailsCalls++;
    if (onDetails != null) return onDetails!(orderId);
    return response({
      'data': {'returnOrders': request},
    });
  }

  @override
  Future<Response> cancelReturnRequest({required int returnRequestId}) async {
    cancelledIds.add(returnRequestId);
    return onCancel == null
        ? cancelledResponse()
        : await onCancel!(returnRequestId);
  }

  @override
  Future<Response> submitReturnProduct({
    required ReturnOrderSubmitModel returnOrder,
  }) async {
    includeRequest = true;
    return response({'message': 'Return request submitted'});
  }
}
