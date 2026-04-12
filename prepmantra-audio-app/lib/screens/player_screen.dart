import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../providers/audio_provider.dart';
import '../providers/download_provider.dart';
import '../providers/playback_persistence_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String title;
  final String audioUrl;
  final int duration;

  const PlayerScreen({
    super.key,
    required this.episodeId,
    required this.title,
    required this.audioUrl,
    required this.duration,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localPath = ref.read(downloadServiceProvider).getLocalPath(widget.episodeId);
      final resume = ref.read(playbackPersistenceProvider);

      Duration? startPos;
      if (resume.episodeId == widget.episodeId && resume.positionMs > 0) {
        final maxMs = widget.duration * 1000;
        if (resume.positionMs < maxMs) {
          startPos = Duration(milliseconds: resume.positionMs);
        }
      }

      ref.read(audioServiceProvider).play(
            widget.audioUrl,
            title: widget.title,
            episodeId: widget.episodeId,
            duration: widget.duration,
            localPath: localPath,
            startPosition: startPos,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Artwork placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2A4A), Color(0xFF252545)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.headphones_rounded, size: 80, color: AppColors.primary),
              ),

              const Spacer(flex: 2),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),
              const Text(
                'PrepMantra · ADPO Learning',
                style: TextStyle(color: AppColors.onSurface, fontSize: 13),
              ),

              const Spacer(flex: 2),

              // Progress bar
              StreamBuilder<Duration>(
                stream: audioService.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final playerDuration = audioService.player.duration ?? Duration(seconds: widget.duration);

                  double progress = 0.0;
                  if (playerDuration.inMilliseconds > 0) {
                    progress = (position.inMilliseconds / playerDuration.inMilliseconds).clamp(0.0, 1.0);
                  }

                  return Column(
                    children: [
                      // Seekable progress bar
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceVariant,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (val) {
                            final newPos = Duration(
                              milliseconds: (val * playerDuration.inMilliseconds).toInt(),
                            );
                            audioService.seek(newPos);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(position), style: const TextStyle(color: AppColors.onSurface, fontSize: 12)),
                            Text(_fmt(playerDuration), style: const TextStyle(color: AppColors.onSurface, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 1),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10s
                  _ControlButton(
                    icon: Icons.replay_10_rounded,
                    size: 32,
                    onTap: () {
                      final current = audioService.player.position;
                      audioService.seek(current - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: 24),

                  // Play / Pause toggle
                  StreamBuilder<bool>(
                    stream: audioService.player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return GestureDetector(
                        onTap: () => isPlaying ? audioService.pause() : audioService.resume(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 24),

                  // Forward 10s
                  _ControlButton(
                    icon: Icons.forward_10_rounded,
                    size: 32,
                    onTap: () {
                      final current = audioService.player.position;
                      audioService.seek(current + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Small helper widget to keep code clean ──────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.onSurface, size: size),
    );
  }
}
