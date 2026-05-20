import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/translations.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'full_screen_image_viewer.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('savedMessagesTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(context.t('forwardedMessages'), style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('savedMessages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark_outline_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(context.t('noSavedMessages'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text(context.t('forwardHint'),
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant.withAlpha(60),
                  ),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final type = data['type'] ?? 'text';
                    final content = data['content'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final senderId = data['senderId'] ?? '';
                    final senderName = data['senderName'] ?? context.t('unknown');

                    return FutureBuilder<UserModel?>(
                      future: senderId.isNotEmpty ? _userService.getUser(senderId) : Future.value(null),
                      builder: (context, userSnapshot) {
                        final sender = userSnapshot.data;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: sender?.photoUrl != null ? NetworkImage(sender!.photoUrl!) : null,
                            child: sender?.photoUrl == null
                                ? Text(
                                    senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                  )
                                : null,
                          ),
                          title: Text(senderName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (type == 'text')
                                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                              if (type == 'image')
                                Row(
                                  children: [
                                    Icon(Icons.photo_camera_rounded, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: content,
                                        width: 120, height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              if (type == 'voice')
                                Row(
                                  children: [
                                    Icon(Icons.mic_rounded, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(context.t('voice'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              if (type == 'video')
                                Row(
                                  children: [
                                    Icon(Icons.videocam_rounded, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(context.t('video'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatRelativeTime(timestamp),
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withAlpha(150)),
                              ),
                            ],
                          ),
                          onTap: type == 'image'
                              ? () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => FullScreenImageViewer(
                                    imageUrl: content,
                                    heroTag: 'saved_image_$index',
                                  )))
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
