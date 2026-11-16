import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/ads/ad_service.dart';
import 'package:igcse_chemistry_mcqs/app.dart';

import 'fixtures.dart';

/// Records ad calls and shows a marker where a banner would be.
class _FakeAds implements AdService {
  int interstitials = 0;

  @override
  Future<void> start() async {}

  @override
  Widget banner() => const SizedBox(key: Key('banner'), height: 50);

  @override
  Future<void> showResultsInterstitial() async => interstitials++;

  @override
  Future<bool> privacyChoicesRequired() async => false;

  @override
  Future<void> showPrivacyChoices() async {}
}

void main() {
  late _FakeAds ads;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    ads = _FakeAds();
    await tester.pumpWidget(ChemistryMcqApp(bank: fakeBank(), ads: ads));
  }

  testWidgets('banners only on browsing screens, never on a paper', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('banner')), findsOneWidget); // home
    await tester.tap(find.byKey(const Key('home-mock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsOneWidget); // paper list
    await tester.tap(find.byKey(const Key('paper-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner')), findsNothing); // the paper itself
    expect(ads.interstitials, 0);
  });

  testWidgets('interstitial only when leaving results', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home-mock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paper-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('score')), findsOneWidget);
    expect(find.byKey(const Key('banner')), findsNothing); // results
    expect(ads.interstitials, 0);

    await tester.scrollUntilVisible(find.text('Home'), 300);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-mock')), findsOneWidget);
    expect(ads.interstitials, 1);
  });
}
