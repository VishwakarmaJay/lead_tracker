/// Audio formats Lead Tracker accepts, and the safe file extension each is
/// stored with. The extension comes from this table only — never copied from
/// an incoming file name.
library;

const _extensionByMime = <String, String>{
  'audio/mp4': 'm4a',
  'audio/m4a': 'm4a',
  'audio/x-m4a': 'm4a',
  'audio/aac': 'aac',
  'audio/aacp': 'aac',
  'audio/amr': 'amr',
  'audio/amr-wb': 'awb',
  'audio/3gpp': '3gp',
  'audio/3gpp2': '3g2',
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
  'audio/wave': 'wav',
  'audio/mpeg': 'mp3',
  'audio/mp3': 'mp3',
  'audio/ogg': 'ogg',
  'audio/opus': 'opus',
  'audio/flac': 'flac',
  'audio/x-flac': 'flac',
  'audio/webm': 'webm',
};

const _mimeByExtension = <String, String>{
  'm4a': 'audio/mp4',
  'mp4': 'audio/mp4',
  'aac': 'audio/aac',
  'amr': 'audio/amr',
  'awb': 'audio/amr-wb',
  '3gp': 'audio/3gpp',
  '3g2': 'audio/3gpp2',
  'wav': 'audio/wav',
  'mp3': 'audio/mpeg',
  'ogg': 'audio/ogg',
  'oga': 'audio/ogg',
  'opus': 'audio/opus',
  'flac': 'audio/flac',
  'webm': 'audio/webm',
};

/// A recognised audio format.
typedef AudioFormat = ({String mimeType, String extension});

/// Works out the format from the MIME type, falling back to the extension of
/// [fileName] (some senders report `application/octet-stream`). Returns null
/// for anything that isn't a supported audio file.
AudioFormat? detectAudioFormat({String? mimeType, String? fileName}) {
  final mime = mimeType?.toLowerCase().split(';').first.trim();
  final fromMime = mime == null ? null : _extensionByMime[mime];
  if (fromMime != null) {
    return (mimeType: mime!, extension: fromMime);
  }
  final name = fileName?.toLowerCase() ?? '';
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) {
    return null;
  }
  final extension = name.substring(dot + 1);
  final mimeFromExtension = _mimeByExtension[extension];
  if (mimeFromExtension == null) {
    return null;
  }
  return (
    mimeType: mimeFromExtension,
    extension: extension == 'mp4' ? 'm4a' : extension,
  );
}
