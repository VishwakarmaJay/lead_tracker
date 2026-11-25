import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/core/extension/log.dart';

/// Play / pause, seek bar, times, and speed for one local audio file.
/// Owns its `AudioPlayer` and disposes it with the widget, so only the
/// screen on top plays.
///
/// Public: used by the recording import and player screens.
class RecordingPlayer extends StatefulWidget {
  const RecordingPlayer({required this.path, this.onDuration, super.key});

  final String path;

  /// Called once the file is loaded and its length is known.
  final ValueChanged<Duration>? onDuration;

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  static const _speeds = [1.0, 1.5, 2.0];

  final _player = AudioPlayer();
  bool _ready = false;
  bool _failed = false;
  double _speed = 1;

  /// Seek bar position while the user drags it.
  double? _dragMs;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final duration = await _player.setFilePath(widget.path);
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
      if (duration != null) {
        widget.onDuration?.call(duration);
      }
    } on Object catch (e) {
      'Player could not open file: ${e.runtimeType}'.logWarning();
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlay(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (state.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
  }

  void _cycleSpeed() {
    final next = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length];
    setState(() => _speed = next);
    unawaited(_player.setSpeed(next));
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Row(
        children: [
          Icon(Icons.volume_off, color: context.colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "This phone can't play this file.",
              style: context.text.body.copyWith(color: context.colors.warning),
            ),
          ),
        ],
      );
    }
    if (!_ready) {
      return const LinearProgressIndicator();
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _player.playerState;
        final completed = state.processingState == ProcessingState.completed;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnapshot) {
            final total = _player.duration ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final positionMs =
                (_dragMs ??
                        (positionSnapshot.data ?? Duration.zero).inMilliseconds
                            .toDouble())
                    .clamp(0, maxMs > 0 ? maxMs : 0)
                    .toDouble();
            return Column(
              children: [
                Row(
                  children: [
                    IconButton.filled(
                      tooltip: state.playing && !completed ? 'Pause' : 'Play',
                      onPressed: () => _togglePlay(state),
                      icon: Icon(
                        completed
                            ? Icons.replay
                            : state.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        max: maxMs > 0 ? maxMs : 1,
                        value: maxMs > 0 ? positionMs : 0,
                        onChanged: maxMs > 0
                            ? (value) => setState(() => _dragMs = value)
                            : null,
                        onChangeEnd: (value) async {
                          await _player.seek(
                            Duration(milliseconds: value.round()),
                          );
                          if (mounted) {
                            setState(() => _dragMs = null);
                          }
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: _cycleSpeed,
                      child: Text('${_speed.toString().replaceAll('.0', '')}×'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        formatClock(Duration(milliseconds: positionMs.round())),
                        style: context.text.caption,
                      ),
                      const Spacer(),
                      Text(formatClock(total), style: context.text.caption),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// `3:05` or `1:02:07`.
String formatClock(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}
