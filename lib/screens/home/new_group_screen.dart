import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _userService = UserService();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();
  
  List<UserModel> _searchResults = [];
  final List<UserModel> _selectedUsers = [];
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isSearching = true);
    try {
      final currentUid = _authService.currentUser?.uid;
      final users = await _userService.getInitialUsers();
      setState(() {
        _searchResults = users.where((u) => u.uid != currentUid).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadInitialUsers();
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

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('enterGroupName'))),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('selectMember'))),
      );
      return;
    }

    setState(() => _isCreating = true);

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final participantIds = _selectedUsers.map((u) => u.uid).toList();
    final chatId = await _chatService.createGroup(
      _groupNameController.text,
      participantIds,
      currentUser.uid,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: _groupNameController.text,
            otherUserId: 'group', // Special case for groups
          ),
        ),
      );
    }
  }

  void _toggleUserSelection(UserModel user) {
    setState(() {
      if (_selectedUsers.any((u) => u.uid == user.uid)) {
        _selectedUsers.removeWhere((u) => u.uid == user.uid);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('newGroup')),
        actions: [
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _isCreating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _createGroup,
                      child: Text(context.t('create'), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.md),
                child: TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: context.t('groupName'),
                    prefixIcon: Icon(Icons.group_add),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.sm),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: context.t('searchMembers'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                              child: user.photoUrl == null ? const Icon(Icons.person) : null,
                            ),
                            Positioned(
                              right: -2,
                              top: -2,
                              child: GestureDetector(
                                onTap: () => _toggleUserSelection(user),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.displayName.split(' ')[0],
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isSelected = _selectedUsers.any((u) => u.uid == user.uid);
                      return ListTile(
                        onTap: () => _toggleUserSelection(user),
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.username != null ? '@${user.username}' : user.email),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
