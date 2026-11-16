import 'package:flutter/material.dart';

import '../app.dart';
import '../data/papers.dart';
import 'mock_select_screen.dart';
import 'topics_screen.dart';

/// 1440 → "1,440".
String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = BankScope.of(context);
    final bank = scope.bank;
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: scope.ads.banner(),
      appBar: AppBar(
        title: const Text(appTitle),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Cambridge IGCSE Chemistry (0620)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${_thousands(bank.questions.length)} exam-style multiple-choice questions across '
              '${bank.topics.length} topics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ModeCard(
              key: const Key('home-practice'),
              icon: Icons.menu_book_outlined,
              title: 'Topic practice',
              subtitle:
                  'Choose a topic and subtopics. See the answer and explanation after every question.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TopicsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              key: const Key('home-mock'),
              icon: Icons.assignment_outlined,
              title: 'Mock papers',
              subtitle:
                  '$papersPerScope papers of $questionsPerPaper questions, mixed or by topic, '
                  'timed at $paperMinutes minutes. Marked at the end.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MockSelectScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Topics', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final t in bank.topics)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  topicIcon(t.number),
                  color: topicColor(t.number, theme.brightness),
                ),
                title: Text('${t.number}  ${t.name}'),
                trailing: Text('${bank.count(topic: t.number)} Qs'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final ads = BankScope.of(context).ads;
    final choices = await ads.privacyChoicesRequired();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: appTitle,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 HomiLabs',
      children: [
        const SizedBox(height: 12),
        const Text(
          'Original practice questions written to the topics of the Cambridge IGCSE Chemistry 0620 '
          'syllabus (2026–2028). Questions marked Core use Core content; Extended questions use '
          'Supplement content.\n\nThis app is not produced or endorsed by Cambridge University Press & '
          'Assessment.\n\nThe app is free and shows ads from Google AdMob, never during a question '
          'or paper. Your answers stay on your phone. Privacy policy and terms: '
          'igcse-chemistry.homilabs.org',
        ),
        if (choices) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: ads.showPrivacyChoices,
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Privacy choices'),
          ),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 36, color: scheme.onPrimaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
