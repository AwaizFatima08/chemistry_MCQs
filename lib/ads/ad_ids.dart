import 'package:flutter/foundation.dart';

/// AdMob identifiers. Debug builds always use Google's published test units
/// so a developer never clicks a live ad.
abstract final class AdIds {
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Release units for this app are not created yet (AdMob account homilabs.smc@gmail.com).
  // Until they exist these are Google's test units, and scripts/check-release-ad-ids.sh
  // refuses to release while they are still here. Replace with the ids in config/admob.json.
  static const _liveBanner = _testBanner;
  static const _liveInterstitial = _testInterstitial;

  static String get banner => kReleaseMode ? _liveBanner : _testBanner;
  static String get interstitial =>
      kReleaseMode ? _liveInterstitial : _testInterstitial;
}
