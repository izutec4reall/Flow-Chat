import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';

class JoinRequestsScreen extends StatelessWidget {
  final String chatId;

  JoinRequestsScreen({super.key, required this.chatId});

  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('joinRequests')),
        centerTitle: true,
      ),
      body: StreamBuilder<ChatModel>(
        stream: _chatService.getChatStream(chatId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final chat = snapshot.data!;
          if (chat.joinRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(context.t('noPendingRequests'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.md),
            itemCount: chat.joinRequests.length,
            itemBuilder: (context, index) {
              final uid = chat.joinRequests[index];
              return FutureBuilder<UserModel?>(
                future: _userService.getUser(uid),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${user?.username ?? 'username'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                              onPressed: () => _chatService.handleJoinRequest(chatId, uid, true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                              onPressed: () => _chatService.handleJoinRequest(chatId, uid, false),
                            ),
                          ],
                        ),
                      ),
                    ),
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
