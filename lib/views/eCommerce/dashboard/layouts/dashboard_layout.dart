import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itrsp_shop/components/ecommerce/confirmation_dialog.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/controllers/eCommerce/cart/cart_controller.dart';
import 'package:itrsp_shop/controllers/misc/misc_controller.dart';
import 'package:itrsp_shop/gen/assets.gen.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/routes.dart';
import 'package:itrsp_shop/services/common/hive_service_provider.dart';
import 'package:itrsp_shop/utils/context_less_navigation.dart';
import 'package:itrsp_shop/utils/global_function.dart';
import 'package:itrsp_shop/views/eCommerce/dashboard/components/app_bottom_navbar.dart';
import 'package:itrsp_shop/views/eCommerce/home/home_view.dart';
import 'package:itrsp_shop/views/eCommerce/more/more_view.dart';
import 'package:itrsp_shop/views/eCommerce/my_cart/my_cart_view.dart';
import 'package:itrsp_shop/views/eCommerce/my_message/my_message_view.dart';

class EcommerceDashboardLayout extends ConsumerStatefulWidget {
  const EcommerceDashboardLayout({super.key});

  @override
  ConsumerState<EcommerceDashboardLayout> createState() =>
      _EcommerceDashboardLayoutState();
}

class _EcommerceDashboardLayoutState
    extends ConsumerState<EcommerceDashboardLayout> {
  @override
  void initState() {
    _init();
    super.initState();
  }

  _init() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(hiveServiceProvider).getAuthToken().then((token) {
        if (token != null) {
          ref.read(cartController.notifier).getAllCarts();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(bottomTabControllerProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (onPop) {
        if (ref.read(selectedTabIndexProvider) != 0) {
          ref.read(selectedTabIndexProvider.notifier).state = 0;
          pageController.jumpToPage(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        bottomNavigationBar: AppBottomNavbar(
            bottomItem: getBottomItems(context: context),
            onSelect: (index) {
              if (index != null) {
                if (index == 2 &&
                    !ref.read(hiveServiceProvider).userIsLoggedIn()) {
                  _warningDialog(ref: ref);
                } else {
                  pageController.jumpToPage(index);
                }
              }
            }),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          onPageChanged: (index) {
            ref.read(selectedTabIndexProvider.notifier).state = index;
          },
          children: const [
            EcommerceHomeView(),
            EcommerceMyCartView(
              isRoot: true,
              isBuyNow: false,
            ),
            MyMessageView(),
            EcommerceMoreView()
          ],
        ),
      ),
    );
  }
}

void _warningDialog({required WidgetRef ref}) {
  showDialog(
    barrierColor: colors(GlobalFunction.navigatorKey.currentContext!)
        .accentColor!
        .withOpacity(0.8),
    context: GlobalFunction.navigatorKey.currentContext!,
    builder: (_) => ConfirmationDialog(
      title: S.of(ContextLess.context).youAreNotLoggedIn,
      confirmButtonText:
          S.of(GlobalFunction.navigatorKey.currentContext!).login,
      onPressed: () {
        ref.refresh(selectedTabIndexProvider.notifier).state;
        GlobalFunction.navigatorKey.currentContext!.nav
            .pushNamedAndRemoveUntil(Routes.login, (route) => false);
      },
    ),
  );
}

List<BottomItem> getBottomItems({required BuildContext context}) {
  return [
    BottomItem(
      icon: Assets.svg.inactiveHome,
      activeIcon: Assets.svg.activeHome,
      name: S.of(context).home,
    ),
    BottomItem(
      icon: Assets.svg.inactiveBag,
      activeIcon: Assets.svg.activeBag,
      name: S.of(context).myCart,
    ),
    BottomItem(
      icon: Assets.svg.message,
      activeIcon: Assets.svg.message,
      name: S.of(context).message,
    ),
    BottomItem(
      icon: Assets.svg.inactiveMore,
      activeIcon: Assets.svg.activeMore,
      name: S.of(context).more,
    ),
  ];
}

class BottomItem {
  final String icon;
  final String activeIcon;
  final String name;
  BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.name,
  });
}
