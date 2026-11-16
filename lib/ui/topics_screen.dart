import 'package:flutter/material.dart';

import '../app.dart';
import '../data/models.dart';
import 'practice_screen.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = BankScope.of(context).bank;
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: BankScope.of(context).ads.banner(),
      appBar: AppBar(title: const Text('Topic practice')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bank.topics.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final t = bank.topics[i];
            final color = topicColor(t.number, theme.brightness);
            return Card(
              key: Key('topic-${t.number}'),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(topicIcon(t.number)),
                ),
                title: Text(
                  '${t.number}. ${t.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${t.subtopics.length} subtopics · ${bank.count(topic: t.number)} questions',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TopicSetupScreen(topic: t),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pick subtopics, level and length before a practice session.
class TopicSetupScreen extends StatefulWidget {
  const TopicSetupScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<TopicSetupScreen> createState() => _TopicSetupScreenState();
}

class _TopicSetupScreenState extends State<TopicSetupScreen> {
  late final Set<String> _subs = {
    for (final s in widget.topic.subtopics) s.code,
  };
  Level _level = Level.extended;
  int _length = 20; // 0 = all
  bool _shuffle = true;

  @override
  Widget build(BuildContext context) {
    final bank = BankScope.of(context).bank;
    final available = bank
        .select(topic: widget.topic.number, subs: _subs, level: _level)
        .length;
    final allSelected = _subs.length == widget.topic.subtopics.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topic.number}. ${widget.topic.name}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Level', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Level>(
              segments: const [
                ButtonSegment(value: Level.core, label: Text('Core only')),
                ButtonSegment(
                  value: Level.extended,
                  label: Text('Core + Extended'),
                ),
              ],
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtopics',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (allSelected) {
                      _subs.clear();
                    } else {
                      _subs.addAll(widget.topic.subtopics.map((s) => s.code));
                    }
                  }),
                  child: Text(allSelected ? 'Clear all' : 'Select all'),
                ),
              ],
            ),
            for (final s in widget.topic.subtopics)
              CheckboxListTile(
                key: Key('sub-${s.code}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _subs.contains(s.code),
                onChanged: (v) => setState(
                  () => v! ? _subs.add(s.code) : _subs.remove(s.code),
                ),
                title: Text('${s.code}  ${s.name}'),
                secondary: Text(
                  '${bank.count(topic: widget.topic.number, sub: s.code, level: _level)}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 12),
            Text(
              'Number of questions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in const [10, 20, 40, 0])
                  ChoiceChip(
                    label: Text(n == 0 ? 'All ($available)' : '$n'),
                    selected: _length == n,
                    onSelected: (_) => setState(() => _length = n),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shuffle questions'),
              value: _shuffle,
              onChanged: (v) => setState(() => _shuffle = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('start-practice'),
              onPressed: available == 0 ? null : () => _start(bank),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                available == 0 ? 'No questions selected' : 'Start practice',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start(QuestionBank bank) {
    final pool = bank.select(
      topic: widget.topic.number,
      subs: _subs,
      level: _level,
    );
    if (_shuffle) pool.shuffle();
    final questions = _length == 0 || _length >= pool.length
        ? pool
        : pool.sublist(0, _length);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PracticeScreen(title: widget.topic.name, questions: questions),
      ),
    );
  }
}
