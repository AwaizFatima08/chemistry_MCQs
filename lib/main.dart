import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'ads/google_ad_service.dart';
import 'app.dart';
import 'data/models.dart';

/// `--dart-define=STORE_SHOTS=true` builds without ads, for store screenshots.
const _storeShots = bool.fromEnvironment('STORE_SHOTS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bank = QuestionBank.fromJsonString(
    await rootBundle.loadString('assets/data/bank.json'),
  );
  final AdService ads = _storeShots ? const NoAdService() : GoogleAdService();
  runApp(ChemistryMcqApp(bank: bank, ads: ads));
  unawaited(ads.start());
}
