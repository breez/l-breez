import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';
import 'package:flutter/material.dart';

class PaymentDetailsDestinationPubkey extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsDestinationPubkey({
    super.key,
    required this.paymentMinutiae,
  });

  @override
  Widget build(BuildContext context) {
    final destinationPubkey = paymentMinutiae.swapId;
    if (destinationPubkey.isNotEmpty) {
      return ShareablePaymentRow(
        // TODO: Move this message to Breez-Translations
        title: "Swap ID",
        sharedValue: destinationPubkey,
      );
    } else {
      return Container();
    }
  }
}
