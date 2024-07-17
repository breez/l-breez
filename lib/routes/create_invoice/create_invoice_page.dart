import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/create_invoice/qr_code_dialog.dart';
import 'package:l_breez/routes/create_invoice/widgets/successful_payment.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_dialog.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:logging/logging.dart';

final _log = Logger("CreateInvoicePage");

class CreateInvoicePage extends StatefulWidget {
  final Function(LNURLPageResult? result)? onFinish;
  final LnUrlWithdrawRequestData? requestData;

  static const routeName = "/create_invoice";

  const CreateInvoicePage({super.key, this.onFinish, this.requestData})
      : assert(
          requestData == null || (onFinish != null),
          "If you are using LNURL withdraw, you must provide an onFinish callback.",
        );

  @override
  State<StatefulWidget> createState() => CreateInvoicePageState();
}

class CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _doneAction = KeyboardDoneAction();

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: [_amountFocusNode]);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final data = widget.requestData;
        if (data != null) {
          final currencyState = context.read<CurrencyCubit>().state;
          _amountController.text = currencyState.bitcoinCurrency.format(
            data.maxWithdrawable.toInt() ~/ 1000,
            includeDisplayName: false,
          );
          _descriptionController.text = data.defaultDescription;
        }
      },
    );
  }

  @override
  void dispose() {
    _doneAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.invoice_title),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 40.0),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    maxLength: 90,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      labelText: texts.invoice_description_label,
                    ),
                    style: theme.FieldTextStyle.textStyle,
                  ),
                  BlocBuilder<CurrencyCubit, CurrencyState>(
                    builder: (context, currencyState) {
                      return AmountFormField(
                        context: context,
                        texts: texts,
                        bitcoinCurrency: currencyState.bitcoinCurrency,
                        focusNode: _amountFocusNode,
                        controller: _amountController,
                        validatorFn: (v) => validatePayment(v),
                        style: theme.FieldTextStyle.textStyle,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        stickToBottom: true,
        text: widget.requestData != null ? texts.invoice_action_redeem : texts.invoice_action_create,
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            final data = widget.requestData;
            if (data != null) {
              _withdraw(data);
            } else {
              _createInvoice();
            }
          }
        },
      ),
    );
  }

  Future<void> _withdraw(
    LnUrlWithdrawRequestData data,
  ) async {
    _log.info(
      "Withdraw request: description=${data.defaultDescription}, k1=${data.k1}, "
      "min=${data.minWithdrawable}, max=${data.maxWithdrawable}",
    );
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();

    final navigator = Navigator.of(context);
    navigator.pop();

    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => LNURLWithdrawDialog(
        requestData: data,
        amountSats: currencyCubit.state.bitcoinCurrency.parse(
          _amountController.text,
        ),
        onFinish: widget.onFinish!,
      ),
    );
  }

  Future _createInvoice() async {
    _log.info("Create invoice: description=${_descriptionController.text}, amount=${_amountController.text}");
    final navigator = Navigator.of(context);
    final currentRoute = ModalRoute.of(navigator.context)!;
    final accountCubit = context.read<AccountCubit>();
    final currencyCubit = context.read<CurrencyCubit>();

    final amountMsat = currencyCubit.state.bitcoinCurrency.parse(_amountController.text);
    final prepareReceiveResponse = await accountCubit.prepareReceivePayment(amountMsat);
    final receivePaymentResponse = accountCubit.receivePayment(prepareReceiveResponse);

    navigator.pop();
    Widget dialog = FutureBuilder(
      future: receivePaymentResponse,
      builder: (BuildContext context, AsyncSnapshot<liquid_sdk.ReceivePaymentResponse> snapshot) {
        _log.info("Building QrCodeDialog with invoice: ${snapshot.data}, error: ${snapshot.error}");
        return QrCodeDialog(
          prepareReceiveResponse,
          snapshot.data,
          snapshot.error,
          (result) {
            onPaymentFinished(result, currentRoute, navigator);
          },
        );
      },
    );

    return showDialog(
      useRootNavigator: false,
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
  }

  void onPaymentFinished(
    dynamic result,
    ModalRoute currentRoute,
    NavigatorState navigator,
  ) {
    _log.info("Payment finished: $result");
    if (result == true) {
      if (currentRoute.isCurrent) {
        navigator.push(
          TransparentPageRoute((ctx) => const SuccessfulPaymentRoute()),
        );
      }
    } else {
      if (result is String) {
        showFlushbar(context, title: "", message: result);
      }
    }
  }

  String? validatePayment(int amount) {
    var currencyCubit = context.read<CurrencyCubit>();
    return PaymentValidator(
      validatePayment: _validatePayment,
      currency: currencyCubit.state.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validatePayment(int amount, bool outgoing) {
    var accountCubit = context.read<AccountCubit>();
    return accountCubit.validatePayment(amount, outgoing);
  }
}
