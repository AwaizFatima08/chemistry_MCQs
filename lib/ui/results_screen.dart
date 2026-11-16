import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/models.dart';
import 'question_view.dart';

/// Score summary plus a review of every question.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.answers,
    this.timeTaken,
    this.onRetry,
  });

  final String title;
  final List<Question> questions;
  final List<int?> answers;
  final Duration? timeTaken;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scope = BankScope.of(context);
    final bank = scope.bank;
    final theme = Theme.of(context);
    final score = [
      for (var i = 0; i < questions.length; i++)
        if (answers[i] == questions[i].answer) 1,
    ].length;
    final unanswered = answers.where((a) => a == null).length;
    final pct = questions.isEmpty
        ? 0
        : (100 * score / questions.length).round();

    // Score by subtopic, in syllabus order.
    final bySub = <String, (int, int)>{};
    for (var i = 0; i < questions.length; i++) {
      final (r, n) = bySub[questions[i].sub] ?? (0, 0);
      bySub[questions[i].sub] = (
        r + (answers[i] == questions[i].answer ? 1 : 0),
        n + 1,
      );
    }
    final subs = bySub.keys.toList()
      ..sort((a, b) => bank.subOrder(a).compareTo(bank.subOrder(b)));

    // Leaving results (back or Home) is the one natural break for a full-screen ad.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(scope.ads.showResultsInterstitial());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score / ${questions.length}',
                        key: const Key('score'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text('$pct%', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(_verdict(pct), textAlign: TextAlign.center),
                      if (unanswered > 0 || timeTaken != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (unanswered > 0) '$unanswered not answered',
                            if (timeTaken != null) 'time ${_fmt(timeTaken!)}',
                          ].join(' · '),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('By subtopic', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final s in subs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('$s ${bank.subtopic(s)?.name ?? ''}'),
                  trailing: Text('${bySub[s]!.$1} / ${bySub[s]!.$2}'),
                ),
              const Divider(height: 32),
              Text('Review', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              for (var i = 0; i < questions.length; i++)
                _ReviewTile(
                  number: i + 1,
                  question: questions[i],
                  chosen: answers[i],
                ),
              const SizedBox(height: 16),
              if (onRetry != null)
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay),
                  label: const Text('Try again'),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _verdict(int pct) => switch (pct) {
    >= 80 => 'Excellent: exam ready on these questions.',
    >= 60 => 'Good. Review the ones you missed.',
    >= 40 => 'Getting there. Revise the weaker subtopics below.',
    _ => 'Keep practising. Read each explanation carefully.',
  };

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.chosen,
  });

  final int number;
  final Question question;
  final int? chosen;

  @override
  Widget build(BuildContext context) {
    final right = chosen == question.answer;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(
          chosen == null
              ? Icons.remove_circle_outline
              : (right ? Icons.check_circle : Icons.cancel),
          color: chosen == null
              ? Colors.grey
              : (right ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
        ),
        title: Text(
          'Q$number. ${question.text}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Your answer: ${chosen == null ? '–' : letters[chosen!]}   Correct: ${letters[question.answer]}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          QuestionView(
            question: question,
            stateOf: (i) {
              if (i == question.answer) {
                return i == chosen ? OptionState.correct : OptionState.missed;
              }
              return i == chosen ? OptionState.wrong : OptionState.idle;
            },
          ),
          ExplanationCard(question: question, chosen: chosen),
        ],
      ),
    );
  }
}
