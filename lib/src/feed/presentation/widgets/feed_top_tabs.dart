// lib/features/feed/presentation/widgets/feed_top_tabs.dart
import 'package:flutter/material.dart';
import '../../domain/feed_tab.dart';

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _blue = Color(0xff74BFFF);

/// Tab order the underlying [TabController]'s indices map to — must match
/// the outer PageView's page order in home_feed.dart.
const tabOrder = [FeedTab.following, FeedTab.forYou];

/// "Following | For you" switcher, built on Flutter's real [TabBar] (kept
/// in sync with the feed's own vertical-swipe PageView via [controller] —
/// see home_feed.dart) instead of a hand-rolled Row of GestureDetectors, so
/// it gets proper tap semantics, a correctly-sized touch target, and a
/// Material ink response for free — plain text labels otherwise gave no
/// feedback at all on tap.
class FeedTopTabs extends StatelessWidget {
  final TabController controller;

  const FeedTopTabs({required this.controller, super.key});

  static const _tabWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: _tabWidth * tabOrder.length,
          child: TabBar(
            controller: controller,
            indicator: const _GradientUnderlineIndicator(),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
            labelStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
            splashBorderRadius: BorderRadius.circular(20),
            overlayColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.1),
            ),
            tabs: const [
              Tab(text: 'Following'),
              Tab(text: 'For you'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints the same small gradient pill the old hand-rolled indicator used,
/// sitting under whichever tab is (or is animating towards being) selected
/// — TabBar recomputes and repaints this every frame the controller's
/// animation is running, same as the original AnimatedAlign did.
class _GradientUnderlineIndicator extends Decoration {
  const _GradientUnderlineIndicator();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GradientUnderlinePainter(onChanged);
}

class _GradientUnderlinePainter extends BoxPainter {
  _GradientUnderlinePainter(super.onChanged);

  static const _width = 30.0;
  static const _height = 3.5;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = Rect.fromLTWH(
      offset.dx + (size.width - _width) / 2,
      offset.dy + size.height - _height - 6,
      _width,
      _height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [_pink, _purple, _blue],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
}
