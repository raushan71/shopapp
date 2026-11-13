import 'package:flutter_test/flutter_test.dart';
import 'package:ready_ecommerce/models/eCommerce/order/order_place_model.dart';
import 'package:ready_ecommerce/models/eCommerce/product/product_details.dart';

void main() {
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
}
