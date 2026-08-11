import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('ServiceOutagePage');

/// Wind-down notice, carrying the exchange services, the disclaimer and the wallet we
/// recommend. Kept off the app so the options can change without shipping a release, and
/// so this page has one thing to say.
const String _moveFundsUrl = 'https://breez.technology/misty/';

const String _noticeSeenKey = 'service_outage_notice_seen';

/// Opens the notice on startup, once ever.
///
/// After the first time, the home app bar warning carries the signal, so re-showing this on
/// every launch would only be nagging.
Future<void> showServiceOutageNoticeIfUnseen(BuildContext context) async {
  if (!ServiceOutage.swapsUnavailable) {
    return;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_noticeSeenKey) ?? false) {
    return;
  }
  // Marked before opening, so being killed on the page does not bring it back.
  await prefs.setBool(_noticeSeenKey, true);

  if (context.mounted) {
    await Navigator.of(context).pushNamed(ServiceOutagePage.routeName);
  }
}

/// Copy is hardcoded English, as ExceptionHandler's swap messages are: Breez-Translations is
/// pinned to a git ref, and a temporary notice is not worth the round-trip.
class ServiceOutagePage extends StatelessWidget {
  static const String routeName = '/service_outage';

  const ServiceOutagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle? bodyStyle = themeData.primaryTextTheme.titleLarge?.copyWith(height: 1.5);

    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: const Text('Service unavailable')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'The service Misty Breez relies on is no longer available. On-chain and Lightning '
              'payments cannot be made in the app.',
              style: bodyStyle,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Sending and receiving with a Liquid address still works, and is how you move your '
              'funds out.',
              style: bodyStyle,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        text: 'MOVE YOUR FUNDS',
        onPressed: () {
          _logger.info('Opening the wind-down page');
          ExternalBrowserService.launchLink(context, linkAddress: _moveFundsUrl);
        },
      ),
    );
  }
}
