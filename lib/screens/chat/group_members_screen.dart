import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/translations.dart';
import 'add_group_members_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  final String chatId;

  const GroupMembersScreen({super.key, required this.chatId});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatModel>(
      stream: _chatService.getChatStream(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final chat = snapshot.data!;
        final currentUserId = _authService.currentUser?.uid;
        final currentIsAdmin = chat.admins.contains(currentUserId) || chat.adminId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.t('members')),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(
                  hintText: context.t('searchMembers'),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  leading: const Icon(Icons.search),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ),
            ),
          ),
          body: ListView.builder(
            itemCount: chat.participants.length,
            itemBuilder: (context, index) {
              final uid = chat.participants[index];
              return FutureBuilder<UserModel?>(
                future: _userService.getUser(uid),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  if (_searchQuery.isNotEmpty && 
                      (user?.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) == false)) {
                    return const SizedBox.shrink();
                  }

                  final isOwner = uid == chat.adminId;
                  final isAdmin = chat.admins.contains(uid) || isOwner;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                      child: user?.photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user?.displayName ?? context.t('loading')),
                    subtitle: user != null
                        ? Text('@${user.displayName.toLowerCase().replaceAll(' ', '')}')
                        : Text(context.t('loading')),
                    trailing: isAdmin 
                      ? Chip(
                          label: Text(isOwner ? context.t('owner') : context.t('admin'), style: const TextStyle(fontSize: 10)),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        )
                      : null,
                    onTap: () => _showMemberOptions(chat, uid, isAdmin, isOwner, currentIsAdmin),
                  );
                },
              );
            },
          ),
          floatingActionButton: (currentIsAdmin || (chat.permissions['addUsers'] ?? true)) ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGroupMembersScreen(
                    chatId: widget.chatId,
                    existingMemberIds: chat.participants,
                  ),
                ),
              );
            },
            child: const Icon(Icons.person_add),
          ) : null,
        );
      },
    );
  }

  void _showMemberOptions(ChatModel chat, String targetUid, bool targetIsAdmin, bool isOwner, bool currentIsAdmin) {
    if (targetUid == _authService.currentUser?.uid) return;

    final userRestriction = chat.restrictions[targetUid];
    final isRestricted = userRestriction != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: Text(context.t('sendPrivateMessage')),
            onTap: () {}, // Navigate to private chat
          ),
          if (currentIsAdmin && !isOwner) ...[
            ListTile(
              leading: Icon(targetIsAdmin ? Icons.admin_panel_settings_outlined : Icons.admin_panel_settings),
              title: Text(targetIsAdmin ? context.t('dismissAdmin') : context.t('makeAdmin')),
              onTap: () {
                _chatService.toggleAdmin(widget.chatId, targetUid, !targetIsAdmin);
                Navigator.pop(context);
              },
            ),
            // Restrict / Remove Restriction
            ListTile(
              leading: Icon(
                isRestricted ? Icons.check_circle_outline : Icons.block_rounded,
                color: isRestricted ? Colors.green : Colors.orange,
              ),
              title: Text(
                isRestricted ? context.t('removeRestriction') : context.t('restrict'),
                style: TextStyle(
                  color: isRestricted ? Colors.green : Colors.orange,
                ),
              ),
              subtitle: isRestricted ? Text(context.t('restrictedHint'), style: const TextStyle(fontSize: 12)) : null,
              onTap: () {
                Navigator.pop(context);
                if (isRestricted) {
                  _chatService.removeUserRestriction(widget.chatId, targetUid);
                } else {
                  _showRestrictDialog(targetUid);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
              title: Text(context.t('kickFromGroup'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                _chatService.banUser(widget.chatId, targetUid);
                Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showRestrictDialog(String targetUid) {
    bool noMessages = false;
    bool noMedia = false;
    int durationIndex = 0;

    final durations = [
      null as Duration?,
      const Duration(hours: 1),
      const Duration(hours: 8),
      const Duration(days: 1),
      const Duration(days: 7),
    ];
    final durationLabels = [
      context.t('permanent'),
      context.t('for1Hour'),
      context.t('for8Hours'),
      context.t('for1Day'),
      context.t('for7Days'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(context.t('restrictUser'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Permissions toggles
              SwitchListTile(
                title: Text(context.t('sendMessages')),
                value: !noMessages,
                onChanged: (v) => setModalState(() => noMessages = !v),
                secondary: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.chat_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              SwitchListTile(
                title: Text(context.t('sendMedia')),
                value: !noMedia,
                onChanged: (v) => setModalState(() => noMedia = !v),
                secondary: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.image_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(context.t('restrictUntil'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: durationLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final selected = durationIndex == i;
                    return FilterChip(
                      label: Text(durationLabels[i], style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
                      selected: selected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      onSelected: (_) => setModalState(() => durationIndex = i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _chatService.setUserRestriction(
                      widget.chatId,
                      targetUid,
                      sendMessages: noMessages ? false : null,
                      sendMedia: noMedia ? false : null,
                      until: durations[durationIndex] != null
                          ? DateTime.now().add(durations[durationIndex]!)
                          : null,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(context.t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
