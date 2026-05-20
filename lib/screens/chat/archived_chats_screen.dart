import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../utils/translations.dart';
import '../../widgets/chat_list_item.dart';

class ArchivedChatsScreen extends StatelessWidget {
  final List<ChatModel> chats;
  final String currentUserId;

  const ArchivedChatsScreen({
    super.key,
    required this.chats,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('archivedChats')),
        actions: [
          if (chats.isNotEmpty)
            TextButton(
              onPressed: () => _unarchiveAll(context),
              child: Text(context.t('unarchiveChat')),
            ),
        ],
      ),
      body: chats.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text(context.t('noArchived'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(context.t('noArchivedHint'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 82, color: colorScheme.outlineVariant.withAlpha(80)),
              itemBuilder: (context, index) {
                return ChatListItem(
                  chat: chats[index],
                  currentUserId: currentUserId,
                  onTap: () {},
                );
              },
            ),
    );
  }

  void _unarchiveAll(BuildContext context) {
    final chatService = ChatService();
    for (final chat in chats) {
      chatService.toggleArchive(chat.chatId, currentUserId, false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('unarchiveChat'))),
    );
  }
}
