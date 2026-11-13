import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:ready_ecommerce/config/app_text_style.dart';
import 'package:ready_ecommerce/config/theme.dart';
import 'package:ready_ecommerce/generated/l10n.dart';
import 'package:ready_ecommerce/models/eCommerce/product/product_details.dart';
import 'package:ready_ecommerce/utils/global_function.dart';

class AvailableOrderOptions extends StatelessWidget {
  final OrderOptions options;

  const AvailableOrderOptions({
    super.key,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    if (!options.doorstepDelivery &&
        !options.storePickup &&
        !options.cashOnDelivery &&
        !options.onlinePayment) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: GlobalFunction.getContainerColor(),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).availableOrderOptions,
            style: AppTextStyle(context).subTitle,
          ),
          Gap(4.h),
          Text(
            S.of(context).chooseOrderOptionsAtCheckout,
            style: AppTextStyle(context).bodyTextSmall.copyWith(
                  color: colors(context).bodyTextSmallColor,
                ),
          ),
          Gap(14.h),
          if (options.doorstepDelivery || options.storePickup) ...[
            _sectionTitle(context, S.of(context).fulfillment),
            Gap(8.h),
            if (options.doorstepDelivery)
              _option(
                context,
                icon: Icons.local_shipping_outlined,
                title: S.of(context).doorstepDelivery,
                subtitle: S.of(context).deliveredToAddress,
              ),
            if (options.storePickup)
              _option(
                context,
                icon: Icons.storefront_outlined,
                title: S.of(context).storePickup,
                subtitle: S.of(context).collectFromShop,
              ),
          ],
          if ((options.doorstepDelivery || options.storePickup) &&
              (options.cashOnDelivery || options.onlinePayment))
            Gap(12.h),
          if (options.cashOnDelivery || options.onlinePayment) ...[
            _sectionTitle(context, S.of(context).payment),
            Gap(8.h),
            if (options.cashOnDelivery)
              _option(
                context,
                icon: Icons.payments_outlined,
                title: S.of(context).cashOnDelivery,
              ),
            if (options.onlinePayment)
              _option(
                context,
                icon: Icons.credit_card_outlined,
                title: S.of(context).payOnline,
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyle(context).bodyText.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21.sp, color: colors(context).primaryColor),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle(context).bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyle(context).bodyTextSmall.copyWith(
                          color: colors(context).bodyTextSmallColor,
                        ),
                  ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 19.sp, color: Colors.green),
        ],
      ),
    );
  }
}
