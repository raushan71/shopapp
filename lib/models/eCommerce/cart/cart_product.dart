import 'package:ready_ecommerce/models/eCommerce/cart/gift.dart';

class CartItem {
  CartItem({
    required this.shopId,
    required this.shopName,
    required this.shopLogo,
    required this.shopRating,
    required this.cartProduct,
  });
  late final int shopId;
  late final String shopName;
  late final String shopLogo;
  late final String shopRating;
  late final bool hasGift;
  late final List<CartProduct> cartProduct;

  CartItem.fromJson(Map<String, dynamic> json) {
    shopId = _asInt(json['shop_id']);
    shopName = json['shop_name']?.toString() ?? '';
    shopLogo = json['shop_logo']?.toString() ?? '';
    shopRating = json['shop_rating'].toString();
    hasGift = json['has_gift'] ?? false;
    cartProduct = (json['products'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((product) => CartProduct.fromJson(product.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['shop_id'] = shopId;
    data['shop_name'] = shopName;
    data['shop_logo'] = shopLogo;
    data['shop_rating'] = shopRating;
    data['has_gift'] = hasGift;
    data['products'] = cartProduct.map((product) => product.toJson()).toList();
    return data;
  }
}

class CartProduct {
  CartProduct({
    required this.id,
    required this.quantity,
    required this.name,
    required this.thumbnail,
    required this.brand,
    required this.price,
    required this.discountPrice,
    required this.discountPercentage,
    required this.rating,
    required this.totalReviews,
    required this.totalSold,
    required this.color,
    required this.size,
    required this.unit,
    this.isDigital,
  });
  late final int id;
  late final int quantity;
  late final String name;
  late final String thumbnail;
  late final String? brand;
  late final double price;
  late final double discountPrice;
  late final double discountPercentage;
  late final double rating;
  late final String totalReviews;
  late final String totalSold;
  Color? color;
  Color? size;
  late final String? unit;
  late final Gift? gift;
  bool? isDigital;

  CartProduct.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    quantity = _asInt(json['quantity'], fallback: 1);
    name = json['name']?.toString() ?? '';
    thumbnail = json['thumbnail']?.toString() ?? '';
    brand = json['brand']?.toString();
    price = _asDouble(json['price']);
    discountPrice = _asDouble(json['discount_price']);
    discountPercentage = _asDouble(json['discount_percentage']);
    rating = _asDouble(json['rating']);
    totalReviews = json['total_reviews']?.toString() ?? '0';
    totalSold = json['total_sold']?.toString() ?? '0';
    color = json["color"] == null ? null : Color.fromJson(json["color"]);
    size = json["size"] == null ? null : Color.fromJson(json["size"]);
    unit = json['unit']?.toString();
    gift = json['gift'] != null ? Gift.fromMap(json['gift']) : null;
    isDigital = json['is_digital'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['quantity'] = quantity;
    data['name'] = name;
    data['thumbnail'] = thumbnail;
    data['brand'] = brand;
    data['price'] = price;
    data['discount_price'] = discountPrice;
    data['discount_percentage'] = discountPercentage;
    data['rating'] = rating;
    data['total_reviews'] = totalReviews;
    data['total_sold'] = totalSold;
    data['color'] = color?.toJson();
    data['size'] = size?.toJson();
    data['unit'] = unit;
    data['gift'] = gift?.toJson();
    data['is_digital'] = isDigital;
    return data;
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class Color {
  int? id;
  String? name;
  String? colorCode;
  double? price;

  Color({
    this.id,
    this.name,
    this.colorCode,
    this.price,
  });

  factory Color.fromJson(Map<String, dynamic> json) => Color(
        id: json["id"] == null ? null : _asInt(json["id"]),
        name: json["name"]?.toString(),
        colorCode: json["color_code"]?.toString(),
        price: json["price"] == null ? null : _asDouble(json["price"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "color_code": colorCode,
        "price": price,
      };
}
