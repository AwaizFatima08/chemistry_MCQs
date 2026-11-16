import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/papers.dart';
import 'question_view.dart';
import 'results_screen.dart';

/// A mock paper: answer in any order, flag, change answers, submit to mark.
class ExamScreen extends StatefulWidget {
  const ExamScreen({
    super.key,
    required this.title,
    required this.paper,
    this.minutes,
  });

  final String title;
  final MockPaper paper;

  /// Time limit; null = untimed.
  final int? minutes;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _index = 0;
  late final List<int?> _answers = List.filled(
    widget.paper.questions.length,
    null,
  );
  final Set<int> _flags = {};
  final _started = DateTime.now();
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _done = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.minutes != null) {
      _left = Duration(minutes: widget.minutes!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final left =
        Duration(minutes: widget.minutes!) -
        DateTime.now().difference(_started);
    if (left <= Duration.zero) {
      _timer?.cancel();
      _submit(timeUp: true);
    } else {
      setState(() => _left = left);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = BankScope.of(context).bank;
    final qs = widget.paper.questions;
    final q = qs[_index];
    final answered = _answers.where((a) => a != null).length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirm(
              'Leave this paper?',
              'Your answers will not be saved.',
              'Leave',
            ) &&
            context.mounted) {
          _timer?.cancel();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            maxLines: 2,
            style: const TextStyle(fontSize: 16, height: 1.2),
          ),
          actions: [
            if (widget.minutes != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Text(
                    '${_left.inMinutes}:${(_left.inSeconds % 60).toString().padLeft(2, '0')}',
                    key: const Key('timer'),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.bold,
                      color: _left.inMinutes < 2
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: _flags.contains(_index)
                  ? 'Remove flag'
                  : 'Flag for review',
              icon: Icon(
                _flags.contains(_index) ? Icons.flag : Icons.outlined_flag,
              ),
              onPressed: () => setState(
                () => _flags.contains(_index)
                    ? _flags.remove(_index)
                    : _flags.add(_index),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _Navigator(
                count: qs.length,
                current: _index,
                answered: (i) => _answers[i] != null,
                flagged: _flags.contains,
                onTap: _go,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    QuestionView(
                      key: ValueKey(q.id),
                      question: q,
                      header: QuestionTag(
                        question: q,
                        subName: bank.subtopic(q.sub)?.name ?? '',
                        trailing: Text(
                          'Q${_index + 1} of ${qs.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      stateOf: (i) => _answers[_index] == i
                          ? OptionState.selected
                          : OptionState.idle,
                      onSelect: (i) => setState(
                        () =>
                            _answers[_index] = _answers[_index] == i ? null : i,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: _index == 0 ? null : () => _go(_index - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: const Key('exam-next'),
                  onPressed: _index == qs.length - 1
                      ? null
                      : () => _go(_index + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('submit'),
                    onPressed: () async {
                      final left = qs.length - answered;
                      final ok = await _confirm(
                        'Submit paper?',
                        left == 0
                            ? 'All questions answered.'
                            : '$left question${left == 1 ? '' : 's'} not answered.',
                        'Submit',
                      );
                      if (ok) _submit();
                    },
                    child: Text('Submit ($answered/${qs.length})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int i) {
    setState(() => _index = i);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  void _submit({bool timeUp = false}) {
    if (_done || !mounted) return;
    _done = true;
    _timer?.cancel();
    // Close a confirm dialog that may be open when time runs out.
    Navigator.of(context).popUntil((r) => r is PageRoute);
    if (timeUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time's up: paper submitted.")),
      );
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          title: widget.title,
          questions: widget.paper.questions,
          answers: _answers,
          timeTaken: DateTime.now().difference(_started),
        ),
      ),
    );
  }
}

/// Row of numbered chips: filled = answered, flag dot = flagged.
class _Navigator extends StatelessWidget {
  const _Navigator({
    required this.count,
    required this.current,
    required this.answered,
    required this.flagged,
    required this.onTap,
  });

  final int count;
  final int current;
  final bool Function(int) answered;
  final bool Function(int) flagged;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final isCurrent = i == current;
          final done = answered(i);
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(i),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: isCurrent
                        ? Border.all(color: scheme.tertiary, width: 3)
                        : null,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: done ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (flagged(i))
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Icon(Icons.flag, size: 16, color: scheme.error),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
