import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/translations.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();

  /// Generates a consistent gradient for avatar backgrounds.
  List<Color> _avatarGradient(String name) {
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final users = docs
              .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
              .where((user) => user.uid != currentUserId)
              .toList();

          if (users.isEmpty) {
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
                    child: Icon(Icons.people_outline_rounded, size: 36, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(context.t('noConversations'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 76),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            itemBuilder: (context, index) {
              final user = users[index];
              final gradient = _avatarGradient(user.displayName);
              return InkWell(
                onTap: () async {
                  final chatId = await _chatService.getOrCreateChat(currentUserId, user.uid);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        otherUserName: user.displayName,
                        otherUserId: user.uid,
                        otherUserPhotoUrl: user.photoUrl,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (user.username != null)
                              Text(
                                '@${user.username}',
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant.withAlpha(100)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
