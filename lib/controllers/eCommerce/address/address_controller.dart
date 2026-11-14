import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ready_ecommerce/models/eCommerce/address/add_address.dart';
import 'package:ready_ecommerce/models/eCommerce/common/common_response.dart';
import 'package:ready_ecommerce/controllers/misc/misc_controller.dart';
import 'package:ready_ecommerce/services/common/hive_service_provider.dart';
import 'package:ready_ecommerce/services/eCommerce/address_service/address_service.dart';

final addressControllerProvider =
    StateNotifierProvider<AddressController, bool>(
        (ref) => AddressController(ref));

class AddressController extends StateNotifier<bool> {
  final Ref ref;
  AddressController(this.ref) : super(false);

  List<AddAddress> _addressList = [];
  List<AddAddress> get addressList => _addressList;

  Future<CommonResponse> addAddress({required AddAddress addAddress}) async {
    try {
      state = true;
      final response = await ref
          .read(addressServiceProvider)
          .addAddress(addAddress: addAddress);
      state = false;
      return CommonResponse(isSuccess: true, message: response.data['message']);
    } catch (error) {
      debugPrint(error.toString());
      state = false;
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> updateAddress({required AddAddress addAddress}) async {
    try {
      state = true;
      final response = await ref
          .read(addressServiceProvider)
          .updateAddress(addAddress: addAddress);
      state = false;
      return CommonResponse(isSuccess: true, message: response.data['message']);
    } catch (error) {
      debugPrint(error.toString());
      state = false;
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> deleteAddress({required int addressId}) async {
    try {
      state = true;
      final response = await ref
          .read(addressServiceProvider)
          .deleteAddress(addressId: addressId);
      state = false;
      return CommonResponse(isSuccess: true, message: response.data['message']);
    } catch (error) {
      debugPrint(error.toString());
      state = false;
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }

  Future<CommonResponse> getAddress() async {
    try {
      state = true;
      final response = await ref.read(addressServiceProvider).getAddress();
      final List<dynamic> addressData = response.data['data']['addresses'];
      _addressList =
          addressData.map((address) => AddAddress.fromMap(address)).toList();
      if (_addressList.isEmpty) {
        ref.read(hiveServiceProvider).clearDefaultAddress();
        ref.read(selectedDeliveryAddress.notifier).state = null;
      } else {
        final savedAddress =
            await ref.read(hiveServiceProvider).getDefaultAddress();
        AddAddress? preferredAddress;

        for (final address in _addressList) {
          if (address.isDefault) {
            preferredAddress = address;
            break;
          }
        }

        if (preferredAddress == null && savedAddress?.addressId != null) {
          for (final address in _addressList) {
            if (address.addressId == savedAddress!.addressId) {
              preferredAddress = address;
              break;
            }
          }
        }

        preferredAddress ??= _addressList.first;
        await ref
            .read(hiveServiceProvider)
            .saveDefaultDeliveryAddress(address: preferredAddress);
        ref.read(selectedDeliveryAddress.notifier).state = preferredAddress;
      }

      state = false;
      return CommonResponse(isSuccess: true, message: response.data['message']);
    } catch (error, stk) {
      debugPrint(stk.toString());
      debugPrint(error.toString());
      state = false;
      return CommonResponse(isSuccess: false, message: error.toString());
    }
  }
}
