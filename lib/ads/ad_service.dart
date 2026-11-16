import 'package:flutter/widgets.dart';

/// Ads shown outside practice and papers: a banner on browsing screens and an
/// occasional interstitial when leaving a results screen. Never shown while a
/// question or paper is on screen.
abstract interface class AdService {
  /// Asks for consent where required, then starts the ad SDK.
  Future<void> start();

  /// A banner for the bottom of a browsing screen; empty when no ad is ready.
  Widget banner();

  /// Shows the full-screen ad after results, if the frequency cap allows.
  Future<void> showResultsInterstitial();

  /// True where the law requires a way to change ad consent (EEA, UK).
  Future<bool> privacyChoicesRequired();

  /// Opens the consent form so the user can change their choices.
  Future<void> showPrivacyChoices();
}

/// Used in tests, for store screenshots, and whenever ads are not wired in.
class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<void> start() async {}

  @override
  Widget banner() => const SizedBox.shrink();

  @override
  Future<void> showResultsInterstitial() async {}

  @override
  Future<bool> privacyChoicesRequired() async => false;

  @override
  Future<void> showPrivacyChoices() async {}
}
