import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itrsp_shop/config/theme.dart';
import 'package:itrsp_shop/controllers/common/master_controller.dart';
import 'package:itrsp_shop/models/common/master_model.dart';
import 'package:itrsp_shop/models/eCommerce/order/order_details_model.dart';
import 'package:itrsp_shop/views/eCommerce/order_details/components/order_product_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fonts = FontLoader('Mulish')
      ..addFont(rootBundle.load('assets/font/Mulish-Regular.ttf'));
    await fonts.load();
  });

  for (final width in [320.0, 390.0, 430.0]) {
    for (final rated in [false, true]) {
      testWidgets(
          'return dialog fits ${rated ? 'rated variants' : 'discounted prices'} '
          'at $width pixels before and after selection', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(currencyProvider.notifier).updateCurrency(Currency(
              name: 'INR',
              symbol: '\u20b9',
              position: 'prefix',
              rate: 1,
            ));
        final product = Products(
          id: 1,
          name: 'Cotton leggings combo pack',
          brand: null,
          thumbnail: 'https://example.com/product.png',
          price: rated ? 499 : 129999,
          discountPrice: rated ? 0 : 99999,
          orderQty: 2,
          color: rated ? 'midnight blue' : 'black',
          size: rated ? 'extra large' : 'M',
          rating: rated ? 4.5 : null,
          isReturnable: true,
          attachments: [],
        );
        var selected = false;

        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              theme: getAppTheme(context: context, isDarkTheme: false),
              home: Scaffold(
                body: Dialog(
                  child: SingleChildScrollView(
                    child: StatefulBuilder(builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Select Return Items'),
                          GestureDetector(
                            onTap: () => setState(() => selected = !selected),
                            child: OrderProductCard(
                              orderId: 1,
                              product: product,
                              index: 0,
                              orderStatus: 'Delivered',
                              paymentStatus: 'Paid',
                              showCheckbox: true,
                              hideReviewButton: true,
                              isSelected: selected,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(product.name), findsOneWidget);
        expect(find.text(rated ? 'Midnight blue' : 'Black'), findsOneWidget);
        expect(find.text(rated ? 'Extra large' : 'M'), findsOneWidget);

        await tester.tap(find.byType(OrderProductCard));
        await tester.pump();

        expect(selected, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
