import 'package:flutter/material.dart';
import 'package:itrsp_shop/generated/l10n.dart';
import 'package:itrsp_shop/models/eCommerce/common/common_response.dart';

class CancelReturnRequestButton extends StatefulWidget {
  final Future<CommonResponse> Function() onCancel;
  final VoidCallback? onCancelled;
  final bool enabled;

  const CancelReturnRequestButton({
    super.key,
    required this.onCancel,
    this.onCancelled,
    this.enabled = true,
  });

  @override
  State<CancelReturnRequestButton> createState() =>
      _CancelReturnRequestButtonState();
}

class _CancelReturnRequestButtonState extends State<CancelReturnRequestButton> {
  bool _isBusy = false;
  bool _isCancelling = false;

  Future<void> _cancelReturn() async {
    if (_isBusy || !widget.enabled) return;
    setState(() => _isBusy = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).cancelReturnRequestConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).keepReturnRequest),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).cancelReturnRequest),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _isCancelling = true);
      final response = await widget.onCancel();
      if (!mounted) return;

      final message = response.message.trim().isNotEmpty
          ? response.message
          : response.isSuccess
              ? S.of(context).returnCancellationSuccess
              : S.of(context).returnCancellationFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (response.isSuccess) widget.onCancelled?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).returnCancellationFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isBusy || !widget.enabled ? null : _cancelReturn,
      icon: _isCancelling
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.close, size: 18),
      label: Text(
        S.of(context).cancelReturnRequest,
        textAlign: TextAlign.center,
      ),
    );
  }
}
