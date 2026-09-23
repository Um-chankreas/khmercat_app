import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Pill tab bar with a gradient thumb that slides between tabs, and a body
/// that cross-fades when the selection changes. Reused wherever a
/// profile-style screen needs a small set of content tabs. Pass [labels] for
/// icon + text tabs, or omit them for an icon-only bar.
class ProfileIconTabStrip extends HookWidget {
  final List<String> icons;
  final List<String>? labels;

  /// Tabs that trigger [onAction] instead of switching the body (e.g. opening
  /// an edit sheet or a confirmation dialog).
  final Set<int> actionIndexes;
  final ValueChanged<int>? onAction;
  final Widget Function(BuildContext context, int selectedIndex) bodyBuilder;

  const ProfileIconTabStrip({
    required this.icons,
    required this.bodyBuilder,
    this.labels,
    this.actionIndexes = const {},
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selected = useState(0);
    return Column(
      children: [
        ProfileTabBar(
          icons: icons,
          labels: labels,
          selectedIndex: selected.value,
          onChanged: (i) {
            if (actionIndexes.contains(i)) {
              onAction?.call(i);
            } else {
              selected.value = i;
            }
          },
        ),
        const Gap(8),
        ProfileTabBody(
          index: selected.value,
          child: bodyBuilder(context, selected.value),
        ),
      ],
    );
  }
}

/// Cross-fades and size-animates between tab bodies. Keyed by [index].
class ProfileTabBody extends StatelessWidget {
  final int index;
  final Widget child;
  const ProfileTabBody({required this.index, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(index), child: child),
      ),
    );
  }
}

/// The pill tab bar itself, with selection owned by the caller — so it can
/// live in a pinned sliver header while the body scrolls beneath it.
class ProfileTabBar extends StatelessWidget {
  final List<String> icons;
  final List<String>? labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ProfileTabBar({
    required this.icons,
    required this.selectedIndex,
    required this.onChanged,
    this.labels,
    super.key,
  });

  static double heightFor({required bool withLabels}) => withLabels ? 56 : 48;

  @override
  Widget build(BuildContext context) {
    final n = icons.length;
    final showLabels = labels != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: heightFor(withLabels: showLabels),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ProfileTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
        boxShadow: ProfileTheme.cardShadow(),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: n <= 1
                ? Alignment.center
                : Alignment(-1 + 2 * selectedIndex / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ProfileTheme.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: ProfileTheme.purple.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(n, (i) {
              final isSelected = selectedIndex == i;
              final color = isSelected
                  ? Colors.white
                  : ProfileTheme.textSecondary(context).withValues(alpha: 0.7);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.12 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Image.asset(
                            icons[i],
                            width: 21,
                            height: 21,
                            color: color,
                          ),
                        ),
                        if (showLabels) ...[
                          const Gap(3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: color,
                            ),
                            child: Text(
                              labels![i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
