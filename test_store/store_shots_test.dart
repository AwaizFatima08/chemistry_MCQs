// Renders the Play Store phone screenshots from the real app screens, without ads.
// Run: flutter test test_store/store_shots_test.dart  → store-assets/screenshots/phone/
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/app.dart';
import 'package:igcse_chemistry_mcqs/data/models.dart';
import 'package:igcse_chemistry_mcqs/data/papers.dart';
import 'package:igcse_chemistry_mcqs/ui/exam_screen.dart';
import 'package:igcse_chemistry_mcqs/ui/home_screen.dart';
import 'package:igcse_chemistry_mcqs/ui/practice_screen.dart';
import 'package:igcse_chemistry_mcqs/ui/results_screen.dart';
import 'package:igcse_chemistry_mcqs/ui/topics_screen.dart';

const _fonts =
    '/mnt/storage/projects/flutter/bin/cache/artifacts/material_fonts';
const _out = 'store-assets/screenshots/phone';

Future<void> _loadFonts() async {
  Future<ByteData> f(String name) async =>
      ByteData.sublistView(File('$_fonts/$name').readAsBytesSync());
  final roboto = FontLoader('Roboto')
    ..addFont(f('Roboto-Regular.ttf'))
    ..addFont(f('Roboto-Medium.ttf'))
    ..addFont(f('Roboto-Bold.ttf'));
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(f('MaterialIcons-Regular.otf'))).load();
}

void main() {
  late QuestionBank bank;
  final boundary = GlobalKey();

  setUpAll(() async {
    await _loadFonts();
    bank = QuestionBank.fromJsonString(
      File('assets/data/bank.json').readAsStringSync(),
    );
    Directory(_out).createSync(recursive: true);
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ChemistryMcqApp(bank: bank),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final ro =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await ro.toImage(pixelRatio: 2.625);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  NavigatorState nav(WidgetTester tester) =>
      Navigator.of(tester.element(find.byType(HomeScreen)));

  Question q(String id) => bank.questions.firstWhere((q) => q.id == id);

  testWidgets('01 home', (tester) async {
    await start(tester);
    await shot(tester, '01-home');
  });

  testWidgets('02 topic setup', (tester) async {
    await start(tester);
    nav(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicSetupScreen(topic: bank.topic(11)),
      ),
    );
    await tester.pumpAndSettle();
    await shot(tester, '02-topic-setup');
  });

  testWidgets('03 practice with explanation', (tester) async {
    await start(tester);
    // A question with no formula characters: the test renderer's Roboto lacks
    // subscripts and arrows, which phones draw from their system fonts.
    final question = q('c11-0065');
    nav(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          title: 'Organic chemistry',
          questions: [question, q('c11-0100'), q('c11-0056')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('option-${question.answer}')));
    await tester.pumpAndSettle();
    await shot(tester, '03-practice-explained');
  });

  testWidgets('04 table question', (tester) async {
    await start(tester);
    final question = q('c1-0106');
    nav(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(
          title: 'States of matter',
          questions: [question, q('c1-0046')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('option-${(question.answer + 1) % 4}')));
    await tester.pumpAndSettle();
    await shot(tester, '04-practice-table');
  });

  testWidgets('05 mock papers', (tester) async {
    await start(tester);
    await tester.tap(find.byKey(const Key('home-mock')));
    await tester.pumpAndSettle();
    await shot(tester, '05-mock-papers');
  });

  testWidgets('06 exam', (tester) async {
    await start(tester);
    final paper = PaperFactory(
      bank,
    ).paper(number: 7, topic: null, level: Level.extended);
    nav(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamScreen(
          title: 'Mixed paper 7 (Extended)',
          paper: paper,
          minutes: paperMinutes,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(Key('option-${paper.questions[i].answer}')));
      await tester.pump();
      if (i == 2) {
        await tester.tap(find.byTooltip('Flag for review'));
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('exam-next')));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '06-mock-exam');
  });

  testWidgets('07 results and 08 review', (tester) async {
    await start(tester);
    final paper = PaperFactory(
      bank,
    ).paper(number: 7, topic: null, level: Level.extended);
    final answers = [
      for (var i = 0; i < paper.questions.length; i++)
        // 16 right, 3 wrong, 1 blank.
        i == 19
            ? null
            : (i % 6 == 4
                  ? (paper.questions[i].answer + 1) % 4
                  : paper.questions[i].answer),
    ];
    nav(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          title: 'Mixed paper 7 (Extended)',
          questions: paper.questions,
          answers: answers,
          timeTaken: const Duration(minutes: 18, seconds: 42),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await shot(tester, '07-results');

    // Open a wrong answer (i % 6 == 4) whose text has no formula characters,
    // which the test renderer's Roboto cannot draw.
    bool plain(Question q) =>
        '${q.text}${q.options.join()}'.codeUnits.every((c) => c < 128);
    final wrong = [4, 10, 16].firstWhere((i) => plain(paper.questions[i]));
    final tile = find.textContaining('Q${wrong + 1}. ');
    await tester.scrollUntilVisible(tile, 300);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    // Bring the opened question to just below the app bar.
    final dy = tester.getTopLeft(tile).dy;
    await tester.drag(find.byType(ListView), Offset(0, -(dy - 110)));
    await tester.pumpAndSettle();
    await shot(tester, '08-review');
  });
}
