import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ready_ecommerce/controllers/eCommerce/return_policy/return_policy_controller.dart';
import 'package:ready_ecommerce/views/eCommerce/return_order/componants/cancel_return_request_button.dart';

class ReturnRequestCancelAction extends ConsumerWidget {
  final int? returnRequestId;
  final bool canCancel;

  const ReturnRequestCancelAction({
    super.key,
    required this.returnRequestId,
    required this.canCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestId = returnRequestId;
    if (!canCancel || requestId == null) return const SizedBox.shrink();

    final cancelling =
        ref.watch(returnCancellationControllerProvider).contains(requestId);
    return CancelReturnRequestButton(
      enabled: !cancelling,
      onCancel: () => ref
          .read(returnCancellationControllerProvider.notifier)
          .cancelReturnRequest(returnRequestId: requestId),
    );
  }
}
