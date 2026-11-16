import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/data/models.dart';
import 'package:igcse_chemistry_mcqs/data/papers.dart';

import 'fixtures.dart';

void main() {
  late QuestionBank bank;
  setUpAll(() => bank = loadRealBank());

  for (final level in Level.values) {
    for (final topic in <int?>[null, for (var n = 1; n <= 12; n++) n]) {
      test(
        '50 papers × 20 distinct questions: topic=${topic ?? 'mixed'} ${level.name}',
        () {
          final factory = PaperFactory(bank);
          for (var n = 1; n <= papersPerScope; n++) {
            final p = factory.paper(number: n, topic: topic, level: level);
            expect(
              p.questions,
              hasLength(questionsPerPaper),
              reason: 'paper $n',
            );
            expect(
              p.questions.map((q) => q.id).toSet(),
              hasLength(questionsPerPaper),
              reason: 'paper $n',
            );
            for (final q in p.questions) {
              if (topic != null) expect(q.topic, topic);
              expect(q.fits(level), isTrue);
            }
            // Syllabus order.
            final order = [for (final q in p.questions) bank.subOrder(q.sub)];
            expect(order, [...order]..sort());
          }
        },
      );
    }
  }

  test('mixed papers follow the topic quota', () {
    final p = PaperFactory(bank).paper(number: 3, level: Level.extended);
    for (final MapEntry(key: t, value: n) in mixedQuota.entries) {
      expect(p.questions.where((q) => q.topic == t), hasLength(n));
    }
  });

  test('the 50 mixed extended papers never repeat a question', () {
    final factory = PaperFactory(bank);
    final ids = <String>[];
    for (var n = 1; n <= papersPerScope; n++) {
      ids.addAll(
        factory
            .paper(number: n, level: Level.extended)
            .questions
            .map((q) => q.id),
      );
    }
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('topic papers use the whole pool before repeating', () {
    final factory = PaperFactory(bank);
    final pool = bank.count(topic: 5);
    final seen = <String>{};
    for (var n = 1; n * questionsPerPaper <= pool; n++) {
      for (final q
          in factory
              .paper(number: n, topic: 5, level: Level.extended)
              .questions) {
        expect(seen.add(q.id), isTrue, reason: 'repeat in paper $n');
      }
    }
  });

  test('papers are deterministic', () {
    final a = PaperFactory(bank).paper(number: 17, topic: 3, level: Level.core);
    final b = PaperFactory(bank).paper(number: 17, topic: 3, level: Level.core);
    expect(a.questions.map((q) => q.id), b.questions.map((q) => q.id));
    final c = PaperFactory(bank).paper(number: 18, topic: 3, level: Level.core);
    expect(c.questions.map((q) => q.id), isNot(a.questions.map((q) => q.id)));
  });

  test('seeded random is stable', () {
    List<int> run(int seed) {
      final r = SeededRandom(seed);
      return [for (var i = 0; i < 50; i++) r.nextInt(1000)];
    }

    expect(run(42), run(42));
    expect(run(42), isNot(run(43)));
    expect(run(42).every((v) => v >= 0 && v < 1000), isTrue);
    expect(run(42).toSet().length, greaterThan(40));
  });

  test('fake bank papers work too', () {
    final p = PaperFactory(fakeBank()).paper(number: 50, level: Level.core);
    expect(p.questions, hasLength(questionsPerPaper));
  });
}
