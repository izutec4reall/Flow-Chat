import 'package:flutter/material.dart';
import '../../utils/translations.dart';
import 'faq_detail_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<_FaqCategory> _categories = [
    _FaqCategory(
      icon: Icons.rocket_launch_outlined,
      keyName: 'faqCatGettingStarted',
      questions: [
        _FaqItem('faqCatGettingStarted', 'faqQ1', 'faqA1'),
        _FaqItem('faqCatGettingStarted', 'faqQWhatIsFlow', 'faqAWhatIsFlow'),
        _FaqItem('faqCatGettingStarted', 'faqQCreateAccount', 'faqACreateAccount'),
        _FaqItem('faqCatGettingStarted', 'faqQLogin', 'faqALogin'),
      ],
    ),
    _FaqCategory(
      icon: Icons.groups_outlined,
      keyName: 'faqCatGroups',
      questions: [
        _FaqItem('faqCatGroups', 'faqQ2', 'faqA2'),
        _FaqItem('faqCatGroups', 'faqQAddMember', 'faqAAddMember'),
        _FaqItem('faqCatGroups', 'faqQRemoveMember', 'faqARemoveMember'),
        _FaqItem('faqCatGroups', 'faqQGroupPerms', 'faqAGroupPerms'),
        _FaqItem('faqCatGroups', 'faqQInviteLink', 'faqAInviteLink'),
      ],
    ),
    _FaqCategory(
      icon: Icons.chat_outlined,
      keyName: 'faqCatMessages',
      questions: [
        _FaqItem('faqCatMessages', 'faqQDeleteMsg', 'faqADeleteMsg'),
        _FaqItem('faqCatMessages', 'faqQForward', 'faqAForward'),
        _FaqItem('faqCatMessages', 'faqQPinMsg', 'faqAPinMsg'),
        _FaqItem('faqCatMessages', 'faqQArchive', 'faqAArchive'),
        _FaqItem('faqCatMessages', 'faqQMute', 'faqAMute'),
      ],
    ),
    _FaqCategory(
      icon: Icons.security_outlined,
      keyName: 'faqCatAccount',
      questions: [
        _FaqItem('faqCatAccount', 'faqQResetPass', 'faqAResetPass'),
        _FaqItem('faqCatAccount', 'faqQChangeName', 'faqAChangeName'),
        _FaqItem('faqCatAccount', 'faqQBlockUser', 'faqABlockUser'),
        _FaqItem('faqCatAccount', 'faqQDeleteAccount', 'faqADeleteAccount'),
      ],
    ),
    _FaqCategory(
      icon: Icons.troubleshoot_outlined,
      keyName: 'faqCatTroubleshoot',
      questions: [
        _FaqItem('faqCatTroubleshoot', 'faqQNotif', 'faqANotif'),
        _FaqItem('faqCatTroubleshoot', 'faqQSlow', 'faqASlow'),
        _FaqItem('faqCatTroubleshoot', 'faqQLogoutIssue', 'faqALogoutIssue'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('faq')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              context.t('faqSub'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final cat in _categories) ...[
            _buildCategory(context, cat),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, _FaqCategory cat) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(cat.icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  context.t(cat.keyName),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant),
          for (int i = 0; i < cat.questions.length; i++) ...[
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FaqDetailScreen(
                    questionKey: cat.questions[i].questionKey,
                    answerKey: cat.questions[i].answerKey,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t(cat.questions[i].questionKey),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (i < cat.questions.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withAlpha(80)),
          ],
        ],
      ),
    );
  }
}

class _FaqCategory {
  final IconData icon;
  final String keyName;
  final List<_FaqItem> questions;
  const _FaqCategory({required this.icon, required this.keyName, required this.questions});
}

class _FaqItem {
  final String categoryKey;
  final String questionKey;
  final String answerKey;
  const _FaqItem(this.categoryKey, this.questionKey, this.answerKey);
}
