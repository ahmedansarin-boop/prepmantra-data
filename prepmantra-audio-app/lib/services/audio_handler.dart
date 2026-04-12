import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  AppAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    _player.processingStateStream.listen((ProcessingState state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  Future<void> playCustom({
    required String url, 
    required MediaItem item, 
    String? localPath,
    Duration? startPosition,
  }) async {
    mediaItem.add(item);
    
    if (_player.playing) {
      await _player.stop();
    }
    
    // Inject the initial position payload via just_audio's native configurations avoiding seek delays
    if (localPath != null && File(localPath).existsSync()) {
      debugPrint('HANDLER: Playing local file -> $localPath');
      await _player.setFilePath(localPath, initialPosition: startPosition);
    } else {
      debugPrint('HANDLER: Streaming from URL -> $url');
      await _player.setUrl(url, initialPosition: startPosition);
    }
    
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
