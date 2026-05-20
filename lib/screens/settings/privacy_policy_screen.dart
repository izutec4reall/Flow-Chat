import 'package:flutter/material.dart';
import '../../utils/translations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_PolicySection>[
      _PolicySection(
        icon: Icons.info_outline,
        titleKey: 'ppIntro',
        bodyKey: 'ppIntroBody',
      ),
      _PolicySection(
        icon: Icons.assignment_outlined,
        titleKey: 'ppDataCollect',
        bodyKey: 'ppDataCollectBody',
      ),
      _PolicySection(
        icon: Icons.how_to_vote_outlined,
        titleKey: 'ppDataUse',
        bodyKey: 'ppDataUseBody',
      ),
      _PolicySection(
        icon: Icons.people_outline,
        titleKey: 'ppDataShare',
        bodyKey: 'ppDataShareBody',
      ),
      _PolicySection(
        icon: Icons.security_outlined,
        titleKey: 'ppSecurity',
        bodyKey: 'ppSecurityBody',
      ),
      _PolicySection(
        icon: Icons.delete_outline,
        titleKey: 'ppDataRetention',
        bodyKey: 'ppDataRetentionBody',
      ),
      _PolicySection(
        icon: Icons.child_care_outlined,
        titleKey: 'ppChildren',
        bodyKey: 'ppChildrenBody',
      ),
      _PolicySection(
        icon: Icons.update_outlined,
        titleKey: 'ppChanges',
        bodyKey: 'ppChangesBody',
      ),
      _PolicySection(
        icon: Icons.mail_outline,
        titleKey: 'ppContact',
        bodyKey: 'ppContactBody',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('privacyPolicy')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.t('privacyPolicySub'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            context.t('ppLastUpdate'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            _buildSection(context, section),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, _PolicySection section) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha(60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  context.t(section.titleKey),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.t(section.bodyKey),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  const _PolicySection({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
}
