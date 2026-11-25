import 'package:flutter_test/flutter_test.dart';
import 'package:lead_tracker/src/recordings/data/audio_formats.dart';

void main() {
  test('format comes from the MIME type first', () {
    expect(detectAudioFormat(mimeType: 'audio/mp4', fileName: 'x.wav'), (
      mimeType: 'audio/mp4',
      extension: 'm4a',
    ));
    expect(detectAudioFormat(mimeType: 'audio/AMR; codecs=x'), (
      mimeType: 'audio/amr',
      extension: 'amr',
    ));
  });

  test('falls back to the file extension for generic MIME types', () {
    expect(
      detectAudioFormat(
        mimeType: 'application/octet-stream',
        fileName: 'Call with Asha.M4A',
      ),
      (mimeType: 'audio/mp4', extension: 'm4a'),
    );
    expect(detectAudioFormat(fileName: 'rec.mp4'), (
      mimeType: 'audio/mp4',
      extension: 'm4a',
    ));
  });

  test('rejects anything that is not supported audio', () {
    expect(detectAudioFormat(mimeType: 'image/png', fileName: 'a.png'), isNull);
    expect(detectAudioFormat(mimeType: 'video/mp4', fileName: 'clip'), isNull);
    expect(detectAudioFormat(fileName: 'noextension'), isNull);
    expect(detectAudioFormat(fileName: 'trailingdot.'), isNull);
    expect(detectAudioFormat(), isNull);
  });
}
