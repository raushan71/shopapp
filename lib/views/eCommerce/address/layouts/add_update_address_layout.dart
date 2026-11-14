// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:ready_ecommerce/components/ecommerce/custom_button.dart';
import 'package:ready_ecommerce/components/ecommerce/custom_text_field.dart';
import 'package:ready_ecommerce/config/app_color.dart';
import 'package:ready_ecommerce/config/app_constants.dart';
import 'package:ready_ecommerce/config/app_text_style.dart';
import 'package:ready_ecommerce/config/theme.dart';
import 'package:ready_ecommerce/controllers/common/master_controller.dart';
import 'package:ready_ecommerce/controllers/eCommerce/address/address_controller.dart';
import 'package:ready_ecommerce/controllers/eCommerce/address/areas_controller.dart';
import 'package:ready_ecommerce/generated/l10n.dart';
import 'package:ready_ecommerce/models/eCommerce/address/add_address.dart';
import 'package:ready_ecommerce/models/eCommerce/address/areas_model.dart';
import 'package:ready_ecommerce/models/eCommerce/address/delivery_location.dart';
import 'package:ready_ecommerce/routes.dart';
import 'package:ready_ecommerce/utils/context_less_navigation.dart';
import 'package:ready_ecommerce/utils/global_function.dart';

class AddUpdateAddressLayout extends ConsumerStatefulWidget {
  final AddAddress? address;
  const AddUpdateAddressLayout({
    super.key,
    required this.address,
  });

  @override
  ConsumerState<AddUpdateAddressLayout> createState() =>
      _AddUpdateAddressLayoutState();
}

