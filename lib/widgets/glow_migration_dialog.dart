import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/services/services.dart';

final Logger _logger = Logger('GlowMigrationDialog');

const String _glowAppStoreUrl = 'https://apps.apple.com/us/app/glow-lightning-fast-bitcoin/id6762465698';
const String _glowPlayStoreUrl = 'https://play.google.com/store/apps/details?id=technology.breez.glow';

/// Page listing the third-party services that can move funds out of this wallet.
/// Deliberately a link instead of an in-app list, so the options can be changed
/// without shipping a new app version.
const String _moveFundsUrl = 'https://breez.technology/misty/move-funds.html';

/// Notice shown once per app launch while the swap service is unavailable.
///
/// Copy is hardcoded English, as ExceptionHandler's swap messages are: Breez-Translations is
/// pinned to a git ref, and a temporary notice is not worth the round-trip.
Future<void> showGlowMigrationDialog(BuildContext context) async {
  final ThemeData themeData = Theme.of(context);

  _logger.info('Showing Glow migration notice');

  final bool? getGlow = await showDialog<bool>(
    useRootNavigator: false,
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
        title: const Text('On-chain and Lightning are unavailable'),
        content: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
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
                        ExternalBrowserService.launchLink(dialogContext, linkAddress: _moveFundsUrl),
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
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('NOT NOW', style: themeData.primaryTextTheme.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('GET GLOW', style: themeData.primaryTextTheme.labelLarge),
          ),
        ],
      );
    },
  );

  if (getGlow == true && context.mounted) {
    await ExternalBrowserService.launchLink(
      context,
      linkAddress: Platform.isIOS ? _glowAppStoreUrl : _glowPlayStoreUrl,
    );
  }
}
