import 'dart:async';
import 'package:audio_service/audio_service.dart' as sys;
import 'package:just_audio/just_audio.dart';
import 'audio_handler.dart';
import '../providers/playback_persistence_provider.dart';

class AudioService {
  final AppAudioHandler _handler;
  final PlaybackPersistenceNotifier _persistence;
  StreamSubscription? _posSub;

  AudioService(this._handler, this._persistence) {
    _initPersistenceTracking();
  }

  void _initPersistenceTracking() {
    DateTime lastSave = DateTime.now();
    _posSub = _handler.player.positionStream.listen((pos) {
      final now = DateTime.now();
      // Throttle saving the duration payload to once every 5 seconds to minimize IO writes
      if (now.difference(lastSave).inSeconds >= 5) {
        _persistence.savePosition(pos.inMilliseconds);
        lastSave = now;
      }
    });
  }

  AudioPlayer get player => _handler.player;

  Future<void> play(
    String url, {
    required String title, 
    required String episodeId, 
    required int duration,
    String? localPath,
    Duration? startPosition,
  }) async {
    // Notify persistence engine about active track
    await _persistence.saveEpisode(
      episodeId: episodeId,
      title: title,
      audioUrl: url,
      durationSeconds: duration,
    );

    final item = sys.MediaItem(
      id: episodeId,
      title: title,
      album: 'PrepMantra Learning',
      duration: Duration(seconds: duration),
    );
    await _handler.playCustom(url: url, item: item, localPath: localPath, startPosition: startPosition);
  }

  Future<void> resume() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);

  void dispose() {
    _posSub?.cancel();
  }
}
