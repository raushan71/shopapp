import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/controllers/eCommerce/order/order_controller.dart';
import 'package:itrsp_shop/models/eCommerce/common/common_response.dart';
import 'package:itrsp_shop/models/eCommerce/order/order_details_model.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_details_model/return_order_details_model.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_list_model/return_order.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_list_model/return_order_list_model.dart';
import 'package:itrsp_shop/models/eCommerce/return_policy/return_order_submit_model.dart';
import 'package:itrsp_shop/services/eCommerce/return_product/return_product_service.dart';
import 'package:itrsp_shop/utils/request_handler.dart';

final selectedReturnProductProvider =
    StateNotifierProvider<SelectedReturnProduct, List<Products>>(
        (ref) => SelectedReturnProduct());

final returnSubmitControllerProvider =
    StateNotifierProvider<ReturnProductSubmitController, bool>(
        (ref) => ReturnProductSubmitController(ref));

final returnOrderListProvider = StateNotifierProvider<ReturnOrderListController,
    AsyncValue<ReturnOrderListModel>>(
  (ref) => ReturnOrderListController(ref),
);

final orderReturnRequestsProvider = FutureProvider.autoDispose
    .family<List<ReturnOrder>, ({int orderId, String orderCode})>(
        (ref, order) async {
  final response =
      await ref.read(returnProductServiceProvider).getReturnOrders();
  if (response.statusCode != 200) {
    throw StateError('Unable to load return requests');
  }
  final requests = ReturnOrderListModel.fromMap(response.data);
  return (requests.data?.returnOrders ?? []).where((request) {
    final originalOrder = request.orderId;
    return originalOrder == order.orderId.toString() ||
        (order.orderCode.isNotEmpty && originalOrder == order.orderCode);
  }).toList();
});

final returnCancellationControllerProvider =
    StateNotifierProvider<ReturnCancellationController, Set<int>>(
  (ref) => ReturnCancellationController(ref),
);

final returnOrderDetailsControllerProvider = StateNotifierProvider.family
    .autoDispose<ReturnOrderDetailsController,
        AsyncValue<ReturnOrderDetailsModel>, int>((ref, shopId) {
  final controller = ReturnOrderDetailsController(ref);
  controller.getReturnOrderDetails(orderId: shopId);
  return controller;
});

class SelectedReturnProduct extends StateNotifier<List<Products>> {
  SelectedReturnProduct() : super([]);

  void toggleProductSelection(Products product) {
    if (state.contains(product)) {
      state = state.where((item) => item != product).toList();
    } else {
      state = [...state, product];
    }
  }

  void clearSelection() {
    state = [];
  }
}

class ReturnCancellationController extends StateNotifier<Set<int>> {
  final Ref ref;

  ReturnCancellationController(this.ref) : super({});

  Future<CommonResponse> cancelReturnRequest({
    required int returnRequestId,
  }) async {
    if (state.contains(returnRequestId)) {
      return CommonResponse(isSuccess: false, message: '');
    }
    state = {...state, returnRequestId};
    try {
      final response = await ref
          .read(returnProductServiceProvider)
          .cancelReturnRequest(returnRequestId: returnRequestId);
      final data = response.data;
      final message = data is Map ? data['message'] : null;
      if (!mounted) {
        return CommonResponse(
          isSuccess: response.statusCode == 200,
          message: message is String ? message : '',
        );
      }
      if (response.statusCode != 200) {
        if (response.statusCode == 404 || response.statusCode == 422) {
          _refreshReturnRequests();
        }
        return CommonResponse(
          isSuccess: false,
          message: message is String ? message : '',
        );
      }

      ref.read(selectedReturnProductProvider.notifier).clearSelection();
      ref.invalidate(orderDetailsControllerProvider);
      _refreshReturnRequests();
      return CommonResponse(
        isSuccess: true,
        message: message is String ? message : '',
      );
    } catch (error) {
      final data = error is DioException ? error.response?.data : null;
      final message = data is Map ? data['message'] : null;
      if (mounted &&
          error is DioException &&
          (error.response?.statusCode == 404 ||
              error.response?.statusCode == 422)) {
        _refreshReturnRequests();
      }
      return CommonResponse(
        isSuccess: false,
        message: message is String ? message : '',
      );
    } finally {
      if (mounted) {
        state = {...state}..remove(returnRequestId);
      }
    }
  }

  void _refreshReturnRequests() {
    ref.invalidate(orderReturnRequestsProvider);
    ref.invalidate(returnOrderDetailsControllerProvider);
    unawaited(ref.read(returnOrderListProvider.notifier).fetchReturnOrders());
  }
}

class ReturnProductSubmitController extends StateNotifier<bool> {
  final Ref ref;
  ReturnProductSubmitController(this.ref) : super(false);

  Future<CommonResponse> submitReturnProduct(
      {required ReturnOrderSubmitModel returnOrder}) async {
    state = true;
    final response = await ref
        .read(returnProductServiceProvider)
        .submitReturnProduct(returnOrder: returnOrder);
    final String message = response.data['message'];
    if (response.statusCode == 200) {
      state = false;
      ref.invalidate(orderReturnRequestsProvider);
      unawaited(ref.read(returnOrderListProvider.notifier).fetchReturnOrders());
      return CommonResponse(isSuccess: true, message: message);
    }
    state = false;
    return CommonResponse(isSuccess: false, message: message);
  }
}

class ReturnOrderListController
    extends StateNotifier<AsyncValue<ReturnOrderListModel>> {
  final Ref ref;

  ReturnOrderListController(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchReturnOrders() async {
    try {
      state = const AsyncValue.loading();

      final response =
          await ref.read(returnProductServiceProvider).getReturnOrders();
      if (!mounted) return;
      final model = ReturnOrderListModel.fromMap(response.data);

      state = AsyncValue.data(model);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint("Error fetching return orders: $e");
      debugPrint("Error fetching return orders: $st");

      state = AsyncValue.error(e, st);
    }
  }
}

class ReturnOrderDetailsController
    extends StateNotifier<AsyncValue<ReturnOrderDetailsModel>> {
  final Ref ref;

  ReturnOrderDetailsController(
    this.ref,
  ) : super(const AsyncValue.loading());

  Future<void> getReturnOrderDetails({required int orderId}) async {
    try {
      final response = await ref
          .read(returnProductServiceProvider)
          .getReturnOrderDetails(orderId: orderId);
      if (!mounted) return;
      state = AsyncData(ReturnOrderDetailsModel.fromMap(response.data));
    } catch (error, stackTrace) {
      if (!mounted) return;
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
      state = AsyncError(
          error is DioException ? ApiInterceptors.handleError(error) : error,
          stackTrace);
    }
  }
}
