import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/controllers/eCommerce/order/order_controller.dart';
import 'package:itrsp_shop/models/eCommerce/order/order_details_model.dart';
import 'package:itrsp_shop/services/eCommerce/order/order_service.dart';
import 'package:itrsp_shop/views/eCommerce/order_details/layouts/order_details_layout.dart';

Map<String, dynamic> detailsPayload({
  Object? address,
  Object? shop,
  Object? rider,
}) => {
  'message': 'Order details',
  'data': {
    'order': {
      'id': 42,
      'order_code': 'ORDER-42',
      'order_status': 'Pending',
      'created_at': '2026-11-18T10:00:00Z',
      'payment_method': 'Cash on Delivery',
      'payment_status': 'Pending',
      'tax_amount': 0,
      'total_amount': 499,
      'discount': 0,
      'coupon_discount': 0,
      'payable_amount': 499,
      'quantity': 1,
      'delivery_charge': 0,
      'shop': shop,
      'address': address,
      'rider': rider,
      'products': [
        {
          'id': 7,
          'name': 'Product',
          'thumbnail': '',
          'price': 499,
          'order_qty': 1,
          'discount_price': null,
          'rating': null,
          'licenses': null,
          'attachments': null,
        },
      ],
    },
  },
};

Map<String, dynamic> addressPayload() => {
  'id': 7,
  'name': 'Customer',
  'phone': '9999999999',
  'address_type': 'Home',
  'address_line': null,
  'address_line2': 'GPS address',
  'latitude': '25.6',
  'longitude': 85.1,
  'is_default': 1,
};

Map<String, dynamic> shopPayload() => {
  'id': 2,
  'name': 'Shop',
  'logo': '',
  'banner': null,
  'rating': 4,
  'total_products': '3',
  'total_categories': 1,
  'total_reviews': 5,
};

void main() {
  test('pickup and digital order details accept a null delivery address', () {
    for (final fulfillment in ['pickup', 'digital']) {
      final payload = detailsPayload(shop: shopPayload());
      payload['data']['order']['fulfillment_type'] = fulfillment;
      final order = OrderDetails.fromJson(payload).data.order;
      expect(order.address, isNull);
      expect(order.shop?.id, 2);
      expect(order.products.single.name, 'Product');
      expect(order.payableAmount, 499);
      expect(order.toJson()['address'], isNull);
    }
  });

  test(
    'missing optional shop, rider and product metadata do not prevent parsing',
    () {
      final order = OrderDetails.fromJson(detailsPayload()).data.order;
      expect(order.shop, isNull);
      expect(order.rider, isNull);
      expect(order.products.single.licenses, isNull);
      expect(order.products.single.attachments, isEmpty);
      expect(order.products.single.discountPrice, 0);
    },
  );

  test('GPS delivery address retains coordinates and second address line', () {
    final order = OrderDetails.fromJson(
      detailsPayload(address: addressPayload()),
    ).data.order;
    expect(order.address?.addressLine, isNull);
    expect(order.address?.addressLine2, 'GPS address');
    expect(order.address?.latitude, 25.6);
    expect(order.address?.longitude, 85.1);
    expect(order.address?.isDefault, isTrue);
  });

  test(
    'empty optional relations and rider lists containing null are accepted',
    () {
      for (final rider in [
        null,
        [],
        [null],
        [null, {}],
        {},
      ]) {
        final order = OrderDetails.fromJson(
          detailsPayload(address: {}, shop: [], rider: rider),
        ).data.order;
        expect(order.rider, isNull);
        expect(order.address, isNull);
        expect(order.shop, isNull);
      }
    },
  );

  test('rider maps and lists preserve identity and numeric coordinates', () {
    final assigned = {
      'id': '9',
      'name': 'Rider',
      'latitude': 25.1,
      'longitude': null,
    };
    for (final rider in [
      assigned,
      [null, assigned],
    ]) {
      final order = OrderDetails.fromJson(
        detailsPayload(rider: rider),
      ).data.order;
      expect(order.rider?.id, 9);
      expect(order.rider?.latitude, '25.1');
      expect(order.rider?.longitude, isEmpty);
    }
  });

  test('order and item amounts accept integer and string JSON values', () {
    final payload = detailsPayload();
    final json = payload['data']['order'];
    json['id'] = '42';
    json['quantity'] = '2';
    json['total_amount'] = '499.50';
    json['payable_amount'] = 450;
    json['tax_amount'] = null;
    json['delivery_charge'] = null;
    json['products'][0]['price'] = '499.50';
    json['products'][0]['order_qty'] = '2';
    final order = OrderDetails.fromJson(payload).data.order;
    expect(order.id, 42);
    expect(order.quantity, 2);
    expect(order.totalAmount, 499.5);
    expect(order.payableAmount, 450.0);
    expect(order.taxAmount, 0);
    expect(order.deliveryCharge, 0);
    expect(order.products.single.price, 499.5);
    expect(order.products.single.orderQty, 2);
  });

  test('missing required order data and invalid totals are not fabricated', () {
    for (final payload in [
      <String, dynamic>{},
      {'data': null},
      {
        'data': {'order': null},
      },
    ]) {
      expect(() => OrderDetails.fromJson(payload), throwsFormatException);
    }
    for (final badTotal in [null, 'unknown', 'NaN']) {
      final payload = detailsPayload();
      payload['data']['order']['payable_amount'] = badTotal;
      expect(() => OrderDetails.fromJson(payload), throwsFormatException);
    }
  });

  test('details serialize as JSON and round trip with optional relations', () {
    for (final address in [null, addressPayload()]) {
      final first = OrderDetails.fromJson(
        detailsPayload(address: address, shop: shopPayload()),
      );
      final serialized = first.toJson();
      expect(serialized['data'], isA<Map>());
      final second = OrderDetails.fromJson(jsonDecode(jsonEncode(serialized)));
      expect(second.data.order.payableAmount, first.data.order.payableAmount);
      expect(
        second.data.order.address?.addressLine2,
        first.data.order.address?.addressLine2,
      );
      expect(second.data.order.shop?.id, 2);
    }
  });

  test('details controller reaches data for a pickup order', () async {
    final container = ProviderContainer(
      overrides: [
        orderServiceProvider.overrideWith((ref) => DetailsService(ref)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      orderDetailsControllerProvider(42),
      (_, __) {},
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(orderDetailsControllerProvider(42)).hasError,
      isFalse,
    );
    expect(
      container
          .read(orderDetailsControllerProvider(42))
          .value
          ?.data
          .order
          .address,
      isNull,
    );
    expect(
      container.read(orderDetailsControllerProvider(42)).value?.data.order.id,
      42,
    );
  });

  testWidgets(
    'missing order data shows a friendly retry and reloads the request',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          orderServiceProvider.overrideWith((ref) => DetailsService(ref)),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(orderServiceProvider) as DetailsService;
      service.payload = {
        'message': 'Order unavailable',
        'data': {'order': null},
      };
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
              home: const OrderDetailsLayout(orderId: 42),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(service.calls, 1);
      expect(
        find.text('Unable to load order details. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining("type 'Null'"), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(service.calls, 2);
      expect(
        find.text('Unable to load order details. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class DetailsService extends OrderService {
  DetailsService(super.ref);
  Object payload = detailsPayload();
  int calls = 0;
  @override
  Future<Response> getOrderDetails({required int orderId}) async {
    calls++;
    return Response(
      requestOptions: RequestOptions(path: '/order-details'),
      statusCode: 200,
      data: payload,
    );
  }
}
