import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';

import '../utils/date_formatter.dart';
import '../utils/translations.dart';
import '../screens/chat/full_screen_image_viewer.dart';
import 'voice_message_player.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat/user_profile_screen.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isGroupChat;
  final VoidCallback? onSwipe;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.isGroupChat = false,
    this.onSwipe,
    this.onLongPress,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Telegram-style bubble colors
    final myBubbleColor = isDark
        ? const Color(0xFF2B5278)
        : const Color(0xFFE3FFC5);
    final otherBubbleColor = isDark
        ? colorScheme.surfaceContainerHigh
        : Colors.white;
    final myTextColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final otherTextColor = colorScheme.onSurface;
    final myTimeColor = isDark
        ? Colors.white.withAlpha(150)
        : const Color(0xFF5C8A3C);
    final otherTimeColor = colorScheme.onSurfaceVariant;

    // Bubble tail radius logic (Telegram style)
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (isLastInGroup ? 4 : 18)),
      bottomRight: Radius.circular(!isMe ? 18 : (isLastInGroup ? 4 : 18)),
    );

    Widget bubbleContent = Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 3 : 1,
        bottom: isLastInGroup ? 3 : 1,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                decoration: BoxDecoration(
                  color: isMe ? myBubbleColor : otherBubbleColor,
                  borderRadius: bubbleRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: message.type == MessageType.text
                          ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
                          : const EdgeInsets.all(3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender name in groups
                          if (isGroupChat &&
                              !isMe &&
                              isFirstInGroup &&
                              message.senderName != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 2,
                                left: message.type != MessageType.text ? 8 : 0,
                                top: message.type != MessageType.text ? 6 : 0,
                              ),
                              child: Text(
                                message.senderName!.split('@')[0],
                                style: TextStyle(
                                  color: _getSenderColor(message.senderId),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          // Reply preview
                          if (message.replyToMessageContent != null)
                            GestureDetector(
                              onTap: onReplyTap,
                              child: Container(
                                margin: EdgeInsets.only(
                                  bottom: 4,
                                  left: message.type != MessageType.text ? 6 : 0,
                                  right: message.type != MessageType.text ? 6 : 0,
                                  top: message.type != MessageType.text ? 4 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.black.withAlpha(15)
                                      : colorScheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: isMe
                                          ? (isDark
                                              ? Colors.white70
                                              : const Color(0xFF5C8A3C))
                                          : colorScheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.t('reply'),
                                      style: TextStyle(
                                        color: isMe
                                            ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF5C8A3C))
                                            : colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      message.replyToMessageContent!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isMe
                                            ? myTextColor.withAlpha(150)
                                            : otherTextColor.withAlpha(150),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Forwarded from label
                          if (message.forwardedFrom != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 2,
                                left: message.type != MessageType.text ? 8 : 0,
                                top: message.type != MessageType.text ? 4 : 0,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.forward_rounded, size: 12, color: isMe ? myTextColor.withAlpha(150) : otherTextColor.withAlpha(150)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      context.t('forwardedFrom', args: [message.forwardedFrom!.split('@')[0]]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isMe ? myTextColor.withAlpha(150) : otherTextColor.withAlpha(150),
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Message content
                          _buildMessageContent(
                            context,
                            colorScheme,
                            textTheme,
                            myTextColor,
                            otherTextColor,
                          ),
                          // Inline timestamp for text messages
                          if (message.type == MessageType.text)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormatter.formatChatBubbleTime(
                                        message.timestamp),
                                    style: TextStyle(
                                      color: isMe ? myTimeColor : otherTimeColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      message.isRead
                                          ? Icons.done_all_rounded
                                          : Icons.done_rounded,
                                      size: 15,
                                      color: message.isRead
                                          ? (isDark
                                              ? const Color(0xFF6EB7F0)
                                              : const Color(0xFF4FAE3F))
                                          : (isMe ? myTimeColor : otherTimeColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Overlay timestamp for media messages
                    if (message.type != MessageType.text &&
                        message.type != MessageType.voice)
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormatter.formatChatBubbleTime(
                                    message.timestamp),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  message.isRead
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 13,
                                  color: message.isRead
                                      ? const Color(0xFF6EB7F0)
                                      : Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    // --- Reactions ---
                    if (message.reactions.isNotEmpty)
                      Positioned(
                        bottom: -10,
                        right: isMe ? null : -6,
                        left: isMe ? -6 : null,
                        child: _buildReactionBadge(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Group chat avatar
    if (isGroupChat && !isMe) {
      bubbleContent = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLastInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4, right: 6),
              child: GestureDetector(
                onTap: () => _navigateToUserProfile(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      _getSenderColor(message.senderId).withAlpha(40),
                  child: Text(
                    (() {
                      final name = message.senderName;
                      if (name == null || name.trim().isEmpty) return 'U';
                      final clean = name.split('@')[0].trim();
                      return clean.isEmpty ? 'U' : clean[0].toUpperCase();
                    })(),
                    style: TextStyle(
                      color: _getSenderColor(message.senderId),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 46),
          Expanded(child: bubbleContent),
          const SizedBox(width: 46),
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            onSwipe?.call();
          }
        },
        child: bubbleContent,
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(message.senderId)
        .get();
    if (snapshot.exists && context.mounted) {
      final userData = snapshot.data()!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: message.senderId,
            displayName: userData['displayName'],
            photoUrl: userData['photoUrl'],
          ),
        ),
      );
    }
  }

  Widget _buildMessageContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color myTextColor,
    Color otherTextColor,
  ) {
    switch (message.type) {
      case MessageType.text:
        final textColor = isMe ? myTextColor : otherTextColor;
        final List<TextSpan> spans = [];
        final words = message.content.split(' ');
        for (int i = 0; i < words.length; i++) {
          final word = words[i];
          final isLast = i == words.length - 1;
          if (word.startsWith('@') && word.length > 1) {
            final usernameToSearch =
                word.substring(1).replaceAll(RegExp(r'[^\w\s]+$'), '');
            spans.add(TextSpan(
              text: word,
              style: TextStyle(
                color: isMe
                    ? const Color(0xFF6EB7F0)
                    : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: usernameToSearch)
                      .limit(1)
                      .get();
                  if (snapshot.docs.isNotEmpty && context.mounted) {
                    final userData = snapshot.docs.first.data();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          userId: snapshot.docs.first.id,
                          displayName: userData['displayName'],
                          photoUrl: userData['photoUrl'],
                        ),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('userNotFound', args: [word]))),
                    );
                  }
                },
            ));
          } else if (word.startsWith('http://') || word.startsWith('https://')) {
            spans.add(TextSpan(
              text: word,
              style: TextStyle(
                color: isMe
                    ? const Color(0xFF6EB7F0)
                    : colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: word,
              style: TextStyle(color: textColor),
            ));
          }
          if (!isLast) spans.add(const TextSpan(text: ' '));
        }
        return RichText(
          text: TextSpan(
            children: spans,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.35,
            ),
          ),
        );

      case MessageType.image:
        final heroTag =
            'image_${message.id ?? message.timestamp.millisecondsSinceEpoch}';
        final imageWidget = message.isPending && message.localFilePath != null
            ? Image.file(File(message.localFilePath!), fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: message.content,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: 250,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  width: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.broken_image_rounded,
                      color: colorScheme.error, size: 36),
                ),
                fit: BoxFit.cover,
              );

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
                  imageUrl: message.content,
                  localFilePath: message.localFilePath,
                  heroTag: heroTag,
                ),
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 280,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    imageWidget,
                    if (message.isPending)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

      case MessageType.video:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 250,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(60),
                        Colors.black.withAlpha(120),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 32, color: Colors.black87),
                ),
              ],
            ),
          ),
        );

      case MessageType.file:
        final fileName = message.localFilePath?.split('/').last ?? context.t('document');
        return Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_rounded, size: 32, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isMe ? myTextColor : otherTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    Text(
                      context.t('document'),
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
            borderRadius: BorderRadius.circular(10),
          ),
        );

      case MessageType.voice:
        return SizedBox(
          width: 260,
          child: VoiceMessagePlayer(
            url: message.content,
            foregroundColor: isMe
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A))
                : colorScheme.onSurface,
          ),
        );
    }
  }

  Widget _buildReactionBadge(BuildContext context) {
    final reactions = message.reactions.values.toSet().toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...reactions.take(3).map((emoji) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(emoji, style: const TextStyle(fontSize: 13)),
              )),
          if (message.reactions.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                '${message.reactions.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Generate a consistent color for each sender ID in group chats
  Color _getSenderColor(String senderId) {
    final colors = [
      const Color(0xFFE17076), // Red
      const Color(0xFF7BC862), // Green
      const Color(0xFFE5A64E), // Orange
      const Color(0xFF65AADD), // Blue
      const Color(0xFFEE7AE6), // Pink
      const Color(0xFF6EC9CB), // Teal
      const Color(0xFFFA8E5E), // Peach
      const Color(0xFF8A7AF4), // Purple
    ];
    return colors[senderId.hashCode.abs() % colors.length];
  }
}
