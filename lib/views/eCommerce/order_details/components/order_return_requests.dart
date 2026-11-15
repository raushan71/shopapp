import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ready_ecommerce/config/app_constants.dart';
import 'package:ready_ecommerce/controllers/eCommerce/return_policy/return_policy_controller.dart';
import 'package:ready_ecommerce/generated/l10n.dart';
import 'package:ready_ecommerce/routes.dart';
import 'package:ready_ecommerce/views/eCommerce/return_order/componants/return_request_cancel_action.dart';

class OrderReturnRequests extends ConsumerWidget {
  final int orderId;
  final String orderCode;

  const OrderReturnRequests({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = orderReturnRequestsProvider(
      (orderId: orderId, orderCode: orderCode),
    );
    return ref.watch(provider).when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(S.of(context).returnRequestsLoadFailed),
                TextButton(
                  onPressed: () => ref.invalidate(provider),
                  child: Text(S.of(context).retry),
                ),
              ],
            ),
          ),
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).returnOrders,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final request in requests) ...[
                    const Divider(),
                    Text('#${request.id ?? ''}'),
                    if (request.status != null)
                      Text('${S.of(context).returnStatus}: ${request.status}'),
                    if (request.reason?.isNotEmpty == true)
                      Text(request.reason!),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (request.id != null)
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              Routes.getReturnOrderDetailsViewRouteName(
                                AppConstants.appServiceName,
                              ),
                              arguments: request.id,
                            ),
                            child: Text(S.of(context).viewReturnRequest),
                          ),
                        ReturnRequestCancelAction(
                          key: ValueKey(request.id),
                          returnRequestId: request.id,
                          canCancel: request.canCancel,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }
}
