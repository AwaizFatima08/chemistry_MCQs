import 'dart:io';

import 'package:igcse_chemistry_mcqs/data/models.dart';

/// The real bundled bank.
QuestionBank loadRealBank() => QuestionBank.fromJsonString(
  File('assets/data/bank.json').readAsStringSync(),
);

/// A small synthetic bank: 12 topics × 2 subtopics × [perSub] questions.
QuestionBank fakeBank({int perSub = 30}) {
  final topics = [
    for (var t = 1; t <= 12; t++)
      Topic(
        number: t,
        name: 'Topic $t',
        subtopics: [
          for (var s = 1; s <= 2; s++)
            Subtopic(code: '$t.$s', name: 'Sub $t.$s', topic: t),
        ],
      ),
  ];
  final questions = [
    for (final t in topics)
      for (final s in t.subtopics)
        for (var i = 0; i < perSub; i++)
          Question(
            id: 'u${t.number}-${s.code}-$i',
            topic: t.number,
            sub: s.code,
            level: i.isEven ? Level.core : Level.extended,
            text: 'Question ${s.code} #$i?',
            columns: i % 5 == 0 ? ['speed', 'direction'] : null,
            options: i % 5 == 0
                ? ['fast | left', 'fast | right', 'slow | left', 'slow | right']
                : ['opt A$i', 'opt B$i', 'opt C$i', 'opt D$i'],
            answer: i % 4,
            explanation: 'Because ${i % 4}.',
          ),
  ];
  return QuestionBank(topics: topics, questions: questions);
}
