import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/download_service.dart';
import 'storage_provider.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DownloadService(prefs);
});

/// A StateNotifier to hold the reactive UI state of which episodes are downloaded
class DownloadStateNotifier extends StateNotifier<Set<String>> {
  final DownloadService _service;

  DownloadStateNotifier(this._service) : super({});

  bool isDownloaded(String episodeId) {
    if (state.contains(episodeId)) return true;
    return _service.isDownloaded(episodeId);
  }

  Future<void> fetchAndSave(String url, String episodeId) async {
    final path = await _service.downloadAudio(url, episodeId);
    if (path != null) {
      state = {...state, episodeId}; // Trigger UI rebuild on success
    }
  }
}

final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, Set<String>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return DownloadStateNotifier(service);
});
