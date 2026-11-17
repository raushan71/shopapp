import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/config/app_constants.dart';
import 'package:itrsp_shop/models/eCommerce/address/areas_model.dart';
import 'package:itrsp_shop/utils/api_client.dart';

class AreasControllerNotifier
    extends StateNotifier<AsyncValue<List<AreasModel>>> {
  final Ref ref;

  AreasControllerNotifier(this.ref) : super(const AsyncLoading()) {
    getAreasList();
  }

  Future<void> getAreasList() async {
    state = const AsyncLoading();
    try {
      final response =
          await ref.read(apiClientProvider).get(AppConstants.areasListUrl);

      if (response.statusCode == 200) {
        final areasList = parseAreasPayload(response.data);

        state = AsyncData(areasList);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (error, stackTrace) {
      log("areas_api error: $error");
      log("areas_api stackTrace: $stackTrace");

      state = AsyncError(error, stackTrace);
    }
  }
}

final areasProvider = StateNotifierProvider<AreasControllerNotifier,
    AsyncValue<List<AreasModel>>>((ref) {
  return AreasControllerNotifier(ref);
});
