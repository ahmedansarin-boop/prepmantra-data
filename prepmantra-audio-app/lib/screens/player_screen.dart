import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../providers/audio_provider.dart';
import '../providers/download_provider.dart';
import '../providers/favorites_provider.dart';
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

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _artworkCtrl;
  late final Animation<double> _artworkAnim;

  @override
  void initState() {
    super.initState();
    _artworkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _artworkAnim = CurvedAnimation(
      parent: _artworkCtrl,
      curve: Curves.easeOutBack,
    );
    _artworkCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localPath =
          ref.read(downloadServiceProvider).getLocalPath(widget.episodeId);
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
  void dispose() {
    _artworkCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final isFavorite =
        ref.watch(favoritesProvider).contains(widget.episodeId);
    final isDownloaded = ref
        .watch(downloadStateProvider.notifier)
        .isDownloaded(widget.episodeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: AppColors.onBackground,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'NOW PLAYING',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),

            // ── Artwork ──────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: ScaleTransition(
                  scale: _artworkAnim,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1C2A6A), Color(0xFF2E1060)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.headphones_rounded,
                          size: 90,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Title + subtitle ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PrepMantra · ADPO Learning',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Favorite + Download actions ───────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallAction(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        isFavorite ? AppColors.favorite : AppColors.onSurface,
                    tooltip:
                        isFavorite ? 'Remove favorite' : 'Add to favorites',
                    onTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(widget.episodeId),
                  ),
                  const SizedBox(width: 20),
                  _SmallAction(
                    icon: isDownloaded
                        ? Icons.check_circle_rounded
                        : Icons.download_for_offline_rounded,
                    color:
                        isDownloaded ? AppColors.success : AppColors.onSurface,
                    tooltip: isDownloaded ? 'Downloaded' : 'Download',
                    onTap: isDownloaded
                        ? null
                        : () {
                            ref
                                .read(downloadStateProvider.notifier)
                                .fetchAndSave(widget.audioUrl, widget.episodeId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Downloading "${widget.title}"…'),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),

            // ── Seek slider + timestamps ──────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<Duration>(
                  stream: audioService.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final playerDuration = audioService.player.duration ??
                        Duration(seconds: widget.duration);

                    double progress = 0.0;
                    if (playerDuration.inMilliseconds > 0) {
                      progress = (position.inMilliseconds /
                              playerDuration.inMilliseconds)
                          .clamp(0.0, 1.0);
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceVariant,
                            thumbColor: Colors.white,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (val) {
                              final newPos = Duration(
                                milliseconds: (val *
                                        playerDuration.inMilliseconds)
                                    .toInt(),
                              );
                              audioService.seek(newPos);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(position),
                                  style: AppTextStyles.caption),
                              Text(_fmt(playerDuration),
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Playback controls ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10s
                  _ControlBtn(
                    icon: Icons.replay_10_rounded,
                    size: 28,
                    onTap: () {
                      final current = audioService.player.position;
                      audioService
                          .seek(current - const Duration(seconds: 10));
                    },
                  ),
                  const SizedBox(width: 28),

                  // Play / Pause
                  StreamBuilder<bool>(
                    stream: audioService.player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return GestureDetector(
                        onTap: () => isPlaying
                            ? audioService.pause()
                            : audioService.resume(),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 28),

                  // Forward 10s
                  _ControlBtn(
                    icon: Icons.forward_10_rounded,
                    size: 28,
                    onTap: () {
                      final current = audioService.player.position;
                      audioService
                          .seek(current + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skip button (rewind / forward) ─────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlBtn(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.onBackground, size: size),
      ),
    );
  }
}

// ─── Small action icon ───────────────────────────────────────────────────────
class _SmallAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _SmallAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
