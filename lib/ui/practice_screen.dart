import 'package:flutter/material.dart';

import '../app.dart';
import '../data/models.dart';
import 'question_view.dart';
import 'results_screen.dart';

/// One question at a time with instant marking and explanation.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  final String title;
  final List<Question> questions;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _index = 0;
  late final List<int?> _answers = List.filled(widget.questions.length, null);
  final _scroll = ScrollController();

  Question get _q => widget.questions[_index];
  int? get _chosen => _answers[_index];
  int get _score => [
    for (var i = 0; i < _answers.length; i++)
      if (_answers[i] == widget.questions[i].answer) 1,
  ].length;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = BankScope.of(context).bank;
    final total = widget.questions.length;
    final last = _index == total - 1;
    return PopScope(
      canPop: _answers.every((a) => a == null),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmLeave() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_index + 1) / total),
          ),
        ),
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              QuestionView(
                key: ValueKey(_q.id),
                question: _q,
                header: QuestionTag(
                  question: _q,
                  subName: bank.subtopic(_q.sub)?.name ?? '',
                  trailing: Text(
                    '${_index + 1} / $total   Score $_score',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                stateOf: (i) {
                  if (_chosen == null) return OptionState.idle;
                  if (i == _q.answer) {
                    return i == _chosen
                        ? OptionState.correct
                        : OptionState.missed;
                  }
                  return i == _chosen ? OptionState.wrong : OptionState.idle;
                },
                onSelect: _chosen == null
                    ? (i) => setState(() => _answers[_index] = i)
                    : null,
              ),
              if (_chosen != null) ...[
                const SizedBox(height: 8),
                ExplanationCard(question: _q, chosen: _chosen),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _index == 0 ? null : () => _go(_index - 1),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('next'),
                    onPressed: _chosen == null
                        ? null
                        : (last ? _finish : () => _go(_index + 1)),
                    child: Text(last ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    setState(() => _index = index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          title: widget.title,
          questions: widget.questions,
          answers: _answers,
        ),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final n = _answers.where((a) => a != null).length;
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('End practice?'),
        content: Text('You have answered $n question${n == 1 ? '' : 's'}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}
