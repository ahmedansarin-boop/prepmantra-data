import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/category.dart';
import '../models/episode.dart';
import 'episode_tile.dart';

class CategoryCard extends StatefulWidget {
  final Category category;
  final void Function(Episode episode) onEpisodeTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEpisodeTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header tap area
          InkWell(
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_rounded, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.category.episodes.length} episodes',
                          style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurface,
                  ),
                ],
              ),
            ),
          ),

          // Expandable episode list
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            ...widget.category.episodes.map((episode) => Column(
              children: [
                EpisodeTile(
                  episode: episode,
                  onTap: () => widget.onEpisodeTap(episode),
                ),
                if (episode != widget.category.episodes.last)
                  const Divider(height: 1, indent: 68, color: AppColors.divider),
              ],
            )),
          ],
        ],
      ),
    );
  }
}
