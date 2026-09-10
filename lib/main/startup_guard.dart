import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/widgets/error_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('StartupGuard');

const String _unfinishedLaunchesKey = 'unfinished_launches';
const int _maxUnfinishedLaunches = 2;
const Duration _startupGracePeriod = Duration(seconds: 10);

/// Whether this launch skipped connecting to the SDK, see [shouldConnectOnStartup].
bool startedWithoutSdk = false;

/// Returns false when the previous launches died during startup, so this one opens offline.
///
/// The SDK is built with panic = "abort", so a Rust panic kills the app and nothing on the Dart
/// side can catch it. When wallet data triggers one on every launch, the app closes within
/// seconds and the recovery phrase and logs are out of reach. Skipping the connect keeps both
/// reachable.
Future<bool> shouldConnectOnStartup() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int unfinishedLaunches = prefs.getInt(_unfinishedLaunchesKey) ?? 0;
  if (unfinishedLaunches >= _maxUnfinishedLaunches) {
    _logger.warning('The last $unfinishedLaunches launches ended during startup. Not connecting.');
    // Cleared, so the next launch connects again, e.g. once an update fixes the crash.
    await prefs.remove(_unfinishedLaunchesKey);
    startedWithoutSdk = true;
    return false;
  }

  await prefs.setInt(_unfinishedLaunchesKey, unfinishedLaunches + 1);
  // ponytail: a launch survived if it stayed up for the grace period or reached the background,
  // which a startup crash does neither of. Crashes after the grace period are not counted.
  Timer(_startupGracePeriod, markLaunchFinished);
  AppLifecycleListener(onHide: markLaunchFinished);
  return true;
}

/// Marks this launch as survived. Exiting on purpose must call it, or the exit counts as a crash.
Future<void> markLaunchFinished() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(_unfinishedLaunchesKey);
}

/// Explains why the wallet is offline, and where the recovery phrase and logs are.
///
/// Copy is hardcoded English, as the service outage notice is.
Future<void> showStartedWithoutSdkNotice(BuildContext context) async {
  if (!startedWithoutSdk) {
    return;
  }

  await promptError(
    context,
    title: 'Started without connecting',
    body: const Text(
      'Misty Breez closed unexpectedly the last 2 times it started, so this time it did not '
      'connect. Your funds are safe.\n\n'
      'Back up your recovery phrase now from Menu > Preferences > Security & Backup, and send your '
      'logs to support from Menu > Preferences > Developers > Logs.\n\n'
      'Restart the app to connect again.',
    ),
  );
}
