import 'package:flutter/material.dart';

import '../data/models.dart';

const letters = ['A', 'B', 'C', 'D'];

/// How an option is drawn.
enum OptionState { idle, selected, correct, wrong, missed }

/// Stem plus the four options (as buttons or as table rows).
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.stateOf,
    this.onSelect,
    this.header,
  });

  final Question question;
  final OptionState Function(int option) stateOf;
  final ValueChanged<int>? onSelect;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        SelectableText(
          question.text,
          style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        if (question.isTable) _tableHeader(context),
        for (var i = 0; i < 4; i++) ...[
          _OptionTile(
            key: Key('option-$i'),
            letter: letters[i],
            cells: question.isTable ? question.cells(i) : [question.options[i]],
            state: stateOf(i),
            onTap: onSelect == null ? null : () => onSelect!(i),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _tableHeader(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 12, bottom: 6),
      child: Row(
        children: [
          for (final c in question.columns!)
            Expanded(child: Text(c, style: style)),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.letter,
    required this.cells,
    required this.state,
    this.onTap,
  });

  final String letter;
  final List<String> cells;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final green = dark ? const Color(0xFF2E7D32) : const Color(0xFFDFF3E3);
    final red = dark ? const Color(0xFF8E2A2A) : const Color(0xFFFBE0E0);
    final (Color bg, Color border, IconData? icon) = switch (state) {
      OptionState.idle => (
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        null,
      ),
      OptionState.selected => (scheme.primaryContainer, scheme.primary, null),
      OptionState.correct => (
        green,
        const Color(0xFF2E7D32),
        Icons.check_circle,
      ),
      OptionState.wrong => (red, const Color(0xFFC62828), Icons.cancel),
      OptionState.missed => (
        green,
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
    };
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: border,
          width: state == OptionState.idle ? 1 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: state == OptionState.idle
                    ? scheme.secondaryContainer
                    : border,
                foregroundColor: state == OptionState.idle
                    ? scheme.onSecondaryContainer
                    : Colors.white,
                child: Text(
                  letter,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              for (final c in cells)
                Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 16, height: 1.3),
                  ),
                ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Explanation box shown after answering.
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    required this.question,
    required this.chosen,
  });

  final Question question;
  final int? chosen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final right = chosen == question.answer;
    final title = chosen == null
        ? 'Not answered. Correct answer: ${letters[question.answer]}'
        : right
        ? 'Correct'
        : 'Incorrect. Correct answer: ${letters[question.answer]}';
    return Container(
      key: const Key('explanation'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: right ? const Color(0xFF2E7D32) : scheme.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(question.explanation, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

/// Small "1.2 Diffusion · Core" label above a question.
class QuestionTag extends StatelessWidget {
  const QuestionTag({
    super.key,
    required this.question,
    required this.subName,
    this.trailing,
  });

  final Question question;
  final String subName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${question.sub} $subName · ${question.level.label}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
