import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../../utils/translations.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String chatId;
  final List<String> existingMemberIds;

  const AddGroupMembersScreen({
    super.key,
    required this.chatId,
    required this.existingMemberIds,
  });

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final _userService = UserService();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<UserModel> _searchResults = [];
  final List<UserModel> _selectedUsers = [];
  bool _isSearching = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isSearching = true);
    try {
      final currentUserId = _authService.currentUser?.uid;
      final users = await _userService.getInitialUsers();
      setState(() {
        _searchResults = users
            .where((u) => u.uid != currentUserId && !widget.existingMemberIds.contains(u.uid))
            .toList();
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
    final currentUserId = _authService.currentUser?.uid;
    
    setState(() {
      // Filter out users who are already in the group and current user
      _searchResults = users
          .where((u) => u.uid != currentUserId && !widget.existingMemberIds.contains(u.uid))
          .toList();
      _isSearching = false;
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      for (var user in _selectedUsers) {
        // Added a timeout so it doesn't hang forever if internet is lost
        await _chatService.addMember(widget.chatId, user.uid).timeout(const Duration(seconds: 10));
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('membersAdded'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('addMembersError'))),
        );
      }
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
        title: Text(context.t('addMembers')),
        actions: [
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _isAdding 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _addSelectedMembers,
                      child: Text(context.t('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: context.t('searchPeople'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          if (_selectedUsers.isNotEmpty) const Divider(height: 1),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? Center(child: Text(context.t('noUsersFound')))
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
