import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/translations.dart';
import '../auth/login_screen.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  User? get _user => FirebaseAuth.instance.currentUser;

  String get _ticketId => _user?.uid ?? 'anonymous';

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    if (_user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(_ticketId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _user!.uid,
      'senderName': _user!.displayName ?? _user!.email ?? 'User',
      'isSupport': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
  }

  void _scrollDown() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('supportChat')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: colorScheme.primaryContainer.withAlpha(100),
            child: Row(
              children: [
                Icon(Icons.headset_mic_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t('supportChatDesc'),
                    style: TextStyle(fontSize: 13, color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _user == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login_rounded, size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(context.t('supportLoginRequired'), style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('support_tickets')
                      .doc(_ticketId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final msgs = snapshot.data!.docs;
                    if (msgs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_outlined, size: 48, color: colorScheme.onSurfaceVariant.withAlpha(100)),
                            const SizedBox(height: 12),
                            Text(context.t('supportNoMessages'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) {
                        final data = msgs[i].data() as Map<String, dynamic>;
                        final isSupport = data['isSupport'] == true;
                        final text = data['text'] as String? ?? '';
                        final time = (data['timestamp'] as Timestamp?)?.toDate();
                        final name = data['senderName'] as String? ?? '';
                        return _buildBubble(text, isSupport, time, name, colorScheme);
                      },
                    );
                  },
                ),
          ),
          if (_user != null)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, -1)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: context.t('typeMessage'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isSupport, DateTime? time, String name, ColorScheme colorScheme) {
    return Align(
      alignment: isSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        decoration: BoxDecoration(
          color: isSupport
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSupport ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight: isSupport ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSupport)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  context.t('supportTeam'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
            Text(text, style: const TextStyle(fontSize: 15)),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withAlpha(150)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
