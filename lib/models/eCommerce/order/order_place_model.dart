import 'dart:convert';

class OrderPlaceModel {
  final int? addressId;
  final String? couponId;
  final String? note;
  final String paymentMethod;
  final String fulfillmentType;
  List<int> shopIds;
  final int? isBuyNow;
  final double? latitude;
  final double? longitude;
  OrderPlaceModel({
    required this.addressId,
    required this.couponId,
    required this.note,
    required this.paymentMethod,
    required this.fulfillmentType,
    required this.shopIds,
    this.isBuyNow,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address_id': addressId,
      'coupon_code': couponId,
      'note': note,
      'payment_method': paymentMethod,
      'fulfillment_type': fulfillmentType,
      'shop_ids': shopIds,
      'is_buy_now': isBuyNow,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory OrderPlaceModel.fromMap(Map<String, dynamic> map) {
    return OrderPlaceModel(
      addressId: map['address_id'] != null ? map['address_id'] as int : null,
      couponId:
          map['coupon_code'] != null ? map['coupon_code'] as String : null,
      note: map['note'] != null ? map['note'] as String : null,
      paymentMethod: map['payment_method'] as String,
      fulfillmentType: map['fulfillment_type'] as String? ?? 'delivery',
      shopIds: List<int>.from(
        (map['shop_ids'] as List<int>),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderPlaceModel.fromJson(String source) =>
      OrderPlaceModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
