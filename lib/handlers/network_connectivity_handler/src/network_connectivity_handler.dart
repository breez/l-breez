import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/connectivity/connectivity_cubit.dart';
import 'package:l_breez/handlers/handler/src/handler.dart';
import 'package:l_breez/handlers/handler/src/mixin/handler_context_provider.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:logging/logging.dart';

final _log = Logger("NetworkConnectivityHandler");

class NetworkConnectivityHandler extends Handler {
  StreamSubscription<ConnectivityState>? _subscription;
  Flushbar? _flushbar;

  @override
  void init(HandlerContextProvider<StatefulWidget> contextProvider) {
    super.init(contextProvider);
    _subscription = contextProvider
        .getBuildContext()!
        .read<ConnectivityCubit>()
        .stream
        .distinct((previous, next) => previous.connectivityResult == next.connectivityResult)
        .listen(_listen);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _subscription = null;
    _flushbar = null;
  }

  void _listen(ConnectivityState connectivityState) async {
    _log.info("Received connectivityState $connectivityState");
    if (!connectivityState.hasNetworkConnection) {
      showNoInternetConnectionFlushbar();
    } else {
      dismissFlushbarIfNeed();
    }
  }

  void showNoInternetConnectionFlushbar() {
    dismissFlushbarIfNeed();
    final context = contextProvider?.getBuildContext();
    if (context == null) {
      _log.info("Skipping connection flushbar as context is null");
      return;
    }
    _flushbar = _getNoConnectionFlushbar(context);
    _flushbar?.show(context);
  }

  void dismissFlushbarIfNeed() async {
    final flushbar = _flushbar;
    if (flushbar == null) return;

    if (flushbar.flushbarRoute != null && flushbar.flushbarRoute!.isActive) {
      final context = contextProvider?.getBuildContext();
      if (context == null) {
        _log.info("Skipping dismissing connection flushbar as context is null");
        return;
      }
      Navigator.of(context).removeRoute(flushbar.flushbarRoute!);
    }
    _flushbar = null;
  }

  Flushbar? _getNoConnectionFlushbar(BuildContext context) {
    var themeData = Theme.of(context);

    return Flushbar(
      isDismissible: false,
      flushbarPosition: FlushbarPosition.TOP,
      icon: Icon(
        Icons.warning_amber_outlined,
        size: 28.0,
        color: themeData.colorScheme.error,
      ),
      messageText: Text(
        context.texts().no_connection_flushbar_title,
        style: snackBarStyle,
        textAlign: TextAlign.center,
      ),
      backgroundColor: snackBarBackgroundColor,
    );
  }
}
