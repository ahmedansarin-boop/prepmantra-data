import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../providers/content_provider.dart';
import '../providers/playback_persistence_provider.dart';
import '../widgets/category_card.dart';
import 'player_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final resumeData = ref.watch(playbackPersistenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PrepMantra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded),
            tooltip: 'Saved Episodes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Continue Listening card
          if (resumeData.episodeId != null)
            SliverToBoxAdapter(child: _buildContinueListening(context, resumeData)),

          // Heading
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'All Topics',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Category list
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No learning content available yet.')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      category: category,
                      onEpisodeTap: (episode) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              episodeId: episode.id,
                              title: episode.title,
                              audioUrl: episode.audioUrl,
                              duration: episode.duration,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: categories.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load content:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildContinueListening(BuildContext context, ResumeData data) {
    if (data.title == null || data.audioUrl == null) return const SizedBox();

    double progress = 0.0;
    if (data.durationSeconds > 0) {
      progress = (data.positionMs / (data.durationSeconds * 1000)).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              episodeId: data.episodeId!,
              title: data.title!,
              audioUrl: data.audioUrl!,
              duration: data.durationSeconds,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2A4A), Color(0xFF1A1A3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTINUE LISTENING',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title!,
                          style: const TextStyle(color: AppColors.onBackground, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.onSurface),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
