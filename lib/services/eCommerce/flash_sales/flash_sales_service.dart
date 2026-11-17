import 'dart:developer';

import 'package:dio/src/response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/config/app_constants.dart';
import 'package:itrsp_shop/services/base/eCommerce/flash_sales_provider_base.dart';
import 'package:itrsp_shop/utils/api_client.dart';

final flashSalesServiceProvider = Provider((ref) => FlashSalesService(ref));

class FlashSalesService extends FlashSalesProviderBase {
  final Ref ref;
  FlashSalesService(this.ref);

  @override
  Future<Response> getFlashSalesDetail({required int id}) async {
    final response = await ref
        .read(apiClientProvider)
        .get("${AppConstants.flashSaleDetails}/$id/details");
    return response;
  }

  @override
  Future<Response> getFlashSalesList() async {
    final response =
        await ref.read(apiClientProvider).get(AppConstants.flashSales);
    log("responseall ${response.data["data"]}");
    return response;
  }
}
