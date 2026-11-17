import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/controllers/misc/misc_controller.dart';
import 'package:itrsp_shop/models/eCommerce/cart/add_to_cart_model.dart';
import 'package:itrsp_shop/models/eCommerce/cart/cart_product.dart';
import 'package:itrsp_shop/models/eCommerce/cart/gift_add_model.dart';
import 'package:itrsp_shop/models/eCommerce/cart/gift_item.dart';
import 'package:itrsp_shop/services/eCommerce/cart_service/cart_service.dart';
import 'package:itrsp_shop/utils/global_function.dart';

class CartController extends StateNotifier<CartState> {
  final Ref ref;
  CartController(this.ref) : super(CartState(isLoading: false, cartItems: []));

  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  List<ShopGift> _giftItems = [];
  List<ShopGift> get giftItems => _giftItems;

  Future<bool> addToCart({
    required AddToCartModel addToCartModel,
  }) async {
    state = CartState(isLoading: true, cartItems: cartItems);
    try {
      debugPrint(
        'CartController.addToCart -> payload: ${addToCartModel.toMap()}',
      );
      final response = await ref
          .read(cartServiceProvider)
          .addToCart(addToCartModel: addToCartModel);
      debugPrint(
        'CartController.addToCart <- status: ${response.statusCode}, data: ${response.data}',
      );

      if (_isSuccessStatus(response.statusCode)) {
        final dynamic cartItemsData = response.data['data']?['cart_items'];
        if (cartItemsData is List) {
          _cartItems = _parseCartItems(cartItemsData);
        } else {
          debugPrint(
            'CartController.addToCart: cart_items missing from response, refreshing cart state.',
          );
          await getAllCarts();
        }
        state = CartState(isLoading: false, cartItems: cartItems);
        ref.read(shopIdsProvider.notifier).addAllShopIds();
        GlobalFunction.showCustomSnackbar(
          message: response.data['message'] ?? 'Cart updated successfully',
          isSuccess: true,
        );
        return true;
      }

      debugPrint(
        'CartController.addToCart failed: status=${response.statusCode}, message=${response.data['message']}',
      );
      GlobalFunction.showCustomSnackbar(
        message: response.data['message'] ?? 'Failed to update cart',
        isSuccess: false,
      );

      state = CartState(isLoading: false, cartItems: cartItems);
      return false;
    } catch (error) {
      state = CartState(isLoading: false, cartItems: cartItems);
      debugPrint("CartController.addToCart error: ${error.toString()}");
      GlobalFunction.showCustomSnackbar(
        message: 'Unable to update cart. Please try again.',
        isSuccess: false,
      );
      return false;
    }
  }

  Future<bool> increment({required int productId}) async {
    try {
      state = CartState(isLoading: true, cartItems: cartItems);
      final response =
          await ref.read(cartServiceProvider).increentQty(productId: productId);
      if (_isSuccessStatus(response.statusCode)) {
        final dynamic data = response.data['data']?['cart_items'];
        if (data is List) {
          _cartItems = _parseCartItems(data);
        } else {
          await getAllCarts();
        }
        state = CartState(isLoading: false, cartItems: cartItems);
        return true;
      }
      // GlobalFunction.showCustomSnackbar(
      //   message: response.data['message'],
      //   isSuccess: response.statusCode == 200 ? true : false,
      // );
      state = CartState(isLoading: false, cartItems: cartItems);
      GlobalFunction.showCustomSnackbar(
        message: response.data['message'] ?? 'Unable to update quantity',
        isSuccess: false,
      );
      return false;
    } catch (error) {
      state = CartState(isLoading: false, cartItems: cartItems);
      debugPrint(error.toString());
      GlobalFunction.showCustomSnackbar(
        message: 'Unable to update quantity. Please try again.',
        isSuccess: false,
      );
      return false;
    }
  }

  Future<bool> decrement({required int productId}) async {
    try {
      state = CartState(isLoading: true, cartItems: cartItems);
      final response = await ref
          .read(cartServiceProvider)
          .decrementQty(productId: productId);
      if (_isSuccessStatus(response.statusCode)) {
        final dynamic data = response.data['data']?['cart_items'];
        if (data is List) {
          _cartItems = _parseCartItems(data);
        } else {
          await getAllCarts();
        }
        state = CartState(isLoading: false, cartItems: cartItems);
        return true;
      }
      // GlobalFunction.showCustomSnackbar(
      //   message: response.data['message'],
      //   isSuccess: response.statusCode == 200 ? true : false,
      // );
      state = CartState(isLoading: false, cartItems: cartItems);
      GlobalFunction.showCustomSnackbar(
        message: response.data['message'] ?? 'Unable to update quantity',
        isSuccess: false,
      );
      return false;
    } catch (error) {
      state = CartState(isLoading: false, cartItems: cartItems);
      debugPrint(error.toString());
      GlobalFunction.showCustomSnackbar(
        message: 'Unable to update quantity. Please try again.',
        isSuccess: false,
      );
      return false;
    }
  }

