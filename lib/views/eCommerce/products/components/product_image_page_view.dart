import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:itrsp_shop/config/app_color.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/controllers/misc/misc_controller.dart';
import 'package:itrsp_shop/models/eCommerce/product/product_details.dart';
import 'package:itrsp_shop/views/eCommerce/products/components/iframe_card.dart';
import 'package:itrsp_shop/views/eCommerce/products/components/video_player.dart';

import '../../../../config/app_constants.dart';

class ProductImagePageView extends ConsumerStatefulWidget {
  final ProductDetails productDetails;
  const ProductImagePageView({
    super.key,
    required this.productDetails,
  });

  @override
  ConsumerState<ProductImagePageView> createState() =>
      _ProductImagePageViewState();
}

class _ProductImagePageViewState extends ConsumerState<ProductImagePageView> {
  PageController pageController = PageController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentPageController.notifier).state = 0;
    });
    pageController.addListener(() {
      int? newPage = pageController.page?.round();
      if (newPage != null && newPage != ref.read(currentPageController)) {
        ref.read(currentPageController.notifier).state = newPage;
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageController);
    final selectedColorIndex = ref.watch(selectedProductColorIndex);
    final productColors = widget.productDetails.product.colors;
    final variantMedia = selectedColorIndex != null &&
            selectedColorIndex >= 0 &&
            selectedColorIndex < productColors.length
        ? productColors[selectedColorIndex].media
        : const <Thumbnail>[];
    final displayMedia = variantMedia.isNotEmpty
        ? variantMedia
        : widget.productDetails.product.thumbnails;

    ref.listen<int?>(selectedProductColorIndex, (previous, next) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !pageController.hasClients) return;
        pageController.jumpToPage(0);
        ref.read(currentPageController.notifier).state = 0;
      });
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 420.h,
          child: PageView.builder(
            key: ValueKey(selectedColorIndex),
            controller: pageController,
            itemCount: displayMedia.length,
            itemBuilder: (context, index) {
              final media = displayMedia[index];
              final fileSystem = media.type;
              if (fileSystem == FileSystem.image.name) {
                return CachedNetworkImage(
                  imageUrl: media.thumbnail ?? '',
                  fit: BoxFit.contain,
                );
              } else if (fileSystem == FileSystem.file.name) {
                return VideoPlayer(
                  videoUrl: media.url ?? '',
                );
              } else {
                return Container(
                  padding: EdgeInsets.only(top: 100.h),
                  width: double.infinity,
                  child: IframeCard(
                    iframeUrl: media.url ?? '',
                  ),
                );
              }
            },
          ),
        ),
        Positioned(
          bottom: 16.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 3.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: EcommerceAppColor.lightGray,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                displayMedia.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? colors(context).light
                        : colors(context).accentColor!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30.sp),
                  ),
                  height: 8.h,
                  width: 8.w,
                ),
              ).toList(),
            ),
          ),
        )
      ],
    );
  }
}
