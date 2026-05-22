import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../services/chat_service.dart';
import '../../services/presence_service.dart';
import '../../services/user_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/date_formatter.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import 'user_profile_screen.dart';
import 'group_management_screen.dart';
import 'group_info_screen.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserPhotoUrl;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUserName = '',
    this.otherUserId = '',
    this.otherUserPhotoUrl,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageService = MessageService();
  final _chatService = ChatService();
  final _presenceService = PresenceService();
  final _userService = UserService();
  final _authService = AuthService();
  final _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late Stream<List<MessageModel>> _messagesStream;
  late Stream<Map<String, bool>> _typingStream;
  late Stream<bool> _presenceStream;
  final List<MessageModel> _pendingMessages = [];
  MessageModel? _replyingTo;
  bool _isUploading = false;
  List<UserModel> _groupMembers = [];
  
  // Pagination
  final ScrollController _scrollController = ScrollController();
  int _messageLimit = 20;
  bool _isLoadingMore = false;
  
  // Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<MessageModel> _currentMessages = [];
  
  // Scroll-to-bottom
  bool _showScrollDownFab = false;
  int _newMessageCount = 0;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _messagesStream = _messageService.getMessages(widget.chatId, limit: _messageLimit);
    _typingStream = _presenceService.getTypingStream(widget.chatId);
    _presenceStream = widget.otherUserId.isNotEmpty
        ? _presenceService.getPresenceStream(widget.otherUserId)
        : Stream.value(false);
    
    _scrollController.addListener(_onScroll);

    // Reset unread count when opening chat
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      _messageService.resetUnreadCount(widget.chatId, uid);
    }

    if (widget.isGroup) {
      _fetchGroupMembers();
    }
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isNearBottom = currentScroll >= maxScroll * 0.9;

    if (isNearBottom && !_isLoadingMore) {
      _loadMoreMessages();
    }

    // Show/hide scroll-to-bottom FAB
    final isAtBottom = currentScroll < 50;
    if (isAtBottom != !_showScrollDownFab) {
      if (mounted) {
        setState(() {
          _showScrollDownFab = !isAtBottom;
          if (isAtBottom) _newMessageCount = 0;
        });
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    setState(() {
      _newMessageCount = 0;
      _showScrollDownFab = false;
    });
  }

  void _loadMoreMessages() {
    setState(() {
      _isLoadingMore = true;
      _messageLimit += 20;
      _messagesStream = _messageService.getMessages(widget.chatId, limit: _messageLimit);
    });
    // Reset loading state after a short delay to prevent multiple calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupMembers() async {
    final chatDoc = await _chatService.getChatOnce(widget.chatId);
    final List<String> memberIds = List<String>.from(chatDoc['participants'] ?? []);
    final List<UserModel> members = [];
    
    for (String id in memberIds) {
      final user = await _userService.getUser(id);
      if (user != null) members.add(user);
    }
    
    if (mounted) {
      setState(() {
        _groupMembers = members;
      });
    }
  }


  void _onTypingChanged(bool isTyping) {
    _presenceService.setTyping(widget.chatId, isTyping);
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _sendMessage(String text) {
    final user = _authService.currentUser;
    if (user == null) return;

    final message = MessageModel(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      receiverId: widget.otherUserId,
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
      replyToMessageId: _replyingTo?.id,
      replyToMessageContent: _replyingTo != null
          ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
          : null,
    );

    // Fetch participants from Firestore for unread tracking
    _messageService.sendMessage(widget.chatId, message);
    _cancelReply();
  }

  Future<void> _sendVoiceMessage(String path) async {
    setState(() => _isUploading = true);
    try {
      final url = await _cloudinaryService.uploadFromFile(path, 'voice_messages');
      if (url != null) {
        final user = _authService.currentUser;
        if (user == null) return;

        final message = MessageModel(
          senderId: user.uid,
          senderName: user.displayName ?? user.email ?? 'User',
          receiverId: widget.otherUserId,
          content: url,
          type: MessageType.voice,
          timestamp: DateTime.now(),
          replyToMessageId: _replyingTo?.id,
          replyToMessageContent: _replyingTo != null
              ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
              : null,
        );

        _messageService.sendMessage(widget.chatId, message);
        _cancelReply();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('errorSendingVoice', args: [e.toString()]))));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMessageOptions(MessageModel message) {
    final bottomColorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: bottomColorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Reactions Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '🔥', '👍'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      _messageService.toggleReaction(
                        widget.chatId,
                        message.id!,
                        _authService.currentUser!.uid,
                        emoji,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bottomColorScheme.surfaceContainerHighest.withAlpha(60),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(height: 1, color: bottomColorScheme.outlineVariant.withAlpha(80)),
            _menuItem(context, Icons.reply_rounded, context.t('reply'), bottomColorScheme, () {
              Navigator.pop(context);
              setState(() {
                _replyingTo = message;
              });
            }),
            Divider(height: 1, indent: 56, color: bottomColorScheme.outlineVariant.withAlpha(80)),
            _menuItem(context, Icons.forward_rounded, context.t('forward'), bottomColorScheme, () {
              Navigator.pop(context);
              _forwardMessage(message);
            }),
            // Copy & Save (hidden if restrictSaving — checked via StreamBuilder)
            StreamBuilder<ChatModel>(
              stream: _chatService.getChatStream(widget.chatId),
              builder: (context, snap) {
                final savingRestricted = snap.data?.restrictSaving == true && widget.isGroup;
                return Column(
                  children: [
                    if (!savingRestricted) ...[
                      Divider(height: 1, indent: 56, color: bottomColorScheme.outlineVariant.withAlpha(80)),
                      _menuItem(context, Icons.copy_rounded, context.t('copyText'), bottomColorScheme, () {
                        Clipboard.setData(ClipboardData(text: message.content));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.t('textCopied'))),
                        );
                      }),
                      Divider(height: 1, indent: 56, color: bottomColorScheme.outlineVariant.withAlpha(80)),
                      _menuItem(context, Icons.bookmark_outline_rounded, context.t('save'), bottomColorScheme, () {
                        _saveMessage(message);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.t('messageSaved'))),
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
            Divider(height: 1, indent: 56, color: bottomColorScheme.outlineVariant.withAlpha(80)),
            if (message.id != null)
              _menuItem(context, Icons.delete_outline_rounded, context.t('deleteMessage'), bottomColorScheme, () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.t('deleteMessage')),
                    content: Text(context.t('deleteChoiceDesc')),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _messageService.hideMessage(widget.chatId, message.id!, _authService.currentUser!.uid);
                        },
                        child: Text(context.t('deleteForMe')),
                      ),
                      if (message.senderId == _authService.currentUser?.uid)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _messageService.deleteMessage(widget.chatId, message.id!);
                          },
                          child: Text(context.t('deleteForEveryone'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(context.t('cancel')),
                      ),
                    ],
                  ),
                );
              }, isDestructive: true),
          StreamBuilder<ChatModel>(
            stream: _chatService.getChatStream(widget.chatId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final chat = snapshot.data!;
              final isAdmin = chat.admins.contains(_authService.currentUser?.uid) || chat.adminId == _authService.currentUser?.uid;
              final canPin = isAdmin || (chat.permissions['pinMessages'] ?? true);
              
              if (widget.isGroup && !canPin) return const SizedBox.shrink();

              return Column(
                children: [
                  Divider(height: 1, indent: 56, color: bottomColorScheme.outlineVariant.withAlpha(80)),
                  _menuItem(context, Icons.push_pin_outlined, context.t('pinMessage'), bottomColorScheme, () {
                    _chatService.pinMessage(widget.chatId, message.id, message.content);
                    Navigator.pop(context);
                  }),
                ],
              );
            },
          ),
        ],
      ),
    ));
  }

  void _forwardMessage(MessageModel message) async {
    final user = _authService.currentUser;
    if (user == null || message.id == null) return;

    final chats = await _chatService.getUserChatsOnce(user.uid);
    final otherChats = chats.where((c) => c.chatId != widget.chatId).toList();

    if (!context.mounted) return;
    _showForwardChatPicker(context, otherChats, message);
  }

  void _showForwardChatPicker(BuildContext ctx, List<ChatModel> chats, MessageModel original) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx2) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(ctx2).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(context.t('forwardTo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            SizedBox(
              height: chats.length > 4 ? 320 : chats.length * 72.0,
              child: ListView.builder(
                itemCount: chats.length,
                itemBuilder: (_, i) {
                  final chat = chats[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text((chat.groupName ?? '?')[0])),
                    title: Text(chat.groupName ?? chat.chatId),
                    onTap: () async {
                      Navigator.pop(ctx2);
                      final forwarded = MessageModel(
                        senderId: _authService.currentUser!.uid,
                        senderName: _authService.currentUser!.displayName ?? _authService.currentUser!.email ?? 'User',
                        receiverId: chat.isGroup ? chat.chatId : chat.participants.firstWhere((p) => p != _authService.currentUser!.uid),
                        content: original.content,
                        type: original.type,
                        timestamp: DateTime.now(),
                        forwardedFrom: original.senderName ?? original.senderId,
                      );
                      await _messageService.sendMessage(chat.chatId, forwarded);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.t('messageForwarded'))),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickWallpaper() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final url = await _cloudinaryService.uploadFile(bytes, image.name, 'wallpapers/${widget.chatId}');
      if (url != null && context.mounted) {
        await _chatService.setChatWallpaper(widget.chatId, url);
      }
    }
  }

  Widget _defaultChatBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0E1621), const Color(0xFF0A1118)]
              : [const Color(0xFFE8F0E8), const Color(0xFFD5E1D8)],
        ),
      ),
      child: CustomPaint(
        painter: _ChatPatternPainter(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(6)
              : const Color(0xFF93B49C).withAlpha(18),
        ),
        size: Size.infinite,
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      _sendImage(bytes, image.name, image.path);
    }
  }

  Future<void> _pickMultiImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        final bytes = await image.readAsBytes();
        _sendImage(bytes, image.name, image.path);
      }
    }
  }

  Future<void> _sendImage(Uint8List bytes, String fileName, String localPath) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // 1. Create Pending Message for Optimistic UI
    final pendingMsg = MessageModel(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      receiverId: widget.otherUserId,
      content: '', // Will be replaced by network URL
      type: MessageType.image,
      timestamp: DateTime.now(),
      isPending: true,
      localFilePath: localPath,
      replyToMessageId: _replyingTo?.id,
      replyToMessageContent: _replyingTo != null
          ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
          : null,
    );

    setState(() {
      _pendingMessages.insert(0, pendingMsg);
      _isUploading = true;
    });
    
    // Save current reply state locally for the final message, then clear global
    final repliedId = _replyingTo?.id;
    final repliedContent = _replyingTo != null
        ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
        : null;
    _cancelReply();

    // 2. Upload to Cloudinary

    final imageUrl = await _cloudinaryService.uploadFile(
      bytes, 
      fileName,
      'chats/${widget.chatId}',
    );
    
    if (imageUrl != null) {
      final message = MessageModel(
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        receiverId: widget.otherUserId,
        content: imageUrl,
        type: MessageType.image,
        timestamp: DateTime.now(),
        replyToMessageId: repliedId,
        replyToMessageContent: repliedContent,
      );
      await _messageService.sendMessage(widget.chatId, message);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('failedImage'))),
        );
      }
    }
    
    // 3. Remove pending message from local state
    setState(() {
      _pendingMessages.remove(pendingMsg);
      _isUploading = false;
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final bytes = await video.readAsBytes();
      _sendVideo(bytes, video.name, video.path);
    }
  }

  Future<void> _sendVideo(Uint8List bytes, String fileName, String localPath) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final pendingMsg = MessageModel(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      receiverId: widget.otherUserId,
      content: '', // Will be replaced
      type: MessageType.video,
      timestamp: DateTime.now(),
      isPending: true,
      localFilePath: localPath,
      replyToMessageId: _replyingTo?.id,
      replyToMessageContent: _replyingTo != null
          ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
          : null,
    );

    setState(() {
      _pendingMessages.insert(0, pendingMsg);
    });
    
    // Save current reply state locally for the final message, then clear global
    final repliedId = _replyingTo?.id;
    final repliedContent = _replyingTo != null
        ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
        : null;
    _cancelReply();

    final videoUrl = await _cloudinaryService.uploadVideo(
      bytes, 
      fileName,
      'chats/${widget.chatId}',
    );
    
    if (videoUrl != null) {
      final message = MessageModel(
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        receiverId: widget.otherUserId,
        content: videoUrl,
        type: MessageType.video,
        timestamp: DateTime.now(),
        replyToMessageId: repliedId,
        replyToMessageContent: repliedContent,
      );
      await _messageService.sendMessage(widget.chatId, message);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('failedVideo'))),
        );
      }
    }
    
    setState(() {
      _pendingMessages.remove(pendingMsg);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = file.path;
    if (path == null) return;
    await _sendFile(file.name, path);
  }

  Future<void> _sendFile(String fileName, String localPath) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final pendingMsg = MessageModel(
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'User',
      receiverId: widget.otherUserId,
      content: fileName,
      type: MessageType.file,
      timestamp: DateTime.now(),
      isPending: true,
      localFilePath: localPath,
      replyToMessageId: _replyingTo?.id,
      replyToMessageContent: _replyingTo != null
          ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
          : null,
    );

    setState(() {
      _pendingMessages.insert(0, pendingMsg);
    });

    final repliedId = _replyingTo?.id;
    final repliedContent = _replyingTo != null
        ? (_replyingTo!.type == MessageType.text ? _replyingTo!.content : '[Media]')
        : null;
    _cancelReply();

    final fileUrl = await _cloudinaryService.uploadRaw(localPath, fileName, 'chats/${widget.chatId}');
    if (fileUrl != null) {
      final message = MessageModel(
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        receiverId: widget.otherUserId,
        content: fileUrl,
        type: MessageType.file,
        timestamp: DateTime.now(),
        localFilePath: localPath,
        replyToMessageId: repliedId,
        replyToMessageContent: repliedContent,
      );
      await _messageService.sendMessage(widget.chatId, message);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('failedFileUpload'))),
        );
      }
    }

    setState(() {
      _pendingMessages.remove(pendingMsg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.t('searchMessages'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              )
            : StreamBuilder<ChatModel>(
                stream: _chatService.getChatStream(widget.chatId),
                builder: (context, chatSnapshot) {
                  String currentName = widget.otherUserName;
                  if (chatSnapshot.hasData) {
                    currentName = chatSnapshot.data!.nicknames?[widget.otherUserId] ?? widget.otherUserName;
                  }
                  return GestureDetector(
                    onTap: () {
                      if (widget.isGroup) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GroupInfoScreen(chatId: widget.chatId)),
                        ).then((value) {
                          if (value == 'search') {
                            setState(() {
                              _isSearching = true;
                            });
                          }
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: widget.otherUserId,
                              displayName: currentName,
                              photoUrl: widget.otherUserPhotoUrl,
                              heroTag: 'avatar_${widget.chatId}',
                            ),
                          ),
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Hero(
                          tag: 'avatar_${widget.chatId}',
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: widget.otherUserPhotoUrl != null 
                                ? NetworkImage(widget.otherUserPhotoUrl!) 
                                : null,
                            child: widget.otherUserPhotoUrl == null 
                                ? Text(
                                    currentName.isNotEmpty ? currentName.substring(0, 1).toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppConstants.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            widget.isGroup
                                ? StreamBuilder<Map<String, bool>>(
                                    stream: _typingStream,
                                    builder: (context, typingSnapshot) {
                                      final typingUsers = typingSnapshot.data?.entries
                                          .where((e) => e.value && e.key != currentUserId)
                                          .map((e) => e.key)
                                          .toList() ?? [];

                                      if (typingUsers.isNotEmpty) {
                                        if (typingUsers.length == 1) {
                                          final typingUserObj = _groupMembers.firstWhere(
                                            (m) => m.uid == typingUsers.first,
                                            orElse: () => UserModel(uid: '', email: '', displayName: 'Someone'),
                                          );
                          return Text(
                            '${typingUserObj.displayName.split('@')[0]} ${context.t('isTyping')}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                          );
                                        } else {
                                          return Text(
                                            context.t('severalTyping'),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                          );
                                        }
                                      }

                                      return Text(
                                        context.t('memberCount', args: [(chatSnapshot.data?.participants.length ?? 0).toString()]),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.outline,
                                              fontSize: 11,
                                            ),
                                      );
                                    },
                                  )
                                : StreamBuilder<Map<String, bool>>(
                                    stream: _typingStream,
                                    builder: (context, typingSnapshot) {
                                      final isTyping = typingSnapshot.data?[widget.otherUserId] ?? false;
                                      
                                      if (isTyping) {
                                        return Text(
                                          context.t('typing'),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                        );
                                      }

                                      return StreamBuilder<bool>(
                                        stream: _presenceStream,
                                        builder: (context, presenceSnapshot) {
                                          final isOnline = presenceSnapshot.data ?? false;
                                          return FutureBuilder<UserModel?>(
                                            future: widget.otherUserId.isNotEmpty
                                                ? _userService.getUser(widget.otherUserId)
                                                : Future.value(null),
                                            builder: (context, userSnapshot) {
                                              String statusText = isOnline ? context.t('online') : context.t('offline');
                                              if (!isOnline && userSnapshot.hasData && userSnapshot.data?.lastSeen != null) {
                                                statusText = '${context.t('lastSeen')}${DateFormatter.formatRelativeTime(userSnapshot.data!.lastSeen!)}';
                                              }
                                              return Text(
                                                statusText,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: isOnline 
                                                        ? Theme.of(context).colorScheme.tertiary 
                                                        : Theme.of(context).colorScheme.outline,
                                                      fontSize: 11,
                                                    ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          StreamBuilder<ChatModel>(
            stream: _chatService.getChatStream(widget.chatId),
            builder: (context, chatSnapshot) {
              final chat = chatSnapshot.data;
              final isAdmin = chat != null && 
                  (chat.admins.contains(currentUserId) || chat.adminId == currentUserId);

              final isMuted = chat != null && chat.mutedUsers[currentUserId] != null;

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfileScreen(userId: widget.otherUserId)),
                    );
                  } else if (value == 'info') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupInfoScreen(chatId: widget.chatId)),
                    );
                  } else if (value == 'management') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupManagementScreen(chatId: widget.chatId)),
                    );
                  } else if (value == 'mute') {
                    _showMuteOptions(context, currentUserId);
                  } else if (value == 'unmute') {
                    _chatService.muteUser(widget.chatId, currentUserId, null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.t('chatUnmuted'))),
                      );
                    }
                  } else if (value == 'wallpaper') {
                    _pickWallpaper();
                  } else if (value == 'removeWallpaper') {
                    _chatService.removeChatWallpaper(widget.chatId);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'profile', child: Text(context.t('viewProfile'))),
                  if (widget.isGroup)
                    PopupMenuItem(value: 'info', child: Text(context.t('groupInfo'))),
                  if (widget.isGroup && isAdmin)
                    PopupMenuItem(value: 'management', child: Text(context.t('groupManagement'))),
                  PopupMenuDivider(),
                  if (chat?.wallpaper != null)
                    PopupMenuItem(
                      value: 'removeWallpaper',
                      child: Row(
                        children: [
                          Icon(Icons.wallpaper_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 12),
                          Text(context.t('removeWallpaper'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'wallpaper',
                      child: Row(
                        children: [
                          Icon(Icons.wallpaper_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(context.t('setWallpaper')),
                        ],
                      ),
                    ),
                  if (isMuted)
                    PopupMenuItem(
                      value: 'unmute',
                      child: Row(
                        children: [
                          Icon(Icons.notifications_on_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(context.t('unmute')),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(context.t('mute')),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: _isUploading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2.0),
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  minHeight: 2.0,
                ),
              )
            : null,
      ),
      body: StreamBuilder<ChatModel>(
        stream: _chatService.getChatStream(widget.chatId),
        builder: (context, chatSnapshot) {
          final chat = chatSnapshot.data;
          final hasPinned = chat?.pinnedMessageId != null;

          return Column(
            children: [
              if (hasPinned)
                GestureDetector(
                  onTap: () {
                    final index = _currentMessages.indexWhere((m) => m.id == chat.pinnedMessageId);
                    if (index != -1) {
                      _scrollController.animateTo(
                        index * 60.0, // Rough estimate, ItemScrollController would be better but this is a start
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.t('scrollToFind'))),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('pinnedMessage'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                chat!.pinnedMessageContent ?? context.t('media'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (chat.admins.contains(_authService.currentUser?.uid) || chat.adminId == _authService.currentUser?.uid)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _chatService.pinMessage(widget.chatId, null, null),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    // Chat wallpaper background
                    Positioned.fill(
                      child: chat?.wallpaper != null
                          ? Image.network(
                              chat!.wallpaper!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultChatBackground(context),
                            )
                          : _defaultChatBackground(context),
                    ),
                    StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Error loading messages: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            '${context.t('errorLoading')}\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData && _pendingMessages.isEmpty) {
                  return Center(child: Text(context.t('noMessages')));
                }
                
                final List<MessageModel> allMessages = [
                  ..._pendingMessages,
                  if (snapshot.hasData) ...snapshot.data!,
                ];
                final uid = _authService.currentUser?.uid ?? '';
                allMessages.removeWhere((m) => m.deletedFor.contains(uid));
                _currentMessages = allMessages;

                // Track new messages for scroll-to-bottom badge
                if (_prevMessageCount > 0 && allMessages.length > _prevMessageCount && _showScrollDownFab) {
                  _newMessageCount += allMessages.length - _prevMessageCount;
                }
                _prevMessageCount = allMessages.length;
                
                final filteredMessages = _searchQuery.isEmpty 
                  ? allMessages 
                  : allMessages.where((m) => m.content.toLowerCase().contains(_searchQuery)).toList();

                if (filteredMessages.isEmpty) {
                  return Center(
                    child: Text(_searchQuery.isEmpty ? context.t('noMessages') : context.t('noSearchMatch')),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppConstants.md),
                  itemCount: filteredMessages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredMessages.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final message = filteredMessages[index];
                    
                    // Grouping Logic
                    bool isFirstInGroup = true;
                    bool isLastInGroup = true;
                    
                    if (index < allMessages.length - 1) { // has older message
                      final olderMessage = allMessages[index + 1];
                      if (olderMessage.senderId == message.senderId && 
                          message.timestamp.difference(olderMessage.timestamp).inMinutes.abs() < 5) {
                        isFirstInGroup = false;
                      }
                    }

                    if (index > 0) { // has newer message
                      final newerMessage = allMessages[index - 1];
                      if (newerMessage.senderId == message.senderId &&
                          newerMessage.timestamp.difference(message.timestamp).inMinutes.abs() < 5) {
                        isLastInGroup = false;
                      }
                    }

                    // Logic for Date Header
                    bool showDateHeader = false;
                    if (index == allMessages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final previousMessage = allMessages[index + 1]; // Older message
                      showDateHeader = message.timestamp.day != previousMessage.timestamp.day ||
                                       message.timestamp.month != previousMessage.timestamp.month ||
                                       message.timestamp.year != previousMessage.timestamp.year;
                    }

                    // Mark as read if received from others and unread
                    if (message.senderId != currentUserId && !message.isRead && message.id != null) {
                      _messageService.markAsRead(widget.chatId, message.id!);
                    }

                    final messageBubble = MessageBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                      isFirstInGroup: isFirstInGroup,
                      isLastInGroup: isLastInGroup,
                      isGroupChat: widget.isGroup,
                      onSwipe: () {
                        setState(() {
                          _replyingTo = message;
                        });
                      },
                      onLongPress: () => _showMessageOptions(message),
                      onReplyTap: () {
                        if (message.replyToMessageId != null) {
                          final index = filteredMessages.indexWhere((m) => m.id == message.replyToMessageId);
                          if (index != -1) {
                            _scrollController.animateTo(
                              index * 70.0, // Rough estimate
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.t('replyNotFound'))),
                            );
                          }
                        }
                      },
                    );

                    if (showDateHeader) {
                      return Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withAlpha(100)
                                    : Colors.black.withAlpha(40),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                DateFormatter.formatChatDateSeparator(message.timestamp),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          messageBubble,
                        ],
                      );
                    }

                    return messageBubble;
                  },
                );
              },
            ),
                  // Scroll-to-bottom FAB
                  if (_showScrollDownFab && !_isSearching)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              if (_newMessageCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _newMessageCount > 99 ? '99+' : '$_newMessageCount',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingTo!.senderId == currentUserId ? context.t('replyingToSelf') : context.t('replyingTo', args: [widget.otherUserName]),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyingTo!.type == MessageType.text ? _replyingTo!.content : context.t('mediaMessage'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          MessageInput(
            onSend: _sendMessage,
            onAttach: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          context.t('attach'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAttachmentsGrid(context, colorScheme),
                      ],
                    ),
                  );
                },
              );
            },
            onTypingChanged: _onTypingChanged,
            onSendVoice: _sendVoiceMessage,
            groupMembers: _groupMembers,
            slowModeSeconds: chat?.slowModeSeconds ?? 0,
            isAdmin: chat?.admins.contains(currentUserId) == true || chat?.adminId == currentUserId,
            canSendMessages: chat == null ||
                chat.admins.contains(currentUserId) ||
                chat.adminId == currentUserId ||
                ((chat.permissions['sendMessages'] ?? true) &&
                    _checkRestriction(chat.restrictions[currentUserId], 'sendMessages')),
            canSendMedia: chat == null ||
                chat.admins.contains(currentUserId) ||
                chat.adminId == currentUserId ||
                ((chat.permissions['sendMedia'] ?? true) &&
                    _checkRestriction(chat.restrictions[currentUserId], 'sendMedia')),
          ),
        ],
      );
    },
  ),
);
}

  void _saveMessage(MessageModel message) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedMessages')
        .add({
      'senderId': message.senderId,
      'senderName': message.senderName,
      'content': message.content,
      'type': message.type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'originalChatId': widget.chatId,
    });
  }

  void _showMuteOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(context.t('muteNotifications'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _muteOption(ctx, context.t('for1Hour'), Duration(hours: 1), userId),
              _muteOption(ctx, context.t('for8Hours'), Duration(hours: 8), userId),
              _muteOption(ctx, context.t('for1Day'), Duration(days: 1), userId),
              _muteOption(ctx, context.t('for7Days'), Duration(days: 7), userId),
              _muteOption(ctx, context.t('forever'), null, userId, isForever: true),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, ColorScheme colorScheme, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.error.withAlpha(20)
              : colorScheme.primaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isDestructive ? colorScheme.error : colorScheme.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Check if a user restriction allows a specific permission.
  /// Returns true if there's no restriction or the restriction allows the action.
  bool _checkRestriction(Map<String, dynamic>? restriction, String permission) {
    if (restriction == null) return true;
    final untilRaw = restriction['until'];
    if (untilRaw != null) {
      DateTime until;
      if (untilRaw is Timestamp) {
        until = untilRaw.toDate();
      } else {
        until = untilRaw as DateTime;
      }
      if (until.isBefore(DateTime.now())) return true; // expired
    }
    if (restriction[permission] == false) return false;
    return true;
  }

  Widget _muteOption(BuildContext ctx, String label, Duration? duration, String userId, {bool isForever = false}) {
    return ListTile(
      leading: Icon(
        isForever ? Icons.block_rounded : Icons.timer_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(ctx);
        _chatService.muteUser(
          widget.chatId,
          userId,
          isForever ? DateTime(2100) : DateTime.now().add(duration!),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('mutedLabel', args: [label]))),
        );
      },
    );
  }

  Widget _buildAttachmentsGrid(BuildContext context, ColorScheme colorScheme) {
    final items = [
      _AttachItem(Icons.photo_library_rounded, context.t('photoVideo'), const Color(0xFF34C759), () {
        Navigator.pop(context);
        _pickMultiImage();
      }),
      _AttachItem(Icons.videocam_rounded, context.t('video'), const Color(0xFF007AFF), () {
        Navigator.pop(context);
        _pickVideo();
      }),
      _AttachItem(Icons.camera_alt_rounded, context.t('camera'), const Color(0xFFFF9500), () {
        Navigator.pop(context);
        _pickImage();
      }),
      _AttachItem(Icons.description_rounded, context.t('document'), const Color(0xFF5856D6), () {
        Navigator.pop(context);
        _pickFile();
      }),
      _AttachItem(Icons.headphones_rounded, context.t('voice'), const Color(0xFFFF2D55), () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('voiceTip'))),
        );
      }),
      _AttachItem(Icons.location_on_rounded, context.t('location'), const Color(0xFF00C7BE), () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('locationComingSoon'))),
        );
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: item.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachItem(this.icon, this.label, this.color, this.onTap);
}

/// Draws a subtle repeating pattern on the chat background
class _ChatPatternPainter extends CustomPainter {
  final Color color;

  _ChatPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Offset every other row
        final offsetX = (y ~/ spacing).isOdd ? spacing / 2 : 0;
        canvas.drawCircle(Offset(x + offsetX, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
