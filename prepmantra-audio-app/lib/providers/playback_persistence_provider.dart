import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_provider.dart';

class ResumeData {
  final String? episodeId;
  final String? title;
  final String? audioUrl;
  final int positionMs;
  final int durationSeconds;

  ResumeData({
    this.episodeId,
    this.title,
    this.audioUrl,
    this.positionMs = 0,
    this.durationSeconds = 0,
  });
}

class PlaybackPersistenceNotifier extends StateNotifier<ResumeData> {
  final SharedPreferences _prefs;

  static const _kEpisodeId = 'resume_episode_id';
  static const _kTitle = 'resume_title';
  static const _kAudioUrl = 'resume_audio_url';
  static const _kPositionMs = 'resume_position_ms';
  static const _kDurationSec = 'resume_duration_sec';

  PlaybackPersistenceNotifier(this._prefs) : super(ResumeData()) {
    _load();
  }

  void _load() {
    state = ResumeData(
      episodeId: _prefs.getString(_kEpisodeId),
      title: _prefs.getString(_kTitle),
      audioUrl: _prefs.getString(_kAudioUrl),
      positionMs: _prefs.getInt(_kPositionMs) ?? 0,
      durationSeconds: _prefs.getInt(_kDurationSec) ?? 0,
    );
  }

  Future<void> saveEpisode({
    required String episodeId,
    required String title,
    required String audioUrl,
    required int durationSeconds,
  }) async {
    await _prefs.setString(_kEpisodeId, episodeId);
    await _prefs.setString(_kTitle, title);
    await _prefs.setString(_kAudioUrl, audioUrl);
    await _prefs.setInt(_kDurationSec, durationSeconds);
    
    state = ResumeData(
      episodeId: episodeId,
      title: title,
      audioUrl: audioUrl,
      positionMs: state.positionMs, // Maintain trailing position briefly until update triggers
      durationSeconds: durationSeconds,
    );
  }

  Future<void> savePosition(int positionMs) async {
    await _prefs.setInt(_kPositionMs, positionMs);
    state = ResumeData(
      episodeId: state.episodeId,
      title: state.title,
      audioUrl: state.audioUrl,
      positionMs: positionMs,
      durationSeconds: state.durationSeconds,
    );
  }
}

final playbackPersistenceProvider = StateNotifierProvider<PlaybackPersistenceNotifier, ResumeData>((ref) {
  return PlaybackPersistenceNotifier(ref.watch(sharedPreferencesProvider));
});
