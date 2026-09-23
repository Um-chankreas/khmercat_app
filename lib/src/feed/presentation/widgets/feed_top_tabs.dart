// lib/features/feed/presentation/widgets/feed_top_tabs.dart
import 'package:flutter/material.dart';
import '../../domain/feed_tab.dart';

/// "Following | For you" switcher: plain text labels with a gradient
/// underline that slides to the selected one — no background or border.
class FeedTopTabs extends StatelessWidget {
  final FeedTab selected;
  final ValueChanged<FeedTab> onChanged;

  const FeedTopTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  static const _tabWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    final isFollowing = selected == FeedTab.following;
    // Row (not Center): Center would stretch the tabs to the full
    // height the parent offers instead of hugging the text.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: _tabWidth * 2,
            child: Stack(
              children: [
                Row(
                  children: [
                    _TabLabel(
                      text: 'Following',
                      isActive: isFollowing,
                      onTap: () => onChanged(FeedTab.following),
                    ),
                    _TabLabel(
                      text: 'For you',
                      isActive: !isFollowing,
                      onTap: () => onChanged(FeedTab.forYou),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: isFollowing
                          ? const Alignment(-0.5, 1)
                          : const Alignment(0.5, 1),
                      child: Container(
                        width: 30,
                        height: 3.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xffFF54AB),
                              Color(0xff9B6BFF),
                              Color(0xff74BFFF),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff9B6BFF,
                              ).withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _TabLabel({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FeedTopTabs._tabWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          // heightFactor: 1 — a plain Center would grow to the full screen
          // height when the tabs are stacked over the video.
          child: Center(
            heightFactor: 1,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: isActive ? 17 : 16,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.2,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}
