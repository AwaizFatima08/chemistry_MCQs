/// Mock papers: 50 fixed papers of 20 questions for every scope (mixed or one
/// topic) and level. Papers are generated deterministically from the bank, so
/// "Mixed paper 7 (Extended)" is always the same set of questions.
library;

import 'models.dart';

const int papersPerScope = 50;
const int questionsPerPaper = 20;

/// Minutes allowed: Cambridge Papers 1/2 give 45 min for 40 questions.
const int paperMinutes = 23;

/// Mixed-paper questions per topic, roughly the weighting of Papers 1/2.
const Map<int, int> mixedQuota = {
  1: 1,
  2: 2,
  3: 1,
  4: 2,
  5: 1,
  6: 2,
  7: 2,
  8: 2,
  9: 2,
  10: 1,
  11: 2,
  12: 2,
};

class MockPaper {
  const MockPaper({
    required this.number,
    required this.topic,
    required this.level,
    required this.questions,
  });

  final int number;

  /// null for a mixed paper.
  final int? topic;
  final Level level;
  final List<Question> questions;
}

/// Small deterministic PRNG (mulberry32) so papers are identical on every device.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  int nextInt(int max) {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    t = (t ^ (t >> 14)) & 0xFFFFFFFF;
    return t % max;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

class PaperFactory {
  PaperFactory(this.bank);

  final QuestionBank bank;
  final Map<String, List<Question>> _streams = {};

  MockPaper paper({required int number, int? topic, required Level level}) {
    assert(number >= 1 && number <= papersPerScope);
    final picked = <Question>[];
    if (topic == null) {
      for (final MapEntry(key: t, value: n) in mixedQuota.entries) {
        picked.addAll(_take(t, level, (number - 1) * n, n));
      }
    } else {
      picked.addAll(
        _take(
          topic,
          level,
          (number - 1) * questionsPerPaper,
          questionsPerPaper,
        ),
      );
    }
    // Real papers follow syllabus order.
    picked.sort((a, b) {
      final c = bank.subOrder(a.sub).compareTo(bank.subOrder(b.sub));
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return MockPaper(
      number: number,
      topic: topic,
      level: level,
      questions: picked,
    );
  }

  /// [count] distinct questions starting at [offset] of the topic's stream: a
  /// series of seeded shuffles of the topic pool. Consecutive papers use
  /// consecutive slices, so questions only repeat once the pool is used up.
  List<Question> _take(int topic, Level level, int offset, int count) {
    final pool = bank.select(topic: topic, level: level);
    if (pool.isEmpty) return const [];
    final key = '$topic/${level.name}';
    final stream = _streams.putIfAbsent(key, () => []);
    final need = offset + count + pool.length;
    var cycle = stream.length ~/ pool.length;
    while (stream.length < need) {
      final copy = [...pool];
      SeededRandom(
        topic * 7919 + level.index * 104729 + cycle * 31337 + 1,
      ).shuffle(copy);
      stream.addAll(copy);
      cycle++;
    }
    final out = <Question>[];
    final seen = <String>{};
    for (var i = offset; out.length < count && out.length < pool.length; i++) {
      if (seen.add(stream[i].id)) out.add(stream[i]);
    }
    return out;
  }
}
