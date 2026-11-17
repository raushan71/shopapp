import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:itrsp_shop/config/app_text_style.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/eCommerce/product/product_details.dart';
import 'package:itrsp_shop/utils/global_function.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: GlobalFunction.getContainerColor(),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: colors(context).accentColor ?? Colors.transparent,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: colors(context).primaryColor!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 21.sp,
                  color: colors(context).primaryColor,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).availableOrderOptions,
                      style: AppTextStyle(context).subTitle,
                    ),
                    Gap(2.h),
                    Text(
                      S.of(context).chooseOrderOptionsAtCheckout,
                      style: AppTextStyle(context).bodyTextSmall.copyWith(
                            color: colors(context).bodyTextSmallColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(18.h),
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
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: colors(context).accentColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: colors(context).primaryColor!.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: colors(context).primaryColor),
          ),
          Gap(12.w),
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
          Icon(Icons.check_circle_rounded,
              size: 20.sp, color: Colors.green.shade600),
        ],
      ),
    );
  }
}
