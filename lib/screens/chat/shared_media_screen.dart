import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';
import '../../utils/translations.dart';

class SharedMediaScreen extends StatefulWidget {
  final String chatId;

  const SharedMediaScreen({super.key, required this.chatId});

  @override
  State<SharedMediaScreen> createState() => _SharedMediaScreenState();
}

class _SharedMediaScreenState extends State<SharedMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MessageModel> _allMessages = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMessages();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _fetchMessages() {
    _sub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
            .toList())
        .listen((msgs) {
      if (mounted) setState(() => _allMessages = msgs);
    });
  }

  List<MessageModel> get _mediaMessages =>
      _allMessages.where((m) => m.type == MessageType.image || m.type == MessageType.video).toList();

  List<MessageModel> get _fileMessages =>
      _allMessages.where((m) => m.type != MessageType.text && m.type != MessageType.image && m.type != MessageType.video).toList();

  List<MessageModel> get _linkMessages =>
      _allMessages.where((m) => m.type == MessageType.text && _hasLink(m.content)).toList();

  bool _hasLink(String text) {
    return text.contains('http://') || text.contains('https://') || text.contains('www.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('sharedMedia')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: [
            Tab(text: context.t('mediaTab'), icon: const Icon(Icons.image_outlined, size: 18)),
            Tab(text: context.t('filesTab'), icon: const Icon(Icons.insert_drive_file_outlined, size: 18)),
            Tab(text: context.t('linksTab'), icon: const Icon(Icons.link_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaGrid(colorScheme),
          _buildFileList(colorScheme),
          _buildLinkList(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ColorScheme colorScheme) {
    final media = _mediaMessages;
    if (media.isEmpty) {
      return _emptyState(Icons.image_outlined, context.t('noMedia'), context.t('noMediaHint'), colorScheme);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final msg = media[index];
        return GestureDetector(
          onTap: () => _showMediaPreview(msg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: NetworkImage(msg.content),
                fit: BoxFit.cover,
              ),
            ),
            child: msg.type == MessageType.video
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFileList(ColorScheme colorScheme) {
    final files = _fileMessages;
    if (files.isEmpty) {
      return _emptyState(Icons.insert_drive_file_outlined, context.t('noFiles'), context.t('noFilesHint'), colorScheme);
    }
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final msg = files[index];
        final sizeStr = '—';
        return ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.insert_drive_file_rounded, color: colorScheme.primary),
          ),
          title: Text(msg.content.split('/').last, overflow: TextOverflow.ellipsis),
          subtitle: Text(sizeStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        );
      },
    );
  }

  Widget _buildLinkList(ColorScheme colorScheme) {
    final links = _linkMessages;
    if (links.isEmpty) {
      return _emptyState(Icons.link_rounded, context.t('noLinks'), context.t('noLinksHint'), colorScheme);
    }
    return ListView.builder(
      itemCount: links.length,
      itemBuilder: (context, index) {
        final msg = links[index];
        final uri = _extractFirstLink(msg.content);
        return ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.link_rounded, color: colorScheme.primary),
          ),
          title: Text(uri?.host ?? msg.content, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(msg.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        );
      },
    );
  }

  Uri? _extractFirstLink(String text) {
    final regex = RegExp(r'(https?://[^\s]+)');
    final match = regex.firstMatch(text);
    return match != null ? Uri.tryParse(match.group(1)!) : null;
  }

  Widget _emptyState(IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant.withAlpha(80)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showMediaPreview(MessageModel msg) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(msg.type == MessageType.video ? context.t('video') : context.t('photo')),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(msg.content, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
