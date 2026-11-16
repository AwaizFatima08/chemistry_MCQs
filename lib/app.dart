import 'package:flutter/material.dart';

import 'ads/ad_service.dart';
import 'data/models.dart';
import 'data/papers.dart';
import 'ui/home_screen.dart';

const appTitle = 'IGCSE Chemistry MCQs';

/// Gives every screen the question bank, the paper factory and the ads.
class BankScope extends InheritedWidget {
  const BankScope({
    super.key,
    required this.bank,
    required this.papers,
    required this.ads,
    required super.child,
  });

  final QuestionBank bank;
  final PaperFactory papers;
  final AdService ads;

  static BankScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BankScope>()!;

  @override
  bool updateShouldNotify(BankScope oldWidget) => bank != oldWidget.bank;
}

class ChemistryMcqApp extends StatelessWidget {
  const ChemistryMcqApp({
    super.key,
    required this.bank,
    this.ads = const NoAdService(),
  });

  final QuestionBank bank;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    return BankScope(
      bank: bank,
      papers: PaperFactory(bank),
      ads: ads,
      child: MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E5AA8),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}

/// Topic colours used on cards and chips.
Color topicColor(int topic, Brightness brightness) {
  const light = [
    Color(0xFF1E5AA8), // states of matter
    Color(0xFF0E7490), // atoms, elements and compounds
    Color(0xFF7C3AED), // stoichiometry
    Color(0xFFB45309), // electrochemistry
    Color(0xFFC2410C), // chemical energetics
    Color(0xFF15803D), // chemical reactions
    Color(0xFFBE123C), // acids, bases and salts
    Color(0xFF4338CA), // periodic table
    Color(0xFF475569), // metals
    Color(0xFF0F766E), // environment
    Color(0xFF9333EA), // organic chemistry
    Color(0xFF854D0E), // experimental techniques
  ];
  const dark = [
    Color(0xFF8AB4F8),
    Color(0xFF67E8F9),
    Color(0xFFC4B5FD),
    Color(0xFFFCD34D),
    Color(0xFFFDBA74),
    Color(0xFF86EFAC),
    Color(0xFFFDA4AF),
    Color(0xFFA5B4FC),
    Color(0xFFCBD5E1),
    Color(0xFF5EEAD4),
    Color(0xFFD8B4FE),
    Color(0xFFFDE68A),
  ];
  return (brightness == Brightness.dark ? dark : light)[(topic - 1) %
      light.length];
}

IconData topicIcon(int topic) => const [
  Icons.ac_unit,
  Icons.scatter_plot,
  Icons.calculate,
  Icons.battery_charging_full,
  Icons.local_fire_department,
  Icons.swap_horiz,
  Icons.science,
  Icons.grid_view,
  Icons.hardware,
  Icons.eco,
  Icons.bubble_chart,
  Icons.biotech,
][(topic - 1) % 12];
