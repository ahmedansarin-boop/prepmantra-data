import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/episode.dart';
import '../providers/download_provider.dart';
import '../providers/favorites_provider.dart';

class EpisodeTile extends ConsumerWidget {
  final Episode episode;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.onTap,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(episode.id);
    final isDownloaded =
        ref.watch(downloadStateProvider.notifier).isDownloaded(episode.id);

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.07),
      highlightColor: AppColors.primary.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // ── Circle play button ─────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),

            // ── Title + meta row ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (episode.duration > 0) ...[
                        const Icon(
                          Icons.timer_outlined,
                          size: 11,
                          color: AppColors.onSurface,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(episode.duration),
                          style: AppTextStyles.caption,
                        ),
                      ],
                      if (isDownloaded) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.offline_bolt_rounded,
                                  size: 10, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text(
                                'Offline',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Favorite button ────────────────────────────────────────
            _ActionIcon(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.favorite : AppColors.onSurface,
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              onTap: () =>
                  ref.read(favoritesProvider.notifier).toggleFavorite(episode.id),
            ),

            // ── Download button ────────────────────────────────────────
            _ActionIcon(
              icon: isDownloaded
                  ? Icons.check_circle_rounded
                  : Icons.download_for_offline_rounded,
              color: isDownloaded ? AppColors.success : AppColors.onSurface,
              tooltip: isDownloaded ? 'Downloaded' : 'Download',
              onTap: isDownloaded
                  ? null
                  : () {
                      ref
                          .read(downloadStateProvider.notifier)
                          .fetchAndSave(episode.audioUrl, episode.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading "${episode.title}"…'),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact icon button with circular ink ───────────────────────────────────
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionIcon({
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}
