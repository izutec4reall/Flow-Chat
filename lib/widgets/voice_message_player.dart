import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final Color foregroundColor;

  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.foregroundColor,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;

  final List<double> _speeds = [1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setPlaybackRate(_speed);
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    final next = (idx + 1) % _speeds.length;
    setState(() => _speed = _speeds[next]);
    if (_isPlaying) {
      _audioPlayer.setPlaybackRate(_speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.foregroundColor.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            color: widget.foregroundColor,
            iconSize: 32,
            onPressed: _togglePlay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (_isPlaying)
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.foregroundColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_speed}x',
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(details.globalPosition);
                      final percent = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                      _audioPlayer.seek(Duration(milliseconds: (_duration.inMilliseconds * percent).toInt()));
                    },
                    child: Row(
                      children: List.generate(35, (index) {
                        final t = index / 35;
                        final envelope = (t < 0.15)
                            ? (t / 0.15)
                            : (t > 0.7)
                                ? (1.0 - (t - 0.7) / 0.3)
                                : 1.0;
                        final freq = 0.5 + 0.5 * sin(t * pi * 4 + 1.5);
                        final noise = 0.3 + 0.7 * (0.5 + 0.5 * sin(index * 2.7 + 1.3));
                        final barHeight = 4.0 + envelope * freq * noise * 22.0;
                        final progress = _duration.inMilliseconds > 0
                            ? (_position.inMilliseconds / _duration.inMilliseconds)
                            : 0.0;
                        final isPlayed = progress > t;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: barHeight.clamp(4.0, 28.0),
                            decoration: BoxDecoration(
                              color: isPlayed ? widget.foregroundColor : widget.foregroundColor.withAlpha(50),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(color: widget.foregroundColor.withAlpha(180), fontSize: 9),
                    ),
                    if (_duration > Duration.zero)
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: widget.foregroundColor.withAlpha(180), fontSize: 9),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
