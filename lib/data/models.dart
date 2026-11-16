/// Question bank models, loaded from `assets/data/bank.json`
/// (built by `tools/build_bank.py`).
library;

import 'dart:convert';

enum Level {
  /// Core content only (Paper 1 style).
  core,

  /// Core + Supplement content (Paper 2 style).
  extended;

  String get label => this == core ? 'Core' : 'Extended';
}

class Subtopic {
  const Subtopic({required this.code, required this.name, required this.topic});

  final String code;
  final String name;
  final int topic;
}

class Topic {
  const Topic({
    required this.number,
    required this.name,
    required this.subtopics,
  });

  final int number;
  final String name;
  final List<Subtopic> subtopics;
}

class Question {
  const Question({
    required this.id,
    required this.topic,
    required this.sub,
    required this.level,
    required this.text,
    required this.columns,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['id'] as String,
    topic: j['topic'] as int,
    sub: j['sub'] as String,
    level: j['level'] == 'core' ? Level.core : Level.extended,
    text: j['q'] as String,
    columns: (j['columns'] as List?)?.cast<String>(),
    options: (j['options'] as List).cast<String>(),
    answer: j['answer'] as int,
    explanation: j['explain'] as String,
  );

  final String id;
  final int topic;
  final String sub;

  /// [Level.core] questions use Core content; [Level.extended] ones need Supplement.
  final Level level;
  final String text;

  /// Headings for a "Which row is correct?" question; null otherwise.
  final List<String>? columns;
  final List<String> options;
  final int answer;
  final String explanation;

  bool get isTable => columns != null;

  /// Option cells for table questions (one list per option).
  List<String> cells(int option) => options[option].split(' | ');

  /// Whether this question belongs on a paper of [level].
  bool fits(Level level) => level == Level.extended || this.level == Level.core;
}

class QuestionBank {
  QuestionBank({required this.topics, required this.questions}) {
    for (final t in topics) {
      for (final s in t.subtopics) {
        _subOrder[s.code] = _subOrder.length;
        _subs[s.code] = s;
      }
    }
  }

  factory QuestionBank.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final topics = [
      for (final t in (j['topics'] as List).cast<Map<String, dynamic>>())
        Topic(
          number: t['n'] as int,
          name: t['name'] as String,
          subtopics: [
            for (final s in (t['subs'] as List).cast<Map<String, dynamic>>())
              Subtopic(
                code: s['code'] as String,
                name: s['name'] as String,
                topic: t['n'] as int,
              ),
          ],
        ),
    ];
    final questions = [
      for (final q in (j['questions'] as List).cast<Map<String, dynamic>>())
        Question.fromJson(q),
    ];
    return QuestionBank(topics: topics, questions: questions);
  }

  final List<Topic> topics;
  final List<Question> questions;
  final Map<String, int> _subOrder = {};
  final Map<String, Subtopic> _subs = {};

  Topic topic(int number) => topics.firstWhere((t) => t.number == number);

  Subtopic? subtopic(String code) => _subs[code];

  /// Syllabus position of a subtopic, used to order paper questions.
  int subOrder(String code) => _subOrder[code] ?? 1 << 20;

  List<Question> select({
    int? topic,
    Set<String>? subs,
    Level level = Level.extended,
  }) => [
    for (final q in questions)
      if ((topic == null || q.topic == topic) &&
          (subs == null || subs.contains(q.sub)) &&
          q.fits(level))
        q,
  ];

  int count({int? topic, String? sub, Level level = Level.extended}) => select(
    topic: topic,
    subs: sub == null ? null : {sub},
    level: level,
  ).length;
}
