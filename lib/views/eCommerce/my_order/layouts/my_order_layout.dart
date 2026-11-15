import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:ready_ecommerce/config/app_color.dart';
import 'package:ready_ecommerce/config/app_text_style.dart';
import 'package:ready_ecommerce/config/theme.dart';
import 'package:ready_ecommerce/controllers/eCommerce/order/order_controller.dart';
import 'package:ready_ecommerce/controllers/misc/misc_controller.dart';
import 'package:ready_ecommerce/generated/l10n.dart';
import 'package:ready_ecommerce/models/eCommerce/order/order_model.dart';
import 'package:ready_ecommerce/utils/global_function.dart';

import '../components/my_order_card_widget.dart';

class MyOrderLayout extends ConsumerStatefulWidget {
  final String? orderStatus;
  const MyOrderLayout({super.key, this.orderStatus});

  static TextEditingController nameController = TextEditingController();
  static TextEditingController phoneController = TextEditingController();
  static TextEditingController emailController = TextEditingController();

  @override
  ConsumerState<MyOrderLayout> createState() => _MyOrderLayoutState();

  static List<Map<String, dynamic>> getOrderStatus(BuildContext context) {
    List<Map<String, dynamic>> orderStatus = [
      {'key': 'all', 'value': S.of(context).all},
      {'key': 'Pending', 'value': S.of(context).pending},
      {'key': 'Confirm', 'value': S.of(context).confirm},
      {'key': 'Processing', 'value': S.of(context).processig},
      {'key': 'On the Way', 'value': S.of(context).onTheWay},
      {'key': 'Delivered', 'value': S.of(context).delivered},
      {'key': 'Cancelled', 'value': S.of(context).cancelled},
    ];

    return orderStatus;
  }
}

class _MyOrderLayoutState extends ConsumerState<MyOrderLayout> {
  final ScrollController orderScrollController = ScrollController();

  int page = 1;
  int perPage = 20;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      ref.read(selectedMyOrderIndexProvider.notifier).state = 0;
      _loadOrders();
    });
    orderScrollController.addListener(orderScrollListener);
  }

  String? get _selectedOrderStatus {
    if (widget.orderStatus != null) return widget.orderStatus;
    final index = ref.read(selectedMyOrderIndexProvider);
    return index == 0
        ? null
        : MyOrderLayout.getOrderStatus(context)[index]['key'] as String;
  }

  Future<void> _loadOrders({bool isPagination = false}) async {
    final nextPage = isPagination ? page + 1 : 1;
    final success = await ref.read(orderControllerProvider.notifier).getOrders(
          orderStatus: _selectedOrderStatus,
          page: nextPage,
          perPage: perPage,
          isPagination: isPagination,
        );
    if (mounted && success) page = nextPage;
  }

  void orderScrollListener() {
    if (!orderScrollController.hasClients ||
        ref.read(orderControllerProvider)) {
      return;
    }
    final controller = ref.read(orderControllerProvider.notifier);
    if (orderScrollController.position.extentAfter < 200 &&
        controller.ordersError == null &&
        controller.orders.length < (controller.totalOrder ?? 0)) {
      _loadOrders(isPagination: true);
    }
  }

  @override
  void dispose() {
    orderScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors(context).accentColor,
      appBar: AppBar(
        title: Text(widget.orderStatus != null
            ? S.of(context).myDigitalProducts
            : S.of(context).myOrder),
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap(3.h),
          if (widget.orderStatus == null) _buildTabBarWidget(context, ref),
          Gap(5.h),
          _buildOrderListWidget()
        ],
      ),
    );
  }

  Widget _buildOrderListWidget() {
    final isLoading = ref.watch(orderControllerProvider);
    final controller = ref.read(orderControllerProvider.notifier);
    final orders = controller.orders;
    return Expanded(
      child: isLoading && orders.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadOrders(),
              child: AnimationLimiter(
                child: CustomScrollView(
                  controller: orderScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (orders.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: controller.ordersError != null
                              ? _buildOrderError(
                                  controller.ordersError!,
                                  () => _loadOrders(),
                                )
                              : Text(
                                  'Order not found!',
                                  style: AppTextStyle(context).subTitle,
                                ),
                        ),
                      )
                    else
                      SliverList.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final OrderModel order = orders[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.h,
                              child: FadeInAnimation(
                                child: MyOrderCard(
                                  order: order,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    if (isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    if (orders.isNotEmpty && controller.ordersError != null)
                      SliverToBoxAdapter(
                        child: _buildOrderError(
                          controller.ordersError!,
                          () => _loadOrders(isPagination: true),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderError(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTabBarWidget(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50.h,
      width: double.infinity,
      color: GlobalFunction.getContainerColor(),
      child: ListView.builder(
        padding: EdgeInsets.only(left: 12.w),
        scrollDirection: Axis.horizontal,
        itemCount: MyOrderLayout.getOrderStatus(context).length,
        shrinkWrap: true,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            if (ref.read(selectedMyOrderIndexProvider.notifier).state !=
                index) {
              ref.read(selectedMyOrderIndexProvider.notifier).state = index;
              page = 1;
              if (orderScrollController.hasClients) {
                orderScrollController.jumpTo(0);
              }
              _loadOrders();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 6.w),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
            ),
            decoration: BoxDecoration(
              color: ref.watch(selectedMyOrderIndexProvider) == index
                  ? colors(context).primaryColor
                  : colors(context).accentColor,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Center(
              child: Text(
                MyOrderLayout.getOrderStatus(context)[index]['value'],
                style: AppTextStyle(context).bodyTextSmall.copyWith(
                      color: ref.watch(selectedMyOrderIndexProvider) == index
                          ? EcommerceAppColor.white
                          : null,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum OrderStatus {
  all,
  pending,
  confirm,
  processing,
  onTheWay,
  delivered,
  canceled,
}
