import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;

class VoiceRecorderService {
  final _record = AudioRecorder();

  Future<void> startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

        const config = RecordConfig();
        await _record.start(config, path: path);
      }
    } catch (e) {
      // ignored
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _record.stop();
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _record.dispose();
  }

  bool isRecording() {
    // Note: AudioRecorder doesn't have a simple isRecording getter in 6.x
    // but we can track it manually if needed.
    return false; // This is just a placeholder
  }
}
