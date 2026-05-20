import 'package:flutter/material.dart';
import '../../models/group_models.dart';
import '../../services/chat_service.dart';
import '../../utils/translations.dart';

class RecentActionsScreen extends StatelessWidget {
  final String chatId;

  const RecentActionsScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final colorScheme = Theme.of(context).colorScheme;

    IconData _iconForType(String type) {
      switch (type) {
        case 'approve_join':
          return Icons.person_add_alt_1_rounded;
        case 'reject_join':
          return Icons.person_remove_rounded;
        case 'add_member':
          return Icons.person_add_rounded;
        case 'change_privacy':
          return Icons.lock_outline_rounded;
        case 'pin_message':
          return Icons.push_pin_rounded;
        case 'delete_message':
          return Icons.delete_outline_rounded;
        case 'banned_user':
          return Icons.block_rounded;
        case 'change_info':
          return Icons.edit_outlined;
        default:
          return Icons.info_outline_rounded;
      }
    }

    Color _colorForType(String type) {
      switch (type) {
        case 'approve_join':
        case 'add_member':
          return Colors.green;
        case 'reject_join':
        case 'banned_user':
          return Colors.red;
        case 'pin_message':
          return Colors.orange;
        case 'change_privacy':
        case 'change_info':
          return Colors.blue;
        default:
          return colorScheme.primary;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('recentActions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: context.t('clearLog'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.t('clearLog')),
                  content: Text(context.t('clearLogConfirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(context.t('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.t('delete'),
                          style: TextStyle(color: colorScheme.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await chatService.clearAdminActions(chatId);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AdminAction>>(
        stream: chatService.getAdminActions(chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final actions = snapshot.data ?? [];

          if (actions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text(context.t('noActions'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(context.t('actionsEmpty'),
                      style: TextStyle(
                          fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final action = actions[index];
              final ago = _formatAgo(action.timestamp);
              final actionColor = _colorForType(action.actionType);

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: actionColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(action.actionType),
                      size: 20, color: actionColor),
                ),
                title: Text(
                  action.adminName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  action.description,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  ago,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
