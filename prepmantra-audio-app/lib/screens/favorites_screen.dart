import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../providers/content_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/episode_tile.dart';
import 'player_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesSet = ref.watch(favoritesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Episodes')),
      body: categoriesAsync.when(
        data: (categories) {
          if (favoritesSet.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.onSurface),
                  SizedBox(height: 16),
                  Text('No favorites yet', style: TextStyle(color: AppColors.onBackground, fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Tap ♡ on any episode to save it here', style: TextStyle(color: AppColors.onSurface, fontSize: 13)),
                ],
              ),
            );
          }

          // Build flat list preserving remote removal safety
          final favEpisodes = categories
              .expand((cat) => cat.episodes)
              .where((ep) => favoritesSet.contains(ep.id))
              .toList();

          if (favEpisodes.isEmpty) {
            return const Center(
              child: Text(
                'Favorited episodes are no longer available.',
                style: TextStyle(color: AppColors.onSurface),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favEpisodes.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 68, color: AppColors.divider),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}
