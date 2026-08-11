import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('ServiceOutageSheet');

const String _glowAppStoreUrl = 'https://apps.apple.com/us/app/glow-lightning-fast-bitcoin/id6762465698';
const String _glowPlayStoreUrl = 'https://play.google.com/store/apps/details?id=technology.breez.glow';

/// Page listing the third-party services that can move funds out of this wallet.
/// Deliberately a link instead of an in-app list, so the options can be changed
/// without shipping a new app version.
const String _moveFundsUrl = 'https://breez.technology/misty/move-funds.html';

const String _noticeSeenKey = 'service_outage_notice_seen';

/// Shows the outage notice on startup, once ever.
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
  // Marked before showing, so being killed mid-sheet does not bring it back.
  await prefs.setBool(_noticeSeenKey, true);

  if (context.mounted) {
    await showServiceOutageSheet(context);
  }
}

/// The same notice, on demand from the home app bar warning.
Future<void> showServiceOutageSheet(BuildContext context) async {
  _logger.info('Showing service outage notice');

  final bool? getGlow = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const _ServiceOutageSheet(),
  );

  if (getGlow == true && context.mounted) {
    await ExternalBrowserService.launchLink(
      context,
      linkAddress: Platform.isIOS ? _glowAppStoreUrl : _glowPlayStoreUrl,
    );
  }
}

/// Copy is hardcoded English, as ExceptionHandler's swap messages are: Breez-Translations is
/// pinned to a git ref, and a temporary notice is not worth the round-trip.
class _ServiceOutageSheet extends StatelessWidget {
  const _ServiceOutageSheet();

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    // Both themes put sheets on a dark canvas, so this text is white rather than themeData's
    // label colours, which resolve to blue-on-blue in the light theme.
    const TextStyle bodyStyle = TextStyle(color: Colors.white70, fontSize: 16.0, height: 1.5);
    const TextStyle actionStyle = TextStyle(color: Colors.white, fontSize: 14.3, letterSpacing: 1.25);

    return Container(
      decoration: BoxDecoration(
        color: themeData.canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const BottomSheetHandle(),
          const BottomSheetTitle(title: 'On-chain and Lightning are unavailable'),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: <InlineSpan>[
                    const TextSpan(
                      text:
                          'The service Misty Breez relies on is no longer available. As a result, on-chain '
                          'and Lightning payments cannot be made in the app. To mitigate this, we added the '
                          'ability to send and receive with a Liquid address.\n\n'
                          'You can move your funds to any wallet that can receive an on-chain Bitcoin '
                          'transaction, using an external service listed ',
                    ),
                    TextSpan(
                      text: 'here',
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () =>
                            ExternalBrowserService.launchLink(context, linkAddress: _moveFundsUrl),
                    ),
                    const TextSpan(
                      text:
                          '. We recommend Glow.\n\n'
                          'Those are external services, operated by third parties and not by Breez. Breez '
                          'does not endorse them. Use them at your own discretion.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('NOT NOW', style: actionStyle),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('GET GLOW', style: actionStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
