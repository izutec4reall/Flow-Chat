import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/message_service.dart';
import '../services/presence_service.dart';
import '../services/user_service.dart';
import '../screens/chat/chat_screen.dart';
import '../utils/date_formatter.dart';
import '../utils/translations.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  /// Returns an icon + prefix for the last message based on its type.
  Widget _buildMessageTypeIcon(BuildContext context, String? type) {
    if (type == null || type == 'text') return const SizedBox.shrink();
    
    IconData icon;
    switch (type) {
      case 'image':
        icon = Icons.photo_camera_rounded;
        break;
      case 'video':
        icon = Icons.videocam_rounded;
        break;
      case 'voice':
        icon = Icons.mic_rounded;
        break;
      case 'file':
        icon = Icons.insert_drive_file_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        size: 15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Returns a label for the message type when the content is empty.
  String _messageTypeLabel(BuildContext context, String? type) {
    switch (type) {
      case 'image':
        return context.t('photo');
      case 'video':
        return context.t('video');
      case 'voice':
        return context.t('voice');
      case 'file':
        return context.t('document');
      default:
        return '';
    }
  }

  /// Builds read status checkmarks (✓ or ✓✓).
  Widget _buildReadStatus(BuildContext context) {
    // Only show checkmarks for messages sent by the current user
    if (chat.lastMessageSenderId != currentUserId) {
      return const SizedBox.shrink();
    }

    // Determine if the message is read by checking if other users have 0 unread
    final bool isRead = chat.unreadCounts.entries
        .where((e) => e.key != currentUserId)
        .every((e) => e.value == 0);

    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: Icon(
        isRead ? Icons.done_all_rounded : Icons.done_rounded,
        size: 16,
        color: isRead
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    final int unreadCount = chat.unreadCounts[currentUserId] ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<UserModel?>(
      future: chat.isGroup ? null : UserService().getUser(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        String displayName;
        String? photoUrl;

        if (chat.isGroup) {
          displayName = chat.groupName ?? context.t('unnamedGroup');
          photoUrl = chat.groupIcon;
        } else {
          displayName = chat.nicknames?[otherUserId] ??
              otherUser?.displayName ??
              context.t('newContact');
          photoUrl = otherUser?.photoUrl;
        }

        // Build last message preview
        String lastMessagePreview;
        final msgType = chat.lastMessageType;
        if (chat.lastMessage.isEmpty) {
          lastMessagePreview = context.t('startChat');
        } else if (msgType != null && msgType != 'text') {
          lastMessagePreview = _messageTypeLabel(context, msgType);
        } else {
          lastMessagePreview = chat.lastMessage;
        }

        // Add sender prefix
        String senderPrefix = '';
        if (chat.lastMessage.isNotEmpty) {
          if (chat.lastMessageSenderId == currentUserId) {
            senderPrefix = '';
          } else if (chat.isGroup && chat.lastMessageSenderId != null) {
            // For groups, try to show the sender's first name
            senderPrefix = '';
          }
        }

        return Dismissible(
          key: Key(chat.chatId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.t('deleteChat')),
                    content: Text(context.t('deleteChatConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.t('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(context.t('delete'),
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) {
            ChatService().deleteChat(chat.chatId);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                const SizedBox(height: 2),
                Text(
                  context.t('delete'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ChatScreen(
                      chatId: chat.chatId,
                      otherUserName: displayName,
                      otherUserId: otherUserId,
                      otherUserPhotoUrl: photoUrl,
                      isGroup: chat.isGroup,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              onLongPress: () => _showContextMenu(context),
              borderRadius: BorderRadius.circular(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // === AVATAR with online indicator ===
                    _buildAvatar(context, otherUserId, displayName, photoUrl),
                    const SizedBox(width: 12),

                    // === NAME + MESSAGE PREVIEW ===
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Name + Time
                          Row(
                            children: [
                              // Group icon
                              if (chat.isGroup)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.group_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              // Pin icon
                              if (chat.pinnedBy.containsKey(currentUserId))
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              // Display name
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Timestamp
                              Text(
                                DateFormatter.formatRelativeTime(
                                    chat.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: unreadCount > 0
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Bottom row: Message preview + Badge
                          Row(
                            children: [
                              // Read status checkmarks
                              _buildReadStatus(context),
                              // Message type icon
                              _buildMessageTypeIcon(context, msgType),
                              // Message preview text
                              Expanded(
                                child: Text(
                                  '$senderPrefix$lastMessagePreview',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: unreadCount > 0
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Muted icon
                              if (chat.mutedUsers[currentUserId] != null &&
                                  (chat.mutedUsers[currentUserId]!.isAfter(DateTime.now())))
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.notifications_off_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              // Unread badge
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  constraints: const BoxConstraints(
                                    minWidth: 22,
                                    minHeight: 22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : '$unreadCount',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String otherUserId,
      String displayName, String? photoUrl) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return StreamBuilder<bool>(
      stream: chat.isGroup
          ? Stream.value(false)
          : PresenceService().getPresenceStream(otherUserId),
      builder: (context, presenceSnapshot) {
        final isOnline = presenceSnapshot.data ?? false;
        return SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            children: [
              Hero(
                tag: 'avatar_${chat.chatId}',
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photoUrl == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getAvatarGradient(displayName),
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Online indicator
              if (isOnline && !chat.isGroup)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = this.currentUserId;
    final chatService = ChatService();
    final messageService = MessageService();
    final isMuted = chat.mutedUsers[currentUserId] != null &&
        chat.mutedUsers[currentUserId]!.isAfter(DateTime.now());
    final unreadCount = chat.unreadCounts[currentUserId] ?? 0;
    final isPinned = chat.pinnedBy.containsKey(currentUserId);
    final isArchived = chat.archivedBy.containsKey(currentUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomColorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Mark as Read / Unread
                _menuItem(
                  ctx,
                  unreadCount > 0
                      ? Icons.done_all_rounded
                      : Icons.mark_email_unread_rounded,
                  unreadCount > 0 ? context.t('markAsRead') : context.t('markAsUnread'),
                  bottomColorScheme,
                  () {
                    Navigator.pop(ctx);
                    if (unreadCount > 0) {
                      messageService.resetUnreadCount(chat.chatId, currentUserId);
                    } else {
                      messageService.markAsUnread(chat.chatId, currentUserId);
                    }
                  },
                ),
                // Pin / Unpin
                _menuItem(
                  ctx,
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  isPinned ? context.t('unpin') : context.t('pin'),
                  bottomColorScheme,
                  () {
                    Navigator.pop(ctx);
                    chatService.togglePin(chat.chatId, currentUserId, !isPinned);
                  },
                ),
                // Mute / Unmute
                _menuItem(
                  ctx,
                  isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  isMuted ? context.t('unmute') : context.t('mute'),
                  bottomColorScheme,
                  () {
                    Navigator.pop(ctx);
                    if (isMuted) {
                      chatService.muteUser(chat.chatId, currentUserId, null);
                    } else {
                      _showMuteDurationPicker(context, currentUserId);
                    }
                  },
                ),
                // Archive / Unarchive
                _menuItem(
                  ctx,
                  isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
                  isArchived ? context.t('unarchive') : context.t('archive'),
                  bottomColorScheme,
                  () {
                    Navigator.pop(ctx);
                    chatService.toggleArchive(chat.chatId, currentUserId, !isArchived);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Delete Chat
                _menuItem(
                  ctx,
                  Icons.delete_outline_rounded,
                  context.t('deleteChat'),
                  bottomColorScheme,
                  () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(context.t('deleteChat')),
                        content: Text(context.t('deleteChatConfirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text(context.t('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(context.t('delete'),
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      chatService.deleteChat(chat.chatId);
                    }
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMuteDurationPicker(BuildContext context, String userId) {
    final chatService = ChatService();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(context.t('mute'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _menuItem(ctx, Icons.timer_outlined, context.t('for1Hour'), colorScheme, () {
                  Navigator.pop(ctx);
                  chatService.muteUser(chat.chatId, userId, DateTime.now().add(const Duration(hours: 1)));
                }),
                _menuItem(ctx, Icons.timer_outlined, context.t('for8Hours'), colorScheme, () {
                  Navigator.pop(ctx);
                  chatService.muteUser(chat.chatId, userId, DateTime.now().add(const Duration(hours: 8)));
                }),
                _menuItem(ctx, Icons.timer_outlined, context.t('for1Day'), colorScheme, () {
                  Navigator.pop(ctx);
                  chatService.muteUser(chat.chatId, userId, DateTime.now().add(const Duration(days: 1)));
                }),
                _menuItem(ctx, Icons.timer_outlined, context.t('for7Days'), colorScheme, () {
                  Navigator.pop(ctx);
                  chatService.muteUser(chat.chatId, userId, DateTime.now().add(const Duration(days: 7)));
                }),
                _menuItem(ctx, Icons.block_rounded, context.t('forever'), colorScheme, () {
                  Navigator.pop(ctx);
                  chatService.muteUser(chat.chatId, userId, DateTime(2100));
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      ColorScheme colorScheme, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.error.withAlpha(20)
              : colorScheme.primaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: isDestructive ? colorScheme.error : colorScheme.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Generates a consistent gradient based on the display name.
  List<Color> _getAvatarGradient(String name) {
    final hash = name.hashCode;
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
      [const Color(0xFFfccb90), const Color(0xFFd57eeb)],
      [const Color(0xFF0fd850), const Color(0xFFf9f047)],
    ];
    return gradients[hash.abs() % gradients.length];
  }
}
