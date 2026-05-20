import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/translations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('userManagement')), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.t('searchUsers'),
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final users = snap.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final name = (data['displayName'] as String? ?? '').toLowerCase();
                  final uid = doc.id.toLowerCase();
                  return email.contains(_searchQuery) || name.contains(_searchQuery) || uid.contains(_searchQuery);
                }).toList();
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(context.t('noUsersFound'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(context.t('totalUsers', args: ['${users.length}']), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final doc = users[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;
                          final name = data['displayName'] ?? 'N/A';
                          final email = data['email'] ?? '';
                          final role = data['role'] ?? 'user';
                          final banned = data['banned'] == true;
                          final photoUrl = data['photoUrl'] as String?;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null ? Text((name is String && name.isNotEmpty ? name[0] : '?').toUpperCase()) : null,
                              ),
                              title: Text(name is String ? name : 'N/A', maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '$email  •  ${context.t(role == 'developer' ? 'roleDeveloper' : 'roleUser')}${banned ? '  •  ' + context.t('bannedUsers') : ''}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12),
                              ),
                              trailing: banned ? Icon(Icons.block_rounded, color: Colors.red.shade300, size: 20) : null,
                              onTap: () => _showUserActions(context, uid, data),
                            ),
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
      ),
    );
  }

  void _showUserActions(BuildContext context, String uid, Map<String, dynamic> data) {
    final name = data['displayName'] ?? uid;
    final role = data['role'] ?? 'user';
    final banned = data['banned'] == true;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(name is String ? name : uid, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              if (banned)
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: Colors.green),
                  title: Text(context.t('unbanUser')),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _firestore.collection('users').doc(uid).update({'banned': false});
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: Colors.red),
                  title: Text(context.t('banUser')),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _firestore.collection('users').doc(uid).update({'banned': true});
                  },
                ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text(context.t('changeRole')),
                subtitle: Text(context.t(role == 'developer' ? 'roleDeveloper' : 'roleUser')),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRolePicker(context, uid, role);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade300),
                title: Text(context.t('deleteUser'), style: TextStyle(color: Colors.red.shade300)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(context.t('deleteUser')),
                      content: Text('${context.t('deleteUser')} $name?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('cancel'))),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(context.t('delete'), style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _firestore.collection('users').doc(uid).delete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRolePicker(BuildContext context, String uid, String currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.t('changeRole')),
        children: [
          ListTile(
            title: Text(context.t('roleUser')),
            leading: Radio<String>(
              value: 'user',
              groupValue: currentRole,
              onChanged: (v) async {
                Navigator.pop(ctx);
                await _firestore.collection('users').doc(uid).update({'role': v});
              },
            ),
            onTap: () async {
              Navigator.pop(ctx);
              await _firestore.collection('users').doc(uid).update({'role': 'user'});
            },
          ),
          ListTile(
            title: Text(context.t('roleDeveloper')),
            leading: Radio<String>(
              value: 'developer',
              groupValue: currentRole,
              onChanged: (v) async {
                Navigator.pop(ctx);
                await _firestore.collection('users').doc(uid).update({'role': v});
              },
            ),
            onTap: () async {
              Navigator.pop(ctx);
              await _firestore.collection('users').doc(uid).update({'role': 'developer'});
            },
          ),
        ],
      ),
    );
  }
}
