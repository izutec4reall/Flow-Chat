import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../models/group_models.dart';
import '../../utils/translations.dart';
import 'join_requests_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  final String chatId;

  const GroupManagementScreen({super.key, required this.chatId});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatModel>(
      stream: _chatService.getChatStream(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final chat = snapshot.data!;
        final currentUserId = _authService.currentUser?.uid;
        final isAdmin = chat.admins.contains(currentUserId) || chat.adminId == currentUserId;

        if (!isAdmin) {
          return Scaffold(body: Center(child: Text(context.t('accessDenied'))));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(context.t('groupManagement')),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.md),
            children: [
              _buildSectionHeader(context.t('settings')),
              _buildTile(
                icon: Icons.alternate_email_rounded,
                title: context.t('groupUsername'),
                subtitle: chat.groupUsername != null ? '@${chat.groupUsername}' : context.t('noUsername'),
                trailing: Icon(Icons.edit_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () => _editGroupUsername(chat),
              ),
              _buildTile(
                icon: Icons.person_add_alt_1_rounded,
                title: context.t('joinRequests'),
                subtitle: context.t('pendingRequests', args: ['${chat.joinRequests.length}']),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JoinRequestsScreen(chatId: widget.chatId),
                  ),
                ),
              ),
              _buildTile(
                icon: Icons.security_rounded,
                title: context.t('permissions'),
                subtitle: context.t('controlPermissions'),
                onTap: () => _showPermissionsDialog(chat),
              ),
              _buildTile(
                icon: Icons.block_rounded,
                title: context.t('contentProtection'),
                subtitle: chat.restrictSaving ? context.t('savingRestricted') : context.t('savingAllowed'),
                trailing: Switch(
                  value: chat.restrictSaving,
                  onChanged: (v) => _chatService.toggleRestrictSaving(widget.chatId, v),
                ),
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.admin_panel_settings_rounded,
                title: context.t('administrators'),
                subtitle: context.t('adminCount', args: ['${chat.admins.length + 1}']),
                onTap: () => _showAdminsDialog(chat),
              ),
              _buildTile(
                icon: Icons.timer_rounded,
                title: context.t('slowMode'),
                subtitle: chat.slowModeSeconds > 0 ? context.t('slowModeDelay', args: ['${chat.slowModeSeconds}']) : context.t('slowModeOff'),
                onTap: () => _showSlowModeDialog(chat),
              ),
              
              const SizedBox(height: AppConstants.lg),
              _buildSectionHeader(context.t('invitations')),
              _buildTile(
                icon: Icons.link_rounded,
                title: context.t('inviteLinks'),
                subtitle: context.t('manageLinks'),
                onTap: () => _showInviteLinksDialog(chat),
              ),
              _buildTile(
                icon: Icons.block_flipped,
                title: context.t('removedUsers'),
                subtitle: context.t('bannedCount', args: ['${chat.bannedUsers.length}']),
                onTap: () => _showBannedUsersDialog(chat),
              ),

              const SizedBox(height: AppConstants.lg),
              _buildSectionHeader(context.t('activity')),
              _buildTile(
                icon: Icons.history_rounded,
                title: context.t('recentActions'),
                subtitle: context.t('viewLogs'),
                onTap: () => _showLogsDialog(chat),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppConstants.sm),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  // --- Sub-Dialogs / Sections ---

  void _showPermissionsDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final p = chat.permissions;
          return Container(
            padding: const EdgeInsets.all(AppConstants.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.t('memberPermissions'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPermissionSwitch(context.t('sendMessages'), p['sendMessages'] ?? true, (v) {
                  p['sendMessages'] = v;
                  _chatService.updateGroupPermissions(widget.chatId, p);
                  setModalState(() {});
                }),
                _buildPermissionSwitch(context.t('sendMedia'), p['sendMedia'] ?? true, (v) {
                  p['sendMedia'] = v;
                  _chatService.updateGroupPermissions(widget.chatId, p);
                  setModalState(() {});
                }),
                _buildPermissionSwitch(context.t('addUsers'), p['addUsers'] ?? true, (v) {
                  p['addUsers'] = v;
                  _chatService.updateGroupPermissions(widget.chatId, p);
                  setModalState(() {});
                }),
                _buildPermissionSwitch(context.t('pinMessages'), p['pinMessages'] ?? true, (v) {
                  p['pinMessages'] = v;
                  _chatService.updateGroupPermissions(widget.chatId, p);
                  setModalState(() {});
                }),
                _buildPermissionSwitch(context.t('changeInfo'), p['changeInfo'] ?? true, (v) {
                  p['changeInfo'] = v;
                  _chatService.updateGroupPermissions(widget.chatId, p);
                  setModalState(() {});
                }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile.adaptive(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  void _showSlowModeDialog(ChatModel chat) {
    double value = chat.slowModeSeconds.toDouble();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('slowMode')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value == 0 ? context.t('slowModeOff') : context.t('slowModeDelay', args: ['${value.toInt()}'])),
              Slider(
                value: value,
                min: 0,
                max: 3600,
                divisions: 120,
                onChanged: (v) => setState(() => value = v),
              ),
              const Text('Members will be able to send one message every selected period.', 
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
            TextButton(
              onPressed: () {
                _chatService.setSlowMode(widget.chatId, value.toInt());
                Navigator.pop(context);
              },
              child: Text(context.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  // --- Admins Management ---
  void _showAdminsDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(context.t('administrators'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chat.participants.length,
                itemBuilder: (context, index) {
                  final uid = chat.participants[index];
                  final isOwner = uid == chat.adminId;
                  final isAdmin = chat.admins.contains(uid) || isOwner;

                  return FutureBuilder<UserModel?>(
                    future: _userService.getUser(uid),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final title = chat.adminTitles[uid] ?? (isOwner ? context.t('owner') : context.t('admin'));
                      
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null),
                        title: Text(user?.displayName ?? 'User'),
                        subtitle: Text(isAdmin ? title : context.t('member'), style: TextStyle(color: isAdmin ? Colors.blue : Colors.grey)),
                        trailing: isOwner 
                          ? const Icon(Icons.star, color: Colors.amber)
                          : Switch(
                              value: isAdmin,
                              onChanged: (val) {
                                _chatService.toggleAdmin(widget.chatId, uid, val);
                                Navigator.pop(context);
                              },
                            ),
                        onTap: isAdmin && !isOwner ? () => _showEditTitleDialog(uid, title) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTitleDialog(String uid, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('adminTitle')),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: context.t('adminTitleHint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () {
              _chatService.setAdminTitle(widget.chatId, uid, controller.text);
              Navigator.pop(context);
              Navigator.pop(context); // Close sheet
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  // --- Invite Links ---
  void _showInviteLinksDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.t('inviteLinks'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCreateLinkDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<InviteLink>>(
              stream: _chatService.getInviteLinks(widget.chatId),
              builder: (context, snapshot) {
                final links = snapshot.data ?? [];
                if (links.isEmpty) return Center(child: Text(context.t('noActiveLinks')));
                return ListView.builder(
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    final linkCode = link.id;
                    return Dismissible(
                      key: ValueKey(link.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(context.t('deleteLink')),
                          content: Text(context.t('deleteLinkConfirm')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('delete'))),
                          ],
                        ),
                      ).then((v) => v ?? false),
                      onDismissed: (_) => _chatService.deleteInviteLink(widget.chatId, link.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: Colors.red,
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.link_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(link.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(linkCode, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            if (link.expiresAt != null)
                              Text(
                                '${context.t('expires')}: ${_formatDate(link.expiresAt!)}',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${link.joinCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: linkCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.t('linkCopied'))),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateLinkDialog() {
    final controller = TextEditingController();
    String selectedDuration = 'permanent';
    final durations = ['permanent', '1h', '8h', '1d', '7d', '30d'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.t('newInviteLink')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: controller, decoration: InputDecoration(hintText: context.t('linkNameHint'))),
              const SizedBox(height: 16),
              Text(context.t('expires'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: durations.map((d) => ChoiceChip(
                  label: Text(context.t(d)),
                  selected: selectedDuration == d,
                  onSelected: (_) => setDialogState(() => selectedDuration = d),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
            TextButton(
              onPressed: () {
                DateTime? expiresAt;
                if (selectedDuration != 'permanent') {
                  final hours = int.tryParse(selectedDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  if (selectedDuration.contains('h')) {
                    expiresAt = DateTime.now().add(Duration(hours: hours));
                  } else {
                    expiresAt = DateTime.now().add(Duration(days: hours));
                  }
                }
                _chatService.createInviteLink(
                  widget.chatId, _authService.currentUser!.uid, controller.text,
                  expiresAt: expiresAt,
                );
                Navigator.pop(context);
              },
              child: Text(context.t('create')),
            ),
          ],
        ),
      ),
    );
  }

  // --- Banned Users ---
  void _showBannedUsersDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(context.t('bannedUsers'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: chat.bannedUsers.isEmpty 
              ? Center(child: Text(context.t('noBannedUsers')))
              : ListView.builder(
                  itemCount: chat.bannedUsers.length,
                  itemBuilder: (context, index) {
                    final uid = chat.bannedUsers[index];
                    return FutureBuilder<UserModel?>(
                      future: _userService.getUser(uid),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null),
                          title: Text(user?.displayName ?? 'User'),
                          trailing: TextButton(
                            onPressed: () => _chatService.unbanUser(widget.chatId, uid),
                            child: Text(context.t('unban')),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // --- Group Username ---
  void _editGroupUsername(ChatModel chat) {
    final controller = TextEditingController(text: chat.groupUsername ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('groupUsername')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '@',
            hintText: context.t('usernameHint'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () {
              final username = controller.text.trim();
              if (username.isNotEmpty) {
                _chatService.updateGroupInfo(widget.chatId, username: username);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  // --- Logs ---
  void _showLogsDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(context.t('recentActions'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<List<AdminAction>>(
                stream: _chatService.getAdminActions(widget.chatId),
                builder: (context, snapshot) {
                  final actions = snapshot.data ?? [];
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.gavel)),
                        title: Text('${action.adminName} ${action.description}'),
                        subtitle: Text(action.timestamp.toString().substring(0, 16)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

