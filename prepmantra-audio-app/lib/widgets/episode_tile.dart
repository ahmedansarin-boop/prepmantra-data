import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
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
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(episode.id);
    final isDownloaded = ref.watch(downloadStateProvider.notifier).isDownloaded(episode.id);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Play icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),

            // Title + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(episode.duration),
                    style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Favorite icon
            GestureDetector(
              onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(episode.id),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.favorite : AppColors.onSurface,
                  size: 20,
                ),
              ),
            ),

            // Download icon
            GestureDetector(
              onTap: isDownloaded
                  ? null
                  : () {
                      ref.read(downloadStateProvider.notifier).fetchAndSave(episode.audioUrl, episode.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading "${episode.title}"...')),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                  color: isDownloaded ? AppColors.success : AppColors.onSurface,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
