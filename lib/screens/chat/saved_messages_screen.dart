import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/translations.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'full_screen_image_viewer.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('savedMessagesTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(context.t('forwardedMessages'), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('savedMessages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark_outline_rounded, size: 36, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(context.t('noSavedMessages'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text(context.t('forwardHint'),
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDate(docs);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: grouped.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = grouped[sectionIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(label: section.label),
                        const SizedBox(height: 4),
                        ...section.items.map((doc) => _SavedMessageTile(
                              doc: doc,
                              colorScheme: colorScheme,
                              onDelete: () => _deleteMessage(uid, doc.id),
                              onCopy: (text) {
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.t('textCopied'))),
                                );
                              },
                              onImageTap: (url) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageViewer(imageUrl: url, heroTag: 'saved_${doc.id}'),
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  List<_DateSection> _groupByDate(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    String _label(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      if (d == today) return context.t('today');
      if (d == yesterday) return context.t('yesterday');
      if (d.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) return context.t('thisWeek');
      if (d.isAfter(lastWeekStart.subtract(const Duration(days: 1)))) return context.t('lastWeek');
      if (d.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) return '${months[date.month - 1]} ${date.year}';
      return '${date.year}';
    }

    final groups = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final label = _label(ts);
      groups.putIfAbsent(label, () => []).add(doc);
    }

    final order = [context.t('today'), context.t('yesterday'), context.t('thisWeek'), context.t('lastWeek')];
    final sorted = groups.entries.toList()..sort((a, b) {
      final ai = order.indexOf(a.key);
      final bi = order.indexOf(b.key);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return -a.key.compareTo(b.key);
    });

    return sorted.map((e) => _DateSection(label: e.key, items: e.value)).toList();
  }

  Future<void> _deleteMessage(String uid, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('savedMessages').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('deleted'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('errorOccurred'))),
        );
      }
    }
  }
}

final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class _DateSection {
  final String label;
  final List<QueryDocumentSnapshot> items;
  _DateSection({required this.label, required this.items});
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }
}

class _SavedMessageTile extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final ColorScheme colorScheme;
  final VoidCallback onDelete;
  final void Function(String) onCopy;
  final void Function(String) onImageTap;

  const _SavedMessageTile({
    required this.doc,
    required this.colorScheme,
    required this.onDelete,
    required this.onCopy,
    required this.onImageTap,
  });

  @override
  State<_SavedMessageTile> createState() => _SavedMessageTileState();
}

class _SavedMessageTileState extends State<_SavedMessageTile> {
  UserModel? _sender;

  @override
  void initState() {
    super.initState();
    _loadSender();
  }

  Future<void> _loadSender() async {
    final data = widget.doc.data() as Map<String, dynamic>;
    final senderId = data['senderId'] as String? ?? '';
    if (senderId.isEmpty) return;
    try {
      final user = await UserService().getUser(senderId);
      if (mounted) setState(() => _sender = user);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'text';
    final content = data['content'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final senderName = data['senderName'] as String? ?? context.t('unknown');
    final cs = widget.colorScheme;

    return Dismissible(
      key: ValueKey(widget.doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onError, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.t('deleteMessage')),
            content: Text(context.t('deleteSavedConfirm')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.t('delete'), style: TextStyle(color: cs.error))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => widget.onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (type == 'text') {
              widget.onCopy(content);
            } else if (type == 'image') {
              widget.onImageTap(content);
            }
          },
          onLongPress: () => _showOptions(context, type, content),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: _sender?.photoUrl != null ? NetworkImage(_sender!.photoUrl!) : null,
                  child: _sender?.photoUrl == null && senderName.isNotEmpty
                      ? Text(senderName[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(senderName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const Spacer(),
                          Text(
                            DateFormatter.formatRelativeTime(timestamp),
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withAlpha(150)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (type == 'text')
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4)),
                      if (type == 'image')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: content,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            height: 180,
                            placeholder: (c, u) => Container(
                              height: 180,
                              color: cs.surfaceContainerHighest,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (c, u, e) => Container(
                              height: 180,
                              color: cs.errorContainer,
                              child: Icon(Icons.broken_image_rounded, color: cs.onErrorContainer),
                            ),
                          ),
                        ),
                      if (type == 'voice')
                        Row(children: [
                          Icon(Icons.mic_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(context.t('voice'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ]),
                      if (type == 'video')
                        Row(children: [
                          Icon(Icons.videocam_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(context.t('video'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ]),
                      if (type == 'file')
                        Row(children: [
                          Icon(Icons.insert_drive_file_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(content.split('/').lastOrNull ?? content,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                          ),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, String type, String content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'text') ...[
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: cs.primary),
                    title: Text(context.t('copyText')),
                    onTap: () {
                      widget.onCopy(content);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text(context.t('delete'), style: TextStyle(color: cs.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