  Future<void> getAllCarts() async {
    try {
      final response = await ref.read(cartServiceProvider).getAllCarts();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['cart_items'];
        _cartItems = _parseCartItems(data);
        state = CartState(isLoading: false, cartItems: cartItems);
        ref.read(shopIdsProvider.notifier).retainAvailableShopIds();
      }
      state = CartState(isLoading: false, cartItems: cartItems);
    } catch (error) {
      state = CartState(isLoading: false, cartItems: cartItems);

      debugPrint(error.toString());
      rethrow;
    }
  }

  Future<void> getAllGifts({required int shopId}) async {
    state = CartState(isLoading: true, cartItems: cartItems);
    try {
      final response = await ref.read(cartServiceProvider).getAllGifts(
            shopId: shopId,
          );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['gifts'];
        _giftItems =
            data.map((giftItem) => ShopGift.fromMap(giftItem)).toList();
      }

      state = CartState(isLoading: false, cartItems: cartItems);
    } catch (error) {
      debugPrint(error.toString());
    } finally {
      state = CartState(isLoading: false, cartItems: cartItems);
    }
  }

  Future<void> addGiftToCart({required GiftAddModel giftAddModel}) async {
    state = CartState(isLoading: true, cartItems: cartItems);
    try {
      final response = await ref
          .read(cartServiceProvider)
          .addGiftToCart(giftAddModel: giftAddModel);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['cart_items'];
        _cartItems =
            data.map((cartItem) => CartItem.fromJson(cartItem)).toList();
      }

      state = CartState(isLoading: false, cartItems: cartItems);
    } catch (error, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint(error.toString());
    } finally {
      state = CartState(isLoading: false, cartItems: cartItems);
    }
  }

  Future<void> deleteGiftFromCart({required int giftId}) async {
    state = CartState(isLoading: true, cartItems: cartItems);
    try {
      final response = await ref
          .read(cartServiceProvider)
          .deleteGiftFromCart(giftId: giftId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['cart_items'];
        _cartItems =
            data.map((cartItem) => CartItem.fromJson(cartItem)).toList();
      }

      state = CartState(isLoading: false, cartItems: cartItems);
    } catch (error) {
      debugPrint(error.toString());
    } finally {
      state = CartState(isLoading: false, cartItems: cartItems);
    }
  }

  List<CartItem> _parseCartItems(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((item) => CartItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}

bool _isSuccessStatus(int? statusCode) =>
    statusCode == 200 || statusCode == 201;

final cartController = StateNotifierProvider<CartController, CartState>(
    (ref) => CartController(ref));

class CartSummeryController extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  CartSummeryController(this.ref)
      : super({
          "totalAmount": 0.0,
          "payableAmount": 0.0,
          "discount": 0.0,
          "deliveryCharge": 0.0,
          "applyCoupon": false,
          "giftCharge": 0.0,
          "orderTaxAmount": 0.0,
          "allVatTaxes": [],
          "availableOrderOptions": <String, dynamic>{}
        });

  Future<void> calculateCartSummery({
    required String? couponCode,
    required List<int> shopIds,
    bool showSnackbar = false,
    bool? isBuyNow,
    String fulfillmentType = 'delivery',
    dynamic addressId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await ref.read(cartServiceProvider).cartSummery(
            couponId: couponCode,
            shopIds: shopIds,
            isBuyNow: isBuyNow,
            fulfillmentType: fulfillmentType,
            addressId: addressId,
            latitude: latitude,
            longitude: longitude,
          );
      if (response.statusCode == 200) {
        final checkout =
            response.data['data']['checkout'] as Map<String, dynamic>;
        state = {
          'totalAmount': checkout['total_amount'],
          'payableAmount': checkout['payable_amount'],
          'discount': checkout['coupon_discount'],
          'deliveryCharge': checkout['delivery_charge'],
          'applyCoupon': response.data['data']['apply_coupon'],
          'giftCharge': checkout['gift_charge'] ?? 0.0,
          'orderTaxAmount': checkout['order_tax_amount'] ?? 0.0,
          'allVatTaxes': checkout['all_vat_taxes'] ?? const [],
          'availableOrderOptions':
              checkout['available_options'] as Map<String, dynamic>? ??
                  const <String, dynamic>{},
        };
      }
      if (showSnackbar) {
        GlobalFunction.showCustomSnackbar(
          message: response.data['message'],
          isSuccess: response.data['data']['apply_coupon'],
        );
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}

final cartSummeryController =
    StateNotifierProvider<CartSummeryController, Map<String, dynamic>>(
        (ref) => CartSummeryController(ref));

class BuyNowSummeryController extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;
  BuyNowSummeryController(this.ref)
      : super({
          "totalAmount": 0.0,
          "payableAmount": 0.0,
          "discount": 0.0,
          "deliveryCharge": 0.0,
          "applyCoupon": false,
          "giftCharge": 0.0,
          'orderTaxAmount': 0.0
        });

  Future<void> calculateCartSummery({
    required String? couponCode,
    required int productId,
    required int quantity,
    bool showSnackbar = false,
  }) async {
    try {
      final response = await ref.read(cartServiceProvider).buyNow(
            couponCode: couponCode,
            productId: productId,
            quantity: quantity,
          );
      if (response.statusCode == 200) {
        state = {
          'totalAmount': response.data['data']['total_amount'],
          'payableAmount': response.data['data']['total_payable_amount'],
          'discount': response.data['data']['coupon_discount'],
          'deliveryCharge': response.data['data']['delivery_charge'],
          'applyCoupon': response.data['data']['apply_coupon'],
          'giftCharge': response.data['data']['gift_charge'],
          'orderTaxAmount': response.data['data']['order_tax_amount'],
        };
      }
      if (showSnackbar) {
        GlobalFunction.showCustomSnackbar(
          message: response.data['message'],
          isSuccess: response.data['data']['apply_coupon'],
        );
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }
}

final buyNowSummeryController =
    StateNotifierProvider<BuyNowSummeryController, Map<String, dynamic>>(
        (ref) => BuyNowSummeryController(ref));

class CartState {
  final bool isLoading;
  final List<CartItem> cartItems;
  CartState({
    required this.isLoading,
    required this.cartItems,
  });
}
