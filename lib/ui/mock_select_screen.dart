import 'package:flutter/material.dart';

import '../app.dart';
import '../data/models.dart';
import '../data/papers.dart';
import 'exam_screen.dart';

/// Choose mixed or a topic, the level, then one of 50 papers.
class MockSelectScreen extends StatefulWidget {
  const MockSelectScreen({super.key});

  @override
  State<MockSelectScreen> createState() => _MockSelectScreenState();
}

class _MockSelectScreenState extends State<MockSelectScreen> {
  int? _topic; // null = mixed
  Level _level = Level.extended;
  bool _timed = true;

  @override
  Widget build(BuildContext context) {
    final bank = BankScope.of(context).bank;
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: BankScope.of(context).ads.banner(),
      appBar: AppBar(title: const Text('Mock papers')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(
                children: [
                  Text('Paper type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    key: const Key('scope'),
                    initialValue: _topic,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Mixed: all topics'),
                      ),
                      for (final t in bank.topics)
                        DropdownMenuItem(
                          value: t.number,
                          child: Text('Topic ${t.number}: ${t.name}'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _topic = v),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<Level>(
                    segments: const [
                      ButtonSegment(
                        value: Level.core,
                        label: Text('Core (Paper 1)'),
                      ),
                      ButtonSegment(
                        value: Level.extended,
                        label: Text('Extended (Paper 2)'),
                      ),
                    ],
                    selected: {_level},
                    onSelectionChanged: (s) => setState(() => _level = s.first),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Timed'),
                    subtitle: const Text(
                      '$paperMinutes minutes for $questionsPerPaper questions, as in the exam',
                    ),
                    value: _timed,
                    onChanged: (v) => setState(() => _timed = v),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _topic == null
                        ? 'Each mixed paper has questions from all twelve topics, weighted like the real paper.'
                        : 'Each paper has $questionsPerPaper questions from ${bank.topic(_topic!).name}.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 76,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: papersPerScope,
                itemBuilder: (context, i) => FilledButton.tonal(
                  key: Key('paper-${i + 1}'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _open(i + 1),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(int number) {
    final scope = BankScope.of(context);
    final paper = scope.papers.paper(
      number: number,
      topic: _topic,
      level: _level,
    );
    final name = _topic == null ? 'Mixed' : 'Topic $_topic';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamScreen(
          title: '$name paper $number (${_level.label})',
          paper: paper,
          minutes: _timed ? paperMinutes : null,
        ),
      ),
    );
  }
}
