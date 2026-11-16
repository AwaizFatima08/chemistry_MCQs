import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/app.dart';

import 'fixtures.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChemistryMcqApp(bank: fakeBank()));
  }

  testWidgets('home shows both modes and every topic', (tester) async {
    await pumpApp(tester);
    expect(find.text('Topic practice'), findsOneWidget);
    expect(find.text('Mock papers'), findsOneWidget);
    for (var t = 1; t <= 12; t++) {
      await tester.scrollUntilVisible(find.text('$t  Topic $t'), 100);
      expect(find.text('$t  Topic $t'), findsOneWidget);
    }
  });

  testWidgets('topic practice: answer, see explanation, finish with a score', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home-practice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topic-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-practice')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      expect(find.byKey(const Key('explanation')), findsNothing);
      await tester.tap(find.byKey(const Key('option-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explanation')), findsOneWidget);
      await tester.tap(find.byKey(const Key('next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('score')), findsOneWidget);
    expect(find.textContaining('/ 10'), findsWidgets);
  });

  testWidgets('mock paper: answer some, submit, see results', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home-mock')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paper-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timer')), findsOneWidget);
    expect(find.text('Submit (0/20)'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('option-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('exam-next')));
      await tester.pump();
    }
    expect(find.text('Submit (5/20)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('15 questions not answered.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('score')), findsOneWidget);
    expect(find.textContaining('15 not answered'), findsOneWidget);
  });

  testWidgets('table questions show column headings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('home-practice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topic-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shuffle questions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-practice')));
    await tester.pumpAndSettle();
    // First fake question (i = 0) is a table question.
    expect(find.text('speed'), findsOneWidget);
    expect(find.text('direction'), findsOneWidget);
  });
}
