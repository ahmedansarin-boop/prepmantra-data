import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/audio_handler.dart';
import 'playback_persistence_provider.dart';

final appAudioHandlerProvider = Provider<AppAudioHandler>((ref) {
  throw UnimplementedError('Initialize appAudioHandlerProvider in main.dart');
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final handler = ref.watch(appAudioHandlerProvider);
  final persistence = ref.watch(playbackPersistenceProvider.notifier);
  return AudioService(handler, persistence);
});
