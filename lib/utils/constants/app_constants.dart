export 'wordlist.dart';

/// Application-wide constants
///
/// This file contains constants that are used throughout the application.
/// Group related constants in their own class for better organization.

/// Payment Sheet timing constants for animations and transitions
class PaymentSheetTiming {
  /// Private constructor to prevent instantiation
  PaymentSheetTiming._();

  /// Delay before popping the payment sheet
  static const Duration popDelay = Duration(milliseconds: 2250);
}

/// Network-related constants
class NetworkConstants {
  /// Private constructor to prevent instantiation
  NetworkConstants._();

  /// Default Liquid Mempool instance URL
  static const String defaultLiquidMempoolInstance = 'https://liquid.network/';

  /// Default Mempool instance URL
  static const String defaultBitcoinMempoolInstance = 'https://mempool.space/';
}

/// Payment-related constants
class PaymentConstants {
  /// Private constructor to prevent instantiation
  PaymentConstants._();

  /// Bitcoin satoshis per BTC
  static const int satoshisPerBitcoin = 100000000;

  /// Default description used on Bolt 12 Offers.
  static const String bolt12OfferDescription = 'Pay to Misty Breez';
}

/// Block times for different blockchains in seconds
class BlockTimes {
  /// Private constructor to prevent instantiation
  BlockTimes._();

  /// Average time between Bitcoin blocks in seconds (10 minutes)
  static const int bitcoinBlockTimeSeconds = 600;

  /// Average time between Liquid blocks in seconds (1 minute)
  static const int liquidBlockTimeSeconds = 60;
}

/// Time conversion constants
class TimeConstants {
  TimeConstants._();

  /// Minutes in a day (24 * 60)
  static const int minutesPerDay = 1440;
}

/// Swap service outage, in effect while the swapper refuses to create swaps.
///
/// Gates the startup notice and the home app bar warning. Flip to false when swaps work
/// again and both disappear.
class ServiceOutage {
  /// Private constructor to prevent instantiation
  ServiceOutage._();

  /// Whether on-chain and Lightning payments are unavailable.
  // ponytail: a const, not cubit state. Nothing exposes swapper availability, and the outage
  // is global. Wire it to real state if it ever needs to vary per user or resolve at runtime.
  static const bool swapsUnavailable = true;
}

class WebhookConstants {
  /// Private constructor to prevent instantiation
  WebhookConstants._();

  /// Base URL for the notification service.
  static const String notifierServiceURL = 'https://notifier.breez.technology';

  /// NWC endpoint for the webhook registration
  static const String breezWebhooksURL = 'https://breez.fun';
}
