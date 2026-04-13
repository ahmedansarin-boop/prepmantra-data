import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../providers/content_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/episode_tile.dart';
import '../widgets/skeleton_loader.dart';
import 'player_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesSet = ref.watch(favoritesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Episodes'),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          // ── Empty favorites ──────────────────────────────────────────
          if (favoritesSet.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              headline: 'No favorites yet',
              message:
                  'Tap the ♡ on any episode to save it here for quick access.',
            );
          }

          // Flat-map all episodes and filter by favorited IDs
          final favEpisodes = categories
              .expand((cat) => cat.episodes)
              .where((ep) => favoritesSet.contains(ep.id))
              .toList();

          // Favorited IDs exist but episodes removed remotely
          if (favEpisodes.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_off_rounded,
              headline: 'Episodes unavailable',
              message:
                  'Your favorited episodes no longer exist in the current content.',
            );
          }

          // ── Episode list ─────────────────────────────────────────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('${favEpisodes.length} saved',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('episodes', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: favEpisodes.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final episode = favEpisodes[index];
                    return EpisodeTile(
                      episode: episode,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            episodeId: episode.id,
                            title: episode.title,
                            audioUrl: episode.audioUrl,
                            duration: episode.duration,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const FavoritesScreenSkeleton(),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          headline: 'Something went wrong',
          message: err.toString(),
        ),
      ),
    );
  }
}
