import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
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

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  /// Safely compute total duration from episode list (in seconds).
  String _totalDuration() {
    final episodes = widget.category.episodes;
    if (episodes.isEmpty) return '';
    final totalSeconds = episodes.fold<int>(0, (sum, e) => sum + e.duration);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m total';
  }

  @override
  Widget build(BuildContext context) {
    final episodeCount = widget.category.episodes.length;
    final totalDur = _totalDuration();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.divider,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Artwork box
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.artworkGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.name,
                              style: AppTextStyles.h3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _Badge(
                                  icon: Icons.music_note_rounded,
                                  label: '$episodeCount ep',
                                ),
                                if (totalDur.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _Badge(
                                    icon: Icons.timer_outlined,
                                    label: totalDur,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Play / Continue button
                            _PlayPill(
                              label: _expanded ? 'Hide Episodes' : 'View Episodes',
                              expanded: _expanded,
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _expanded
                              ? AppColors.primary
                              : AppColors.onSurface,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Animated episode list ────────────────────────────────────
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _expanded
                    ? FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            ...widget.category.episodes.map((episode) => Column(
                                  children: [
                                    EpisodeTile(
                                      episode: episode,
                                      onTap: () => widget.onEpisodeTap(episode),
                                    ),
                                    if (episode !=
                                        widget.category.episodes.last)
                                      const Divider(
                                        height: 1,
                                        indent: 72,
                                        endIndent: 16,
                                        color: AppColors.divider,
                                      ),
                                  ],
                                )),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small info badge ─────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.onSurface),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.badge),
        ],
      ),
    );
  }
}

// ─── Play / View pill button ──────────────────────────────────────────────────
class _PlayPill extends StatelessWidget {
  final String label;
  final bool expanded;

  const _PlayPill({required this.label, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: expanded ? null : AppColors.primaryGradient,
        color: expanded ? AppColors.surfaceVariant : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expanded ? Icons.keyboard_arrow_up_rounded : Icons.play_arrow_rounded,
            size: 14,
            color: expanded ? AppColors.onSurface : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: expanded ? AppColors.onSurface : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
