import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../utils/translations.dart';

import '../../widgets/chat_list_item.dart';
import '../chat/archived_chats_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/support_chat_screen.dart';
import '../settings/faq_screen.dart';
import '../settings/privacy_policy_screen.dart';
import 'new_chat_screen.dart';
import 'new_group_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/saved_messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isSearching = false;

  // Chat filter tabs
  int _selectedFilter = 0;
  final List<String> _filterLabels = ['all', 'personal', 'groups', 'unread'];

  Stream<List<ChatModel>>? _chatStream;
  String? _lastChatUid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t('newConversation'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                _buildBottomSheetItem(
                  context,
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFF007AFF),
                  title: context.t('newChat'),
                  subtitle: context.t('startWithContact'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewChatScreen()),
                    );
                  },
                ),
                _buildBottomSheetItem(
                  context,
                  icon: Icons.group_add_rounded,
                  color: const Color(0xFF34C759),
                  title: context.t('newGroup'),
                  subtitle: context.t('chatWithMultiple'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NewGroupScreen()),
                    );
                  },
                ),
                _buildBottomSheetItem(
                  context,
                  icon: Icons.link_rounded,
                  color: const Color(0xFF5856D6),
                  title: context.t('joinByLink'),
                  subtitle: context.t('enterInviteLink'),
                  onTap: () {
                    Navigator.pop(context);
                    _showJoinGroupDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
      onTap: onTap,
    );
  }

  void _showJoinGroupDialog() {
    final linkController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.t('joinGroup')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('joinGroupDesc')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      hintText: context.t('inviteCode'),
                      prefixIcon: const Icon(Icons.qr_code_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.t('cancel')),
                ),
                isJoining
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          final input = linkController.text.trim();
                          if (input.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.t('enterLink'))),
                            );
                            return;
                          }

                          setDialogState(() => isJoining = true);

                          try {
                            final chat = await _chatService.joinGroupByInviteLink(input);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.t('joinedGroup', args: [chat.groupName ?? 'Group']))),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: chat.chatId,
                                    otherUserName: chat.groupName ?? 'Group Chat',
                                    otherUserId: '',
                                    isGroup: true,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isJoining = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                              );
                            }
                          }
                        },
                        child: Text(context.t('joinGroup')),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  /// Filters chats based on the selected tab.
  List<ChatModel> _filterChats(List<ChatModel> chats) {
    final uid = _authService.currentUser?.uid;

    // Filter out archived chats
    var filtered = chats.where((c) => !c.archivedBy.containsKey(uid)).toList();

    // Apply text search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((chat) {
        final name = chat.isGroup
            ? (chat.groupName ?? '').toLowerCase()
            : chat.lastMessage.toLowerCase();
        return name.contains(_searchQuery) ||
            chat.lastMessage.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply tab filter
    switch (_selectedFilter) {
      case 1: // Personal
        filtered = filtered.where((c) => !c.isGroup).toList();
        break;
      case 2: // Groups
        filtered = filtered.where((c) => c.isGroup).toList();
        break;
      case 3: // Unread
        filtered = filtered
            .where((c) => (c.unreadCounts[uid] ?? 0) > 0)
            .toList();
        break;
    }

    // Sort: pinned chats at top (by pinnedAt descending), then by lastMessageTime
    filtered.sort((a, b) {
      final aPinned = a.pinnedBy.containsKey(uid);
      final bPinned = b.pinnedBy.containsKey(uid);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> pages = [
      _buildChatList(user),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0 ? _buildHomeAppBar(context, colorScheme) : AppBar(
        title: Text(
          context.t('settings'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      drawer: _currentIndex == 0 ? _buildDrawer(user, context) : null,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showNewChatOptions,
              elevation: 4,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.edit_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(context, colorScheme),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context, ColorScheme colorScheme) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: context.t('searchChats'),
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      );
    }

    return AppBar(
      title: Text(
        context.t('appName'),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            setState(() => _isSearching = true);
          },
        ),
      ],
    );
  }

  Widget _buildChatList(User? user) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = user?.uid;
    if (uid != null && uid != _lastChatUid) {
      _lastChatUid = uid;
      _chatStream = _chatService.getUserChats(uid);
    }

    return Column(
      children: [
        // Filter Tabs
        Container(
          height: 44,
          margin: const EdgeInsets.only(top: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _filterLabels.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    context.t(_filterLabels[index]),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: colorScheme.surfaceContainerLow,
                  selectedColor: colorScheme.primary,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outlineVariant.withAlpha(100),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = index);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),

        // Chat List
        Expanded(
          child: StreamBuilder<List<ChatModel>>(
            stream: _chatStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return _buildLoadingShimmer(context);
              }

              if (snapshot.hasError) {
                // ignore: avoid_print
                print('Chat list error: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.error.withAlpha(150)),
                        const SizedBox(height: 12),
                        Text(context.t('errorLoading'), style: TextStyle(color: colorScheme.error)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'.length > 80
                            ? '${snapshot.error}'.substring(0, 80)
                            : '${snapshot.error}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              _lastChatUid = null;
                              _chatStream = null;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(context.t('retry')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allChats = snapshot.data ?? [];
              final uid = user?.uid;
              final archivedCount = allChats.where((c) => c.archivedBy.containsKey(uid)).length;
              final chats = _filterChats(allChats);

              if (allChats.isEmpty) {
                return _buildEmptyState(context, isFiltered: false);
              }

              if (chats.isEmpty) {
                return _buildEmptyState(context, isFiltered: true);
              }

              return Column(
                children: [
                  // Archived Chats banner
                  if (archivedCount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Material(
                        color: colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ArchivedChatsScreen(
                              chats: allChats.where((c) => c.archivedBy.containsKey(uid)).toList(),
                              currentUserId: uid ?? '',
                            )),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                Text(context.t('archivedChats'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const Spacer(),
                                Text('$archivedCount', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: chats.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(left: 82),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        return ChatListItem(
                          chat: chats[index],
                          currentUserId: user?.uid ?? '',
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Avatar shimmer
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withAlpha(100),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120 + (index % 3) * 30.0,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withAlpha(100),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200 + (index % 2) * 40.0,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withAlpha(60),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.filter_list_off_rounded : Icons.chat_bubble_outline_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? context.t('noMatches') : context.t('noConversations'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? context.t('adjustFilter')
                  : context.t('tapToStart'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: _showNewChatOptions,
                child: Text(context.t('startConversation')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.chat_bubble_outline_rounded,
                  Icons.chat_bubble_rounded, context.t('chats')),
              _buildNavItem(context, 1, Icons.settings_outlined,
                  Icons.settings_rounded, context.t('settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData inactiveIcon,
      IconData activeIcon, String label) {
    bool isActive = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 24,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(User? user, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String displayName = user?.displayName ?? 'Flow User';
          String role = 'user';
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              displayName = data['displayName'] ?? displayName;
              role = data['role'] ?? 'user';
            }
          }
          final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'F';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(200),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.onPrimary.withAlpha(50),
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? Text(initial,
                              style: TextStyle(
                                fontSize: 28,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleBadgeColor(role),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimary.withAlpha(200),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: Text(context.t('savedMessages')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavedMessagesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(context.t('settings')),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic_rounded),
                title: Text(context.t('supportChat')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: Text(context.t('faq')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(context.t('privacyPolicy')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.exit_to_app_rounded, color: colorScheme.error),
                title: Text(context.t('logout'), style: TextStyle(color: colorScheme.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleBadgeColor(String role) {
    switch (role) {
      case 'developer':
        return Colors.deepPurpleAccent;
      case 'admin':
        return Colors.redAccent;
      case 'vip':
        return Colors.orange;
      default:
        return Colors.white24;
    }
  }
}
