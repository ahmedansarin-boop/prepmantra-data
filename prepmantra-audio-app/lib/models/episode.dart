import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String title,
    required String description,
    // Maps "audio_url" in JSON → audioUrl in Dart
    // ignore: invalid_annotation_target
    @JsonKey(name: 'audio_url') required String audioUrl,
    required int duration, // in seconds
    required int order,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
}

