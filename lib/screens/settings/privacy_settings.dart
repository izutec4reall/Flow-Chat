import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/translations.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final _authService = AuthService();
  final _userService = UserService();

  Future<void> _unblockUser(String uid, String blockedUid, String name) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'blocking': FieldValue.arrayRemove([blockedUid]),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('unblockedMsg', args: [name]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('privacySecurity'))),
      body: uid == null
          ? Center(child: Text(context.t('notLoggedIn')))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final blocking = data != null ? List<String>.from(data['blocking'] ?? []) : <String>[];

                return ListView(
                  children: [
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: colorScheme.surfaceContainerHighest.withAlpha(60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: colorScheme.error.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.block_rounded, size: 20, color: colorScheme.error),
                                ),
                                const SizedBox(width: 12),
                                Text(context.t('blockedUsers'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const Spacer(),
                                Text('${blocking.length}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                              ],
                            ),
                          ),
                          if (blocking.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Text(context.t('noBlocked'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                            )
                          else
                            ...blocking.map((blockedId) => FutureBuilder<UserModel?>(
                                  future: _userService.getUser(blockedId),
                                  builder: (context, userSnapshot) {
                                    final user = userSnapshot.data;
                                    return Column(
                                      children: [
                                        Divider(height: 1, indent: 16, endIndent: 16,
                                            color: colorScheme.outlineVariant.withAlpha(60)),
                                        ListTile(
                                          leading: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: colorScheme.primaryContainer,
                                            backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                                            child: user?.photoUrl == null
                                                ? Text(user?.displayName.isNotEmpty == true
                                                    ? user!.displayName[0].toUpperCase() : 'U',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary))
                                                : null,
                                          ),
                                          title: Text(user?.displayName ?? 'Unknown', style: const TextStyle(fontSize: 15)),
                                          subtitle: Text(user?.username != null ? '@${user!.username}' : context.t('blockedUser'),
                                              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                                          trailing: TextButton(
                                            onPressed: () => _unblockUser(uid, blockedId, user?.displayName ?? 'User'),
                                            child: Text(context.t('unblock')),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        context.t('blockedInfo'),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
