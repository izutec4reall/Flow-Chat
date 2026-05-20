import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/voice_recorder_service.dart';
import '../utils/translations.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(String) onSendVoice;
  final VoidCallback onAttach;
  final Function(bool)? onTypingChanged;
  final List<UserModel> groupMembers;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onAttach,
    this.onTypingChanged,
    required this.onSendVoice,
    this.groupMembers = const [],
    this.slowModeSeconds = 0,
    this.isAdmin = false,
    this.canSendMessages = true,
    this.canSendMedia = true,
  });

  final int slowModeSeconds;
  final bool isAdmin;
  final bool canSendMessages;
  final bool canSendMedia;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _showSend = false;
  Timer? _typingTimer;
  List<UserModel> _filteredMembers = [];
  bool _showMentions = false;
  final _recorderService = VoiceRecorderService();
  bool _isRecording = false;

  // Slow Mode Cooldown
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // Animation for send button transition
  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cooldownTimer?.cancel();
    _controller.dispose();
    _recorderService.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    if (widget.slowModeSeconds > 0 && !widget.isAdmin) {
      setState(() {
        _cooldownSeconds = widget.slowModeSeconds;
      });
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_cooldownSeconds > 0) {
          setState(() {
            _cooldownSeconds--;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(40),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: !widget.canSendMessages
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_rounded,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        context.t('messagingRestricted'),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slow mode cooldown banner
                  if (_cooldownSeconds > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            context.t('slowModeWait', args: ['$_cooldownSeconds']),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Mentions dropdown
                  if (_showMentions) _buildMentionsDropdown(colorScheme),
                  // Input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Attachment button
                      if (widget.canSendMedia)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: IconButton(
                            onPressed: widget.onAttach,
                            icon: const Icon(Icons.attach_file_rounded,
                                size: 24),
                            color: colorScheme.onSurfaceVariant,
                            splashRadius: 22,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      // Text field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHigh
                                : colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(60),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 5,
                                  minLines: 1,
                                  onChanged: _onTextChanged,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.t('message'),
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withAlpha(150),
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              // Emoji button
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 4, bottom: 4),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                      Icons.sentiment_satisfied_alt_rounded),
                                  color: colorScheme.onSurfaceVariant
                                      .withAlpha(150),
                                  iconSize: 24,
                                  splashRadius: 20,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Send / Mic button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildSendButton(colorScheme, isDark),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) async {
        if (!_showSend) {
          await _recorderService.startRecording();
          setState(() => _isRecording = true);
          if (widget.onTypingChanged != null) widget.onTypingChanged!(true);
        }
      },
      onLongPressEnd: (_) async {
        if (_isRecording) {
          final path = await _recorderService.stopRecording();
          setState(() => _isRecording = false);
          if (widget.onTypingChanged != null) widget.onTypingChanged!(false);
          if (path != null) {
            widget.onSendVoice(path);
            _startCooldown();
          }
        }
      },
      onTap: () {
        if (_cooldownSeconds > 0) return;

        if (_showSend) {
          _sendBtnController.forward().then((_) {
            _sendBtnController.reverse();
          });
          widget.onSend(_controller.text.trim());
          _controller.clear();
          setState(() => _showSend = false);
          if (widget.onTypingChanged != null) widget.onTypingChanged!(false);
          _typingTimer?.cancel();
          _startCooldown();
        }
      },
      child: ScaleTransition(
        scale: _sendBtnScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _cooldownSeconds > 0
                ? colorScheme.surfaceContainerHighest
                : (_isRecording
                    ? const Color(0xFFFF3B30)
                    : (_showSend
                        ? colorScheme.primary
                        : Colors.transparent)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _cooldownSeconds > 0
                ? Text(
                    '$_cooldownSeconds',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.mic_rounded
                          : (_showSend
                              ? Icons.send_rounded
                              : Icons.mic_none_rounded),
                      key: ValueKey(
                          _isRecording ? 'rec' : (_showSend ? 'send' : 'mic')),
                      color: (_showSend || _isRecording)
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      size: _showSend ? 22 : 24,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMentionsDropdown(ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _filteredMembers.length,
          itemBuilder: (context, index) {
            final member = _filteredMembers[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 16,
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(member.displayName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text('@${member.username ?? ''}',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
              onTap: () {
                final text = _controller.text;
                final words = text.split(' ');
                words.removeLast();
                words.add('@${member.username} ');
                _controller.text = words.join(' ');
                _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length));
                setState(() => _showMentions = false);
              },
            );
          },
        ),
      ),
    );
  }

  void _onTextChanged(String val) {
    setState(() => _showSend = val.trim().isNotEmpty);

    final words = val.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';

    if (lastWord.startsWith('@')) {
      final query = lastWord.substring(1).toLowerCase();
      setState(() {
        _filteredMembers = widget.groupMembers.where((m) {
          return (m.username?.toLowerCase().contains(query) ?? false) ||
              (m.displayName.toLowerCase().contains(query));
        }).toList();
        _showMentions = _filteredMembers.isNotEmpty;
      });
    } else {
      if (_showMentions) setState(() => _showMentions = false);
    }

    if (widget.onTypingChanged != null) {
      widget.onTypingChanged!(val.trim().isNotEmpty);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        widget.onTypingChanged!(false);
      });
    }
  }
}
