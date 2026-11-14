import 'package:flutter_test/flutter_test.dart';
import 'package:ready_ecommerce/models/eCommerce/address/add_address.dart';
import 'package:ready_ecommerce/models/eCommerce/address/areas_model.dart';
import 'package:ready_ecommerce/models/eCommerce/cart/cart_product.dart';
import 'package:ready_ecommerce/models/eCommerce/message_model/messages.dart';
import 'package:ready_ecommerce/models/eCommerce/order/order_place_model.dart';
import 'package:ready_ecommerce/models/eCommerce/product/product_details.dart';
import 'package:ready_ecommerce/models/common/master_model.dart';

void main() {
  test('delivery address payload keeps manual fields and pinned location', () {
    final address = AddAddress(
      name: 'Customer',
      phone: '9999999999',
      area: null,
      postCode: null,
      addressLine: null,
      addressLine2: 'Pinned GPS address',
      addressType: 'Home',
      latitude: 12.9716,
      longitude: 77.5946,
      isDefault: false,
    );

    final payload = address.toMap();

    expect(payload['area'], isNull);
    expect(payload['post_code'], isNull);
    expect(payload['address_line'], isNull);
    expect(payload['address_line2'], 'Pinned GPS address');
    expect(payload['latitude'], 12.9716);
    expect(payload['longitude'], 77.5946);
    expect(payload.containsKey('area_id'), isFalse);

    final parsed = AddAddress.fromMap({
      'id': 1,
      'name': 'Customer',
      'phone': '9999999999',
      'area': null,
      'flat_no': null,
      'post_code': null,
      'address_line': null,
      'address_line2': 'Pinned GPS address',
      'address_type': 'Home',
      'latitude': '12.9716',
      'longitude': '77.5946',
      'is_default': 0,
    });

    expect(parsed.addressLine, isNull);
    expect(parsed.addressLine2, 'Pinned GPS address');
    expect(parsed.latitude, 12.9716);
    expect(parsed.longitude, 77.5946);
  });

  test('areas parser accepts nested and direct API response shapes', () {
    final nested = parseAreasPayload({
      'data': {
        'areas': [
          {'id': '7', 'name': 'Central'}
        ]
      }
    });
    final direct = parseAreasPayload({
      'data': [
        {'id': 8, 'name': 'North'}
      ]
    });

    expect(nested.single.id, 7);
    expect(nested.single.name, 'Central');
    expect(direct.single.id, 8);
    expect(direct.single.name, 'North');
  });

  test('master settings parse the Google login business flag safely', () {
    final enabled = SocialAuths.fromJson({
      'google': {
        'name': 'Google',
        'client_id': 'client-id',
        'is_active': true,
        'redirect_url': 'postmessage',
      },
    });
    final disabled = SocialAuths.fromJson({
      'google': {'is_active': false},
    });
    final missing = SocialAuths.fromJson(const {});

    expect(enabled.google.isActive, isTrue);
    expect(enabled.google.clientId, 'client-id');
    expect(disabled.google.isActive, isFalse);
    expect(missing.google.isActive, isFalse);
  });

  test('product details parse variant media and available order options', () {
    final details = ProductDetails.fromMap({
      'product': {
        'id': 18,
        'name': 'Leggings Combo Pack 3',
        'short_description': 'Cotton leggings',
        'price': 499,
        'discount_price': 399,
        'discount_percentage': 20.04,
        'rating': 0,
        'total_reviews': '0',
        'total_sold': '3',
        'quantity': 987,
        'is_favorite': false,
        'thumbnails': [
          {
            'id': 77,
            'thumbnail': 'https://example.com/default.webp',
            'url': null,
            'type': 'image',
          },
        ],
        'sizes': <dynamic>[],
        'color_variation_name': 'More Color',
        'colors': [
          {
            'id': 2,
            'name': 'Black',
            'color_code': '#000000',
            'price': 40,
            'media': [
              {
                'id': 193,
                'thumbnail': 'https://example.com/black.webp',
                'url': null,
                'type': 'image',
              },
            ],
            'swatch_image': 'https://example.com/black.webp',
          },
        ],
        'brand': '   ',
        'description': '<p>Description</p>',
        'order_options': {
          'doorstep_delivery': true,
          'store_pickup': true,
          'cash_on_delivery': true,
          'online_payment': true,
          'show_order_note': false,
        },
        'shop': {
          'id': 2,
          'name': 'Shop2',
          'logo': 'https://example.com/logo.webp',
          'estimated_delivery_time': '5',
          'delivery_charge': 0,
        },
        'flash_sale': null,
      },
      'related_products': <dynamic>[],
    });

    expect(details.product.brand, isEmpty);
    expect(details.product.colorVariationName, 'More Color');
    expect(details.product.colors.single.media.single.id, 193);
    expect(details.product.colors.single.swatchImage,
        'https://example.com/black.webp');
    expect(details.product.orderOptions.doorstepDelivery, isTrue);
    expect(details.product.orderOptions.storePickup, isTrue);
    expect(details.product.orderOptions.cashOnDelivery, isTrue);
    expect(details.product.orderOptions.onlinePayment, isTrue);
  });

  test('order payload includes pickup fulfillment without an address', () {
    final order = OrderPlaceModel(
      addressId: null,
      couponId: null,
      note: null,
      paymentMethod: 'cash',
      fulfillmentType: 'pickup',
      shopIds: [2],
    );

    expect(order.toMap()['fulfillment_type'], 'pickup');
    expect(order.toMap()['address_id'], isNull);
  });

  test('cart parses mixed numeric API values and preserves variants', () {
    final cart = CartItem.fromJson({
      'shop_id': '2',
      'shop_name': 'Shop',
      'shop_logo': '',
      'shop_rating': 4,
      'products': [
        {
          'id': 18,
          'quantity': '3',
          'name': 'Leggings',
          'thumbnail': '',
          'brand': null,
          'price': 499,
          'discount_price': '399.5',
          'discount_percentage': 20,
          'rating': 4,
          'total_reviews': 2,
          'total_sold': 8,
          'color': {'id': 1, 'name': 'Black', 'price': 10},
          'size': {'id': 4, 'name': 'Large', 'price': '15'},
          'unit': null,
          'gift': null,
          'is_digital': false,
        },
      ],
    });

    expect(cart.shopId, 2);
    expect(cart.cartProduct.single.quantity, 3);
    expect(cart.cartProduct.single.price, 499.0);
    expect(cart.cartProduct.single.discountPrice, 399.5);
    expect(cart.cartProduct.single.totalReviews, '2');
    expect(cart.cartProduct.single.toJson()['color']['id'], 1);
    expect(cart.cartProduct.single.toJson()['size']['id'], 4);
  });

  test('chat message parses boolean and numeric seen status', () {
    expect(Messages.fromMap({'is_seen': true}).isSeen, 1);
    expect(Messages.fromMap({'is_seen': false}).isSeen, 0);
    expect(Messages.fromMap({'is_seen': 1}).isSeen, 1);
    expect(Messages.fromMap({'is_seen': '0'}).isSeen, 0);
  });
}
