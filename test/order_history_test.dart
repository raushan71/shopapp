import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itrsp_shop/controllers/eCommerce/order/order_controller.dart';
import 'package:itrsp_shop/models/eCommerce/order/order_model.dart';
import 'package:itrsp_shop/services/eCommerce/order/order_service.dart';

Map<String, dynamic> orderPayload({
  Object id = 1,
  Object quantity = 2,
  Object amount = 499.5,
  Object? address = const {
    'id': 7,
    'name': 'Customer',
    'phone': '9999999999',
    'address_type': 'Home',
    'address_line': null,
    'address_line2': 'Pinned GPS address',
    'is_default': 0,
  },
}) =>
    {
      'id': id,
      'order_code': 'ORDER-$id',
      'quantity': quantity,
      'amount': amount,
      'order_status': 'Pending',
      'created_at': '2026-11-16T10:00:00Z',
      'address': address,
    };

void main() {
  test('history accepts addresses saved using only the GPS address line', () {
    final order = OrderModel.fromJson(orderPayload());

    expect(order.address!.addressLine, isEmpty);
    expect(order.address!.addressLine2, 'Pinned GPS address');
  });

  test('history accepts numeric strings and integer amounts', () {
    final stringValues = OrderModel.fromJson(
      orderPayload(id: '12', quantity: '3', amount: '499.50'),
    );
    final integerAmount = OrderModel.fromJson(orderPayload(amount: 499));

    expect(stringValues.id, 12);
    expect(stringValues.quantity, 3);
    expect(stringValues.amount, 499.5);
    expect(integerAmount.amount, 499.0);
  });

  test('pickup and digital orders can have no delivery address', () {
    final order = OrderModel.fromJson(orderPayload(address: null));

    expect(order.address, isNull);
    expect(order.toJson()['address'], isNull);
  });

  test('one GPS or pickup order does not prevent loading the history',
      () async {
    final container = ProviderContainer(overrides: [
      orderServiceProvider.overrideWith((ref) => StubOrderService(ref)),
    ]);
    addTearDown(container.dispose);
    final service = container.read(orderServiceProvider) as StubOrderService;
    service.responseData = {
      'data': {
        'total': '2',
        'orders': [orderPayload(), orderPayload(id: 2, address: null)],
      },
    };

    await container.read(orderControllerProvider.notifier).getOrders(
          orderStatus: null,
          page: 1,
          perPage: 20,
          isPagination: false,
        );

    expect(container.read(orderControllerProvider), isFalse);
    expect(
        container.read(orderControllerProvider.notifier).orders, hasLength(2));
    expect(container.read(orderControllerProvider.notifier).totalOrder, 2);
  });

  test('failed history requests show an error that clears after retry',
      () async {
    final container = orderContainer();
    addTearDown(container.dispose);
    final service = container.read(orderServiceProvider) as StubOrderService;
    final controller = container.read(orderControllerProvider.notifier);
    service.onGetOrders = (_, __) => Future.error(StateError('Offline'));

    expect(await loadOrders(controller), isFalse);
    expect(container.read(orderControllerProvider), isFalse);
    expect(controller.ordersError, isNotNull);

    service.onGetOrders = null;
    service.responseData = {
      'data': {
        'total': 1,
        'orders': [orderPayload()]
      },
    };
    expect(await loadOrders(controller), isTrue);
    expect(controller.ordersError, isNull);
    expect(controller.orders, hasLength(1));
  });

  test('failed pagination preserves orders and allows retrying the same page',
      () async {
    final container = orderContainer();
    addTearDown(container.dispose);
    final service = container.read(orderServiceProvider) as StubOrderService;
    final controller = container.read(orderControllerProvider.notifier);
    service.responseData = {
      'data': {
        'total': 2,
        'orders': [orderPayload()]
      },
    };
    await loadOrders(controller);
    service.onGetOrders = (_, __) => Future.error(StateError('Offline'));
    expect(await loadOrders(controller, page: 2), isFalse);
    expect(controller.orders.map((order) => order.id), [1]);
    expect(controller.totalOrder, 2);

    service.onGetOrders = null;
    service.responseData = {
      'data': {
        'total': 2,
        'orders': [orderPayload(id: 2)]
      },
    };
    expect(await loadOrders(controller, page: 2), isTrue);
    expect(controller.orders.map((order) => order.id), [1, 2]);
    expect(controller.ordersError, isNull);
  });

  test('an older response cannot replace the newly selected order filter',
      () async {
    final container = orderContainer();
    addTearDown(container.dispose);
    final service = container.read(orderServiceProvider) as StubOrderService;
    final controller = container.read(orderControllerProvider.notifier);
    final oldResponse = Completer<Response>();
    service.onGetOrders = (status, _) =>
        status == null ? oldResponse.future : Future.value(orderResponse(2));

    final oldRequest = loadOrders(controller);
    await loadOrders(controller, status: 'Pending');
    oldResponse.complete(orderResponse(1));
    await oldRequest;

    expect(controller.orders.map((order) => order.id), [2]);
    expect(container.read(orderControllerProvider), isFalse);
  });
}

ProviderContainer orderContainer() => ProviderContainer(overrides: [
      orderServiceProvider.overrideWith((ref) => StubOrderService(ref)),
    ]);

Future<bool> loadOrders(OrderController controller,
        {String? status, int page = 1}) =>
    controller.getOrders(
      orderStatus: status,
      page: page,
      perPage: 20,
      isPagination: page > 1,
    );

Response orderResponse(int id) => Response(
      requestOptions: RequestOptions(path: '/orders'),
      statusCode: 200,
      data: {
        'data': {
          'total': 1,
          'orders': [orderPayload(id: id)]
        },
      },
    );

class StubOrderService extends OrderService {
  StubOrderService(super.ref);

  dynamic responseData;
  Future<Response> Function(String? status, int page)? onGetOrders;

  @override
  Future<Response> getOrders({
    required String? orderStatus,
    required int page,
    required int perPage,
  }) async {
    final handler = onGetOrders;
    if (handler != null) return handler(orderStatus, page);
    return Response(
      requestOptions: RequestOptions(path: '/orders'),
      statusCode: 200,
      data: responseData,
    );
  }
}
