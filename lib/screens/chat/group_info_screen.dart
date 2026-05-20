import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_model.dart';
import '../../models/group_models.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/constants.dart';
import 'package:flutter/services.dart';
import '../../utils/translations.dart';

import 'group_management_screen.dart';
import 'group_members_screen.dart';
import 'join_requests_screen.dart';
import 'recent_actions_screen.dart';
import 'shared_media_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatModel>(
      stream: _chatService.getChatStream(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final chat = snapshot.data!;
        final currentUserId = _authService.currentUser?.uid;
        final isParticipant = chat.participants.contains(currentUserId);
        final isAdmin = chat.admins.contains(currentUserId) || chat.adminId == currentUserId;
        final isPending = chat.joinRequests.contains(currentUserId);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(chat),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (isAdmin && chat.joinRequests.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: AppConstants.md, vertical: AppConstants.sm),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_alt_1_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.t('pendingRequests', args: ['${chat.joinRequests.length}']),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => JoinRequestsScreen(chatId: widget.chatId)),
                              ),
                              child: Text(context.t('review')),
                            ),
                          ],
                        ),
                      ),
                    _buildBioSection(chat),
                    
                    if (!isParticipant)
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.lg),
                        child: ElevatedButton(
                          onPressed: isPending ? null : () => _chatService.requestToJoin(widget.chatId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPending ? Colors.grey : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isPending ? context.t('requested') : context.t('requestToJoin')),
                        ),
                      )
                    else ...[
                      _buildQuickActions(chat),
                      const Divider(height: 1),
                      
                      // --- Options Section ---
                      _buildOptionTile(
                        icon: Icons.people_outline_rounded,
                        title: context.t('members'),
                        subtitle: context.t('memberCount', args: ['${chat.participants.length}']),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GroupMembersScreen(chatId: widget.chatId)),
                        ),
                      ),
                      
                      if (isAdmin)
                        _buildOptionTile(
                          icon: Icons.settings_outlined,
                          title: context.t('groupSettings'),
                          subtitle: context.t('permissionsDesc'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GroupManagementScreen(chatId: widget.chatId)),
                          ),
                        ),
                      
                      if (isAdmin)
                        _buildOptionTile(
                          icon: Icons.history_rounded,
                          title: context.t('recentActions'),
                          subtitle: context.t('viewLogs'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RecentActionsScreen(chatId: widget.chatId)),
                          ),
                        ),
                      
                      _buildOptionTile(
                        icon: Icons.notifications_none_rounded,
                        title: context.t('notifications'),
                        subtitle: context.t('enabled'),
                        onTap: () {},
                      ),
                      
                      const Divider(height: 32, thickness: 8, color: Colors.black12),
                      _buildSectionHeader(context.t('sharedContent'), onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SharedMediaScreen(chatId: widget.chatId)),
                      )),
                    ],
                  ],
                ),
              ),
              
              if (isParticipant)
                _buildSharedMediaPreview(chat),
            ],
          ),
        );
      },
    );
  }

  void _editGroupName(ChatModel chat) {
    final controller = TextEditingController(text: chat.groupName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('groupName')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.t('groupNameHint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _chatService.updateGroupInfo(widget.chatId, name: controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  void _editGroupDescription(ChatModel chat) {
    final controller = TextEditingController(text: chat.groupDescription ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('description')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: context.t('descHint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () {
              _chatService.updateGroupInfo(widget.chatId, description: controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _editGroupPhoto(ChatModel chat) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await File(file.path).readAsBytes();
    final cloudinary = CloudinaryService();
    final url = await cloudinary.uploadFile(bytes, 'group_${widget.chatId}', 'groups');
    if (url != null && context.mounted) {
      _chatService.updateGroupIcon(widget.chatId, url);
    }
  }

  Widget _buildAppBar(ChatModel chat) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = chat.admins.contains(_authService.currentUser?.uid) || chat.adminId == _authService.currentUser?.uid;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: GestureDetector(
          onTap: isAdmin ? () => _editGroupName(chat) : null,
          child: Text(chat.groupName ?? context.t('groupInfoTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'avatar_${chat.chatId}',
              child: chat.groupIcon != null
                  ? Image.network(chat.groupIcon!, fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.primaryContainer,
                      child: Icon(Icons.group, size: 80, color: colorScheme.onPrimaryContainer),
                    ),
            ),
            if (isAdmin)
              Positioned(
                bottom: 8, right: 8,
                child: GestureDetector(
                  onTap: () => _editGroupPhoto(chat),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(ChatModel chat) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = chat.admins.contains(_authService.currentUser?.uid) || chat.adminId == _authService.currentUser?.uid;
    final desc = chat.groupDescription;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.lg),
      child: GestureDetector(
        onTap: isAdmin ? () => _editGroupDescription(chat) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.t('about'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const Spacer(),
                if (isAdmin)
                  Icon(Icons.edit_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              desc ?? context.t('noDescription'),
              style: TextStyle(
                fontSize: 15,
                color: desc != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ChatModel chat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionItem(Icons.search, context.t('search'), onTap: () {
            Navigator.pop(context, 'search');
          }),
          _actionItem(Icons.add_link, context.t('inviteCode'), onTap: () {
            _showInviteLinkDialog(chat);
          }),
          _actionItem(Icons.logout, context.t('leave'), color: Colors.red, onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(context.t('leaveGroup')),
                content: Text(context.t('leaveGroupConfirm')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(context.t('leaveButton'), style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await _chatService.leaveGroup(widget.chatId);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          }),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, {Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color ?? Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  void _showInviteLinkDialog(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(context.t('groupInviteLink'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(context.t('shareLink'), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            StreamBuilder<List<InviteLink>>(
              stream: _chatService.getInviteLinks(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final links = snapshot.data!;
                if (links.isEmpty) {
                  return ElevatedButton(
                    onPressed: () async {
                      await _chatService.createInviteLink(widget.chatId, _authService.currentUser!.uid, 'Primary Link');
                    },
                    child: Text(context.t('generateLink')),
                  );
                }
                final sorted = List<InviteLink>.from(links)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  children: [
                    SizedBox(
                      height: sorted.length > 3 ? 200 : sorted.length * 72.0,
                      child: ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (_, i) {
                          final link = sorted[i];
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(link.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(
                                          link.id,
                                          style: TextStyle(
                                            fontSize: 12,
                                            letterSpacing: 1,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        if (link.expiresAt != null)
                                          Text(
                                            '${context.t('expires')}: ${link.expiresAt!.day}/${link.expiresAt!.month}',
                                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(text: link.id));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('linkCopied'))));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        for (final link in links.where((l) => l.isExpired)) {
                          _chatService.deleteInviteLink(widget.chatId, link.id);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.t('expiredLinksCleared'))),
                        );
                      },
                      icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                      label: Text(context.t('clearExpiredLinks')),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest.withAlpha(60),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedMediaPreview(ChatModel chat) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}
