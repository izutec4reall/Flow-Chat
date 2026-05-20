import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../../utils/translations.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _userService = UserService();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    
    final users = await _userService.searchUsers(query);
    
    final currentUid = _authService.currentUser?.uid;
    setState(() {
      _searchResults = users.where((u) => u.uid != currentUid).toList();
      _isSearching = false;
    });
  }

  Future<void> _startChat(UserModel otherUser) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final chatId = await _chatService.createChat(currentUser.uid, otherUser.uid);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: otherUser.displayName,
            otherUserId: otherUser.uid,
            otherUserPhotoUrl: otherUser.photoUrl,
          ),
        ),
      );
    }
  }

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('newChat')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              autofocus: true,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              decoration: InputDecoration(
                hintText: context.t('searchUsers'),
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150)),
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(80),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_rounded, size: 36, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(context.t('searchForUsers'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Text(context.t('typeToFind'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 76),
                    child: Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant.withAlpha(80)),
                  ),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final gradient = _avatarGradient(user.displayName);
                    return InkWell(
                      onTap: () => _startChat(user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: gradient,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24, backgroundColor: Colors.transparent,
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
                                  Text(user.displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.username != null ? '@${user.username}' : user.email,
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withAlpha(80),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
