import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/data/models.dart';

import 'fixtures.dart';

void main() {
  late QuestionBank bank;
  setUpAll(() => bank = loadRealBank());

  test('twelve syllabus topics, each with at least 100 questions', () {
    expect(bank.topics.map((t) => t.number), [for (var n = 1; n <= 12; n++) n]);
    for (final t in bank.topics) {
      expect(
        bank.count(topic: t.number),
        greaterThanOrEqualTo(100),
        reason: t.name,
      );
    }
  });

  test('every subtopic has questions', () {
    for (final t in bank.topics) {
      for (final s in t.subtopics) {
        expect(
          bank.count(sub: s.code),
          greaterThan(0),
          reason: '${s.code} ${s.name}',
        );
      }
    }
  });

  test('questions are well formed', () {
    final ids = <String>{};
    for (final q in bank.questions) {
      expect(ids.add(q.id), isTrue, reason: 'duplicate ${q.id}');
      expect(q.options, hasLength(4), reason: q.id);
      expect(q.answer, inInclusiveRange(0, 3), reason: q.id);
      expect(bank.subtopic(q.sub)?.topic, q.topic, reason: q.id);
      expect(q.text.trim(), isNotEmpty, reason: q.id);
      expect(q.explanation.trim(), isNotEmpty, reason: q.id);
      if (q.isTable) {
        for (var i = 0; i < 4; i++) {
          expect(q.cells(i), hasLength(q.columns!.length), reason: q.id);
        }
      }
    }
  });

  test('answer letters are reasonably balanced', () {
    final counts = List.filled(4, 0);
    for (final q in bank.questions) {
      counts[q.answer]++;
    }
    for (final c in counts) {
      expect(
        c / bank.questions.length,
        inInclusiveRange(0.18, 0.32),
        reason: '$counts',
      );
    }
  });

  test('both levels are represented in every topic', () {
    for (final t in bank.topics) {
      final core = bank.count(topic: t.number, level: Level.core);
      expect(core, greaterThanOrEqualTo(60), reason: t.name);
      expect(
        bank.count(topic: t.number) - core,
        greaterThanOrEqualTo(40),
        reason: t.name,
      );
    }
  });
}
