import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../utils/translations.dart';
import 'user_management_screen.dart';

final _firestore = FirebaseFirestore.instance;
final _configRef = _firestore.collection('config').doc('app');

class DeveloperModeScreen extends StatefulWidget {
  const DeveloperModeScreen({super.key});

  @override
  State<DeveloperModeScreen> createState() => _DeveloperModeScreenState();
}

class _DeveloperModeScreenState extends State<DeveloperModeScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('developerMode')), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _configRef.snapshots(),
        builder: (context, snap) {
          final config = snap.data?.data() as Map<String, dynamic>? ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, user),
              const SizedBox(height: 16),
              _buildSection(context, context.t('remoteControl')),
              _buildCard(context, Icons.campaign_rounded, context.t('systemBroadcast'), context.t('broadcastSub'), () => _showBroadcastDialog(context, config)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.construction_rounded, context.t('maintenanceMode'), config['maintenanceMode'] == true ? context.t('maintenanceOn') : context.t('maintenanceOff'), () => _showMaintenanceDialog(context, config)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.flag_rounded, context.t('featureFlags'), context.t('featureFlagsSub'), () => _showFeatureFlagsDialog(context, config)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.system_update_rounded, context.t('forceUpdate'), '${context.t('forceUpdateSub', args: [config['minVersion'] ?? '1.0.0'])}', () => _showForceUpdateDialog(context, config)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.lock_rounded, context.t('appPassword'), config['appPassword'] != null ? 'Enabled' : 'Disabled', () => _showAppPasswordDialog(context, config)),
              const SizedBox(height: 16),
              _buildSection(context, context.t('firebase')),
              _buildCard(context, Icons.local_fire_department_rounded, context.t('firebaseConsole'), context.t('firebaseConsoleSub'), () => _showFirebaseConsole(context)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.person_search_rounded, context.t('userLookup'), context.t('userLookupSub'), () => _showUserLookup(context)),
              const SizedBox(height: 12),
              _buildCard(context, Icons.people_rounded, context.t('userManagement'), context.t('userList'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
              const SizedBox(height: 16),
              _buildSection(context, context.t('appInfo')),
              _buildInfoRow(context, context.t('versionVal'), '1.0.0'),
              _buildInfoRow(context, context.t('uidLabel'), user?.uid ?? 'N/A'),
              _buildInfoRow(context, context.t('emailLabel'), user?.email ?? 'N/A'),
              _buildInfoRow(context, context.t('maintenanceMode'), config['maintenanceMode'] == true ? context.t('on') : context.t('off')),
              _buildInfoRow(context, context.t('forceUpdate'), config['minVersion'] ?? '1.0.0'),
              _buildInfoRow(context, context.t('systemBroadcast'), config['broadcast']?['active'] == true ? context.t('active') : context.t('inactive')),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.developer_mode_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('developerMode'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? 'N/A', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  // ─── System Broadcast ─────────────────────────────────────────
  void _showBroadcastDialog(BuildContext context, Map<String, dynamic> config) {
    final msgCtrl = TextEditingController(text: (config['broadcast'] as Map?)?['message'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        final broadcast = (config['broadcast'] as Map?) ?? {};
        final isActive = broadcast['active'] == true;
        return AlertDialog(
          title: Text(context.t('systemBroadcast')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.t('broadcastDesc'), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: msgCtrl, decoration: InputDecoration(hintText: context.t('broadcastHint'), border: const OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(isActive ? context.t('active') : context.t('inactive')),
              value: isActive,
              onChanged: (v) async {
                await _configRef.set({'broadcast.active': v}, SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
            TextButton(onPressed: () async {
              await _configRef.set({
                'broadcast': {'message': msgCtrl.text.trim(), 'active': true}
              }, SetOptions(merge: true));
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: Text(context.t('send'))),
          ],
        );
      }),
    );
  }

  // ─── Maintenance Mode ─────────────────────────────────────────
  void _showMaintenanceDialog(BuildContext context, Map<String, dynamic> config) {
    final msgCtrl = TextEditingController(text: config['maintenanceMessage'] ?? '');
    final isEnabled = config['maintenanceMode'] == true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(context.t('maintenanceMode')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              title: Text(isEnabled ? context.t('maintenanceOn') : context.t('maintenanceOff')),
              value: isEnabled,
              onChanged: (v) async {
                await _configRef.set({'maintenanceMode': v}, SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            TextField(controller: msgCtrl, decoration: InputDecoration(hintText: context.t('maintenanceHint'), border: const OutlineInputBorder()), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close'))),
            TextButton(onPressed: () async {
              await _configRef.set({'maintenanceMessage': msgCtrl.text.trim()}, SetOptions(merge: true));
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: Text(context.t('send'))),
          ],
        );
      }),
    );
  }

  // ─── Feature Flags ────────────────────────────────────────────
  void _showFeatureFlagsDialog(BuildContext context, Map<String, dynamic> config) {
    final flags = Map<String, bool>.from(config['featureFlags'] ?? {});
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(context.t('featureFlags')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ...flags.entries.map((e) => SwitchListTile(
                  title: Text(e.key),
                  value: e.value,
                  onChanged: (v) async {
                    await _configRef.set({'featureFlags.${e.key}': v}, SetOptions(merge: true));
                    setState(() => flags[e.key] = v);
                  },
                )),
                TextButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController();
                    showDialog(
                      context: ctx,
                      builder: (ctx2) => AlertDialog(
                        title: Text(context.t('addFlag')),
                        content: TextField(controller: nameCtrl, decoration: InputDecoration(hintText: context.t('flagName'))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx2), child: Text(context.t('cancel'))),
                          TextButton(onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isNotEmpty) {
                              await _configRef.set({'featureFlags.$name': false}, SetOptions(merge: true));
                            }
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          }, child: Text(context.t('addFlag'))),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.t('addFlag')),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close')))],
        );
      }),
    );
  }

  // ─── Force Update ─────────────────────────────────────────────
  void _showForceUpdateDialog(BuildContext context, Map<String, dynamic> config) {
    final ctrl = TextEditingController(text: config['minVersion'] ?? '1.0.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('forceUpdate')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.t('forceUpdateDesc'), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, decoration: InputDecoration(hintText: context.t('forceUpdateHint'), border: const OutlineInputBorder(), prefixText: 'v')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          TextButton(onPressed: () async {
            await _configRef.set({'minVersion': ctrl.text.trim()}, SetOptions(merge: true));
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(context.t('set'))),
        ],
      ),
    );
  }

  // ─── User Lookup ──────────────────────────────────────────────
  void _showUserLookup(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text(context.t('userLookup')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(hintText: context.t('searchHint'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.search)),
                  onSubmitted: (v) => _lookupUser(ctx, v.trim(), setState),
                ),
                const SizedBox(height: 12),
                _buildUserResult(ctx),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close')))],
        );
      }),
    );
  }

  Widget? _userResultWidget;

  Widget _buildUserResult(BuildContext ctx) {
    if (_userResultWidget == null) return const SizedBox.shrink();
    return _userResultWidget!;
  }

  Future<void> _lookupUser(BuildContext ctx, String query, StateSetter setDialogState) async {
    setDialogState(() => _userResultWidget = const Center(child: CircularProgressIndicator()));

    // Try by UID first
    DocumentSnapshot? doc;
    if (query.contains('@')) {
      final snap = await _firestore.collection('users').where('email', isEqualTo: query).limit(1).get();
      if (snap.docs.isNotEmpty) doc = snap.docs.first;
    }
    doc ??= await _firestore.collection('users').doc(query).get();

    if (!doc.exists) {
      setDialogState(() => _userResultWidget = Text(context.t('userNotFoundError'), style: const TextStyle(color: Colors.red)));
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final role = data['role'] ?? 'user';

    setDialogState(() {
      _userResultWidget = Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.t('uidLabel')}: $uid', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text('${context.t('emailLabel')}: ${data['email'] ?? 'N/A'}'),
              Text('${context.t('nameLabel')}: ${data['displayName'] ?? 'N/A'}'),
              Text('${context.t('roleLabel')}: $role'),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (role != 'developer')
                    TextButton(
                      onPressed: () async {
                        await _firestore.collection('users').doc(uid).update({'role': 'developer'});
                        _lookupUser(ctx, query, setDialogState);
                      },
                      child: Text(context.t('makeDeveloper'), style: const TextStyle(fontSize: 12)),
                    ),
                  if (role == 'developer')
                    TextButton(
                      onPressed: () async {
                        await _firestore.collection('users').doc(uid).update({'role': 'user'});
                        _lookupUser(ctx, query, setDialogState);
                      },
                      child: Text(context.t('removeDeveloper'), style: const TextStyle(fontSize: 12)),
                    ),
                  TextButton(
                    onPressed: () async {
                      await _firestore.collection('users').doc(uid).delete();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(context.t('deleteUser'), style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                  const SizedBox(width: 4),
                  if (data['banned'] != true)
                    TextButton(
                      onPressed: () async {
                        await _firestore.collection('users').doc(uid).update({'banned': true});
                        _lookupUser(ctx, query, setDialogState);
                      },
                      child: Text(context.t('banUser'), style: const TextStyle(fontSize: 12, color: Colors.orange)),
                    ),
                  if (data['banned'] == true)
                    TextButton(
                      onPressed: () async {
                        await _firestore.collection('users').doc(uid).update({'banned': false});
                        _lookupUser(ctx, query, setDialogState);
                      },
                      child: Text(context.t('unbanUser'), style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showAppPasswordDialog(BuildContext context, Map<String, dynamic> config) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('appPassword')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t('appPasswordDesc')),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: context.t('appPasswordHint'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('cancel'))),
          if (config['appPassword'] != null)
            TextButton(
              onPressed: () async {
                await _configRef.set({'appPassword': null}, SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(context.t('removeAppPassword'), style: const TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () async {
              final text = passwordController.text.trim();
              if (text.isNotEmpty && RegExp(r'^\d+$').hasMatch(text)) {
                await _configRef.set({'appPassword': text}, SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(context.t('setAppPassword')),
          ),
        ],
      ),
    );
  }

  void _showFirebaseConsole(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('firebaseConsole')),
        content: const Text('Open your Firebase Console at:\nhttps://console.firebase.google.com\n\nLog in with your Firebase account to view Firestore data, Authentication, and more.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close')))],
      ),
    );
  }
}