class _AddUpdateAddressLayoutState
    extends ConsumerState<AddUpdateAddressLayout> {
  final GlobalKey<FormBuilderState> _formkey = GlobalKey<FormBuilderState>();

  final TextEditingController nameControler = TextEditingController();

  final TextEditingController phoneNumController = TextEditingController();

  // final TextEditingController areaController = TextEditingController();

//  final TextEditingController flatNumController = TextEditingController();

  //final TextEditingController postalCodeController = TextEditingController();

  final TextEditingController addressLine1Controller = TextEditingController();

  // final TextEditingController addressLine2Controller = TextEditingController();

  int activeIndex = 0;

  List<String> addressTags = ['Home', 'Office', 'other'];
  String addressTag = '';

  final List<FocusNode> fNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode()
  ];
  bool isDefaultAddress = false;
  int? selectedAreaId;
  double? selectedLatitude;
  double? selectedLongitude;

  // @override
  // void initState() {
  //   super.initState();
  //
  //   log("----->> ${widget.address?.areaId}");
  //
  //
  //   if (widget.address != null) {
  //     nameControler.text = widget.address!.name;
  //     phoneNumController.text = widget.address!.phone;
  //   //  areaController.text = widget.address!.area ?? '';
  //    // flatNumController.text = widget.address!.flatNo ?? '';
  //    // postalCodeController.text = widget.address!.postCode ?? '';
  //     addressLine1Controller.text = widget.address!.addressLine;
  //    // addressLine2Controller.text = widget.address!.addressLine2 ?? '';
  //     addressTag = widget.address!.addressType;
  //     isDefaultAddress = widget.address!.isDefault;
  //     activeIndex = addressTags.indexOf(widget.address!.addressType);
  //     selectedArea = null;
  //   } else {
  //     addressTag = addressTags.first;
  //   }
  // }

  @override
  void initState() {
    super.initState();

    log("--areaId--->> ${widget.address?.areaId}");

    if (widget.address != null) {
      nameControler.text = widget.address!.name;
      phoneNumController.text = widget.address!.phone;
      addressLine1Controller.text = widget.address!.addressLine;
      addressTag = widget.address!.addressType;
      isDefaultAddress = widget.address!.isDefault;
      activeIndex = addressTags.indexOf(widget.address!.addressType);
      selectedArea = widget.address!.area;
      selectedAreaId = widget.address!.areaId;
      selectedLatitude = widget.address!.latitude;
      selectedLongitude = widget.address!.longitude;

      // Schedule the area selection for after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSelectedArea();
      });
    } else {
      addressTag = addressTags.first;
    }
  }

  void _loadSelectedArea() async {
    if (widget.address?.areaId == null) return;

    final areasAsync = ref.read(areasProvider);

    areasAsync.when(
      data: (areasList) {
        log("--areasList loaded, count: ${areasList.length}");

        try {
          AreasModel? match;
          for (final area in areasList) {
            if (area.id == widget.address!.areaId) {
              match = area;
              break;
            }
          }

          if (match == null) return;

          log("--match found--->> id: ${match.id}, name: ${match.name}");

          if (mounted) {
            setState(() {
              selectedArea = match!.name;
              selectedAreaId = match.id;
            });
          }
        } catch (e) {
          log("--Error finding area: $e");
        }
      },
      loading: () {
        log("--areas still loading, will retry");
        // Retry after a short delay if still loading
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && selectedArea == null) {
            _loadSelectedArea();
          }
        });
      },
      error: (err, stack) {
        log("--Error loading areas: $err");
      },
    );
  }

  @override
  void dispose() {
    nameControler.dispose();
    phoneNumController.dispose();
    //areaController.dispose();
    //flatNumController.dispose();
    // postalCodeController.dispose();
    addressLine1Controller.dispose();
    // addressLine2Controller.dispose();
    super.dispose();
  }

  String? selectedArea;

  @override
  Widget build(BuildContext context) {
    final materModelData =
        ref.watch(masterControllerProvider.notifier).materModel.data;
    final isPhoneRequired = materModelData.phoneRequired;
    int? phoneMinLength = materModelData.phoneMinLength;
    int? phoneMaxLength = materModelData.phoneMaxLength;

    final areaState = ref.watch(areasProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).addNewAddress),
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: FormBuilder(
          key: _formkey,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
            ),
            child: SingleChildScrollView(
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: widget,
                        )),
                    children: [
                      SizedBox(height: 10.h),
                      CustomTextFormField(
                        name: S.of(context).name,
                        hintText: S.of(context).name,
                        textInputType: TextInputType.text,
                        controller: nameControler,
                        focusNode: fNodes[0],
                        textInputAction: TextInputAction.next,
                        validator: (value) => GlobalFunction.commonValidator(
                          context: context,
                          value: value!,
                          hintText: S.of(context).name,
                        ),
                      ),
                      Gap(14.h),
                      CustomTextFormField(
                        name: S.of(context).phone,
                        hintText: S.of(context).phone,
                        textInputType: TextInputType.number,
                        controller: phoneNumController,
                        focusNode: fNodes[1],
                        textInputAction: TextInputAction.next,
                        validator: (value) => GlobalFunction.phoneValidator(
                          isPhoneRequired: isPhoneRequired,
                          context: context,
                          value: value!,
                          hintText: S.of(context).phone,
                          minLength: phoneMinLength,
                          maxLength: phoneMaxLength,
                        ),
                      ),
                      Gap(14.h),
                      Gap(14.h),
                      CustomTextFormField(
                        name: S.of(context).addressOne,
                        hintText: S.of(context).addressOne,
                        textInputType: TextInputType.text,
                        controller: addressLine1Controller,
                        focusNode: fNodes[5],
                        textInputAction: TextInputAction.next,
                        validator: (value) => GlobalFunction.commonValidator(
                          context: context,
                          value: value!,
                          hintText: S.of(context).addressOne,
                        ),
                      ),
                      Gap(14.h),
                      CustomButton(
                          buttonText: widget.address != null
                              ? "Update Delivery Location"
                              : "Pin Delivery Location",
                          onPressed: () async {
                            final location =
                                await context.nav.pushNamed<DeliveryLocation>(
                              Routes.getTrackOrderRouteName(
                                AppConstants.appServiceName,
                              ),
                              arguments: [
                                selectedLatitude != null &&
                                    selectedLongitude != null,
                                selectedLatitude,
                                selectedLongitude,
                              ],
                            );

                            if (!mounted || location == null) return;

                            setState(() {
                              selectedLatitude = location.latitude;
                              selectedLongitude = location.longitude;
                              addressLine1Controller.text = location.address;
                            });
                          }),
                      Gap(14.h),
                      _buildAreaSelector(areaState),
                      Gap(14.h),
                      buildAddressTag(),
                      Gap(14.h),
                      Row(
                        children: [
                          Checkbox(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeColor: colors(context).primaryColor,
                            value: isDefaultAddress,
                            onChanged: (defult) {
                              setState(() {
                                isDefaultAddress = defult!;
                              });
                            },
                          ),
                          Text(S.of(context).makeItDefault,
                              style: AppTextStyle(context).bodyTextSmall),
                          const Spacer(),
                          widget.address?.addressId != null
                              ? TextButton(
                                  onPressed: () async {
                                    final controller = ref.read(
                                        addressControllerProvider.notifier);
                                    final response =
                                        await controller.deleteAddress(
                                      addressId: widget.address?.addressId ?? 0,
                                    );

                                    if (!context.mounted) return;
                                    GlobalFunction.showCustomSnackbar(
                                      message: response.message,
                                      isSuccess: response.isSuccess,
                                    );
                                    if (response.isSuccess) {
                                      await controller.getAddress();
                                      if (context.mounted) context.nav.pop();
                                    }
                                  },
                                  child: Text(
                                    S.of(context).deleteThis,
                                    style: AppTextStyle(context)
                                        .bodyText
                                        .copyWith(color: EcommerceAppColor.red),
                                  ),
                                )
                              : const SizedBox()
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 85.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20),
            child: ref.watch(addressControllerProvider)
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : CustomButton(
                    buttonText: S.of(context).save,
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        final latitude = selectedLatitude;
                        final longitude = selectedLongitude;

                        if (latitude == null || longitude == null) {
                          GlobalFunction.showCustomSnackbar(
                            message:
                                "Please pin your delivery location on the map",
                            isSuccess: false,
                          );
                          return;
                        }
                        if (selectedAreaId == null) {
                          GlobalFunction.showCustomSnackbar(
                            message: "Please select your Area",
                            isSuccess: false,
                          );
                          return;
                        }
                        final AddAddress address = AddAddress(
                          addressId: widget.address?.addressId,
                          name: nameControler.text,
                          phone: phoneNumController.text,
                          area: selectedArea,
                          // flatNo: flatNumController.text,
                          //postCode: postalCodeController.text,
                          addressLine: addressLine1Controller.text,
                          // addressLine2: addressLine2Controller.text,
                          latitude: latitude,
                          longitude: longitude,
                          areaId: selectedAreaId,
                          addressType: addressTag,
                          isDefault: isDefaultAddress,
                        );
                        final controller =
                            ref.read(addressControllerProvider.notifier);
                        final response = widget.address != null
                            ? await controller.updateAddress(
                                addAddress: address)
                            : await controller.addAddress(addAddress: address);

                        if (!context.mounted) return;
                        GlobalFunction.showCustomSnackbar(
                          message: response.message,
                          isSuccess: response.isSuccess,
                        );
                        if (response.isSuccess) {
                          await controller.getAddress();
                          if (context.mounted) context.nav.pop();
                        }
                      }
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaSelector(AsyncValue<List<AreasModel>> areaState) {
    return areaState.when(
      data: (areasList) {
        if (areasList.isEmpty) {
          return _areaSelectorContainer(
            label: 'No delivery areas available',
            trailing: const Icon(Icons.info_outline),
          );
        }

        return PopupMenuButton<int>(
          offset: const Offset(0, 52),
          onSelected: (areaId) {
            final area = areasList.firstWhere((item) => item.id == areaId);
            setState(() {
              selectedAreaId = area.id;
              selectedArea = area.name;
            });
          },
          itemBuilder: (context) => areasList
              .where((area) => area.id != null && area.name != null)
              .map<PopupMenuEntry<int>>(
                (area) => PopupMenuItem<int>(
                  value: area.id!,
                  child: Text(
                    area.name!,
                    style: TextStyle(color: colors(context).primaryColor),
                  ),
                ),
              )
              .toList(),
          child: _areaSelectorContainer(
            label: selectedArea ?? 'Select Area',
            trailing: Icon(
              Icons.arrow_drop_down,
              color: colors(context).primaryColor,
            ),
          ),
        );
      },
      loading: () => _areaSelectorContainer(
        label: 'Loading areas...',
        trailing: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(areasProvider.notifier).getAreasList(),
        child: _areaSelectorContainer(
          label: 'Unable to load areas. Tap to retry',
          textColor: colors(context).errorColor,
          trailing: Icon(Icons.refresh, color: colors(context).errorColor),
        ),
      ),
    );
  }

  Widget _areaSelectorContainer({
    required String label,
    required Widget trailing,
    Color? textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: colors(context).primaryColor!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? colors(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget buildAddressTag() {
    final textStyle = AppTextStyle(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).addressTag,
          style: AppTextStyle(context)
              .bodyTextSmall
              .copyWith(fontWeight: FontWeight.w500),
        ),
        Gap(14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: addressTags.asMap().entries.map(
            (entry) {
              int index = entry.key;
              String tag = entry.value;
              return InkWell(
                borderRadius: BorderRadius.circular(8.sp),
                onTap: () {
                  setState(() {
                    activeIndex = index;
                    addressTag = tag;
                  });
                },
                child: Container(
                  height: 50.h,
                  width: 110.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.sp),
                    border: Border.all(
                      color: activeIndex == index
                          ? colors(context).primaryColor ??
                              EcommerceAppColor.primary
                          : colors(context)
                              .bodyTextColor!
                              .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      getTagTranslation(tag: tag),
                      style: textStyle.bodyTextSmall.copyWith(
                          color: activeIndex == index
                              ? colors(context).primaryColor ??
                                  EcommerceAppColor.primary
                              : colors(context).bodyTextColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  String getTagTranslation({required String tag}) {
    switch (tag.toUpperCase()) {
      case 'HOME':
        return S.of(ContextLess.context).home;
      case 'OFFICE':
        return S.of(ContextLess.context).office;
      default:
        return S.of(ContextLess.context).other;
    }
  }
}
