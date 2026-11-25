import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_probe.g.dart';

/// Checks a file can be decoded on this phone and returns its duration;
/// null when the player can't open it.
typedef AudioProbe = Future<Duration?> Function(String path);

Future<Duration?> probeWithJustAudio(String path) async {
  final player = AudioPlayer();
  try {
    return await player.setFilePath(path).timeout(const Duration(seconds: 8));
  } on Object {
    return null;
  } finally {
    await player.dispose();
  }
}

@riverpod
AudioProbe audioProbe(Ref ref) => probeWithJustAudio;
