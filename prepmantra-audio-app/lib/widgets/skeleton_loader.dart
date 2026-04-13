import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// ─── Animated shimmer box ───────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: const [
                Color(0xFF16163A),
                Color(0xFF26265A),
                Color(0xFF16163A),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
            ),
          ),
        );
      },
    );
  }
}

// ─── Single course-card skeleton ────────────────────────────────────────────
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Artwork placeholder
          const _ShimmerBox(width: 64, height: 64, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: double.infinity, height: 14, radius: 6),
                const SizedBox(height: 8),
                _ShimmerBox(width: MediaQuery.of(context).size.width * 0.35, height: 11, radius: 6),
                const SizedBox(height: 12),
                const _ShimmerBox(width: 80, height: 28, radius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full home-screen skeleton ───────────────────────────────────────────────
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, __) => const CourseCardSkeleton(),
        childCount: 5,
      ),
    );
  }
}

// ─── Favorites list skeleton ─────────────────────────────────────────────────
class EpisodeTileSkeleton extends StatelessWidget {
  const EpisodeTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _ShimmerBox(width: 40, height: 40, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ShimmerBox(width: double.infinity, height: 13, radius: 5),
                const SizedBox(height: 6),
                _ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.28,
                  height: 10,
                  radius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _ShimmerBox(width: 24, height: 24, radius: 12),
          const SizedBox(width: 8),
          const _ShimmerBox(width: 24, height: 24, radius: 12),
        ],
      ),
    );
  }
}

class FavoritesScreenSkeleton extends StatelessWidget {
  const FavoritesScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: 6,
      itemBuilder: (_, __) => const EpisodeTileSkeleton(),
    );
  }
}
