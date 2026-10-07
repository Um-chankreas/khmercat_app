import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

// =============================================================================
// Search bar + filter chips + tabs (the sticky header)
// =============================================================================

/// Deep pink used for links and accents on the search screen ("See all",
/// focus).
const searchAccent = Color(0xffB0125A);

/// Pink → periwinkle wash behind the selected chip.
const searchSoftGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xffF5B5DC), Color(0xffA9C1F5)],
);

/// Soft shadow under the white search bar, chips and cards.
List<BoxShadow> searchShadow() => [
  BoxShadow(
    color: const Color(0xff5B3FA8).withValues(alpha: 0.07),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
];

/// The search tab's backdrop: plain white with the logo's cat head faded
/// into the top-right and bottom-left corners. Dark mode keeps the plain
/// page color and only a faint cat.
class SearchBackdrop extends StatelessWidget {
  const SearchBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final cat = (width * 0.92).clamp(280.0, 480.0);
    // Each is painted once; the boundary keeps it out of scroll repaints.
    Widget logo({required double opacity}) {
      return RepaintBoundary(
        child: Image.asset(
          AssetsName.appLogoTrsm,
          opacity: AlwaysStoppedAnimation(opacity),
          // Decoded at on-screen size, not the 1198px source.
          cacheWidth: (cat * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      );
    }

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: isDark ? null : Colors.white),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Top-right and bottom-left, each hanging off its corner.
            Positioned(
              right: -cat * 0.16,
              top: -cat * 0.04,
              width: cat,
              // Behind the search bar, chips and heading, so it's fainter
              // to stay out of their way.
              child: logo(opacity: isDark ? 0.05 : 0.09),
            ),
            Positioned(
              left: -cat * 0.16,
              bottom: -cat * 0.10,
              width: cat,
              child: logo(opacity: isDark ? 0.06 : 0.13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square icon button that sits beside the search bar and matches it: the
/// same white field, corner radius, hairline border and shadow.
class SearchActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const SearchActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.07),
              width: 1.2,
            ),
            boxShadow: searchShadow(),
          ),
          child: Icon(icon, size: 22, color: ProfileTheme.textPrimary(context)),
        ),
      ),
    );
  }
}

class SearchInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const SearchInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        // White field floating on the backdrop; the outline turns pink
        // while typing.
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused
              ? searchAccent.withValues(alpha: 0.55)
              : onSurface.withValues(alpha: 0.07),
          width: 1.2,
        ),
        boxShadow: searchShadow(),
      ),
      child: Row(
        children: [
          const Gap(16),
          Icon(
            Icons.search_rounded,
            size: 22,
            color: ProfileTheme.textPrimary(context),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              // Any touch outside the field (results, chips, tabs, a scroll)
              // hides the keyboard.
              onTapOutside: (_) => focusNode.unfocus(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search restaurants or dishes',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: ProfileTheme.textSecondary(context),
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: searchAccent,
                ),
              ),
            )
          else if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.cancel_rounded,
                size: 20,
                color: ProfileTheme.textSecondary(context),
              ),
              onPressed: onClear,
            )
          else
            const Gap(12),
        ],
      ),
    );
  }
}

/// Horizontal, scrollable row of filter pills. A pill with [FilterPill.divider]
/// gets a thin separator after it (used to split the sort toggle from the
/// cuisine filters).
class FilterChipsRow extends StatelessWidget {
  final List<FilterPill> pills;
  const FilterChipsRow({required this.pills, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Room for the chips' soft shadows.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pills.length,
        separatorBuilder: (_, i) => pills[i].divider
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: ProfileTheme.purple.withValues(alpha: 0.2),
                ),
              )
            : const Gap(8),
        itemBuilder: (context, i) => _Pill(pill: pills[i]),
      ),
    );
  }
}

class FilterPill {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;
  const FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.divider = false,
  });
}

class _Pill extends StatefulWidget {
  final FilterPill pill;
  const _Pill({required this.pill});

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final selected = pill.selected;
    // The wash is light in both themes, so selected text is always dark.
    final fg = selected ? ProfileTheme.ink : ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        pill.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            // Selected: gradient wash. Idle: white with a thin outline.
            gradient: selected ? searchSoftGradient : null,
            color: selected ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.09),
            ),
            boxShadow: selected ? null : searchShadow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pill.icon != null) ...[
                Icon(pill.icon, size: 16, color: fg),
                const Gap(6),
              ],
              Text(
                pill.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab in [SearchTabs]: a label plus an optional result count.
typedef SearchTab = ({String label, int? count});

/// All | Restaurants 12 | Videos 8 | Users 4 — left aligned, horizontally
/// scrollable, with a gradient underline and a pink dot on the active tab
/// when it has no count badge.
class SearchTabs extends StatelessWidget {
  final List<SearchTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const SearchTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ProfileTheme.hairlineColor(context)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: _TabItem(
                  tab: tabs[i],
                  active: i == selected,
                  muted: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final SearchTab tab;
  final bool active;
  final Color muted;
  const _TabItem({
    required this.tab,
    required this.active,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final count = tab.count;
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? ProfileTheme.textPrimary(context) : muted,
                  ),
                  child: Text(tab.label),
                ),
                if (count != null) ...[
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileTheme.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                  ),
                ] else if (active) ...[
                  const Gap(5),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ProfileTheme.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Underline, as wide as the tab's label row.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: active ? 1 : 0,
            child: Container(
              height: 3,
              width: 28,
              decoration: BoxDecoration(
                gradient: ProfileTheme.pinkPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section chrome
// =============================================================================

/// Bold section heading with an optional pink text action ("See all").
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionTitle({
    required this.title,
    this.actionText,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
        ),
        if (actionText != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: searchAccent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Large icon in a soft ringed circle, title, message, optional tips,
/// tappable suggestions and an action button.
class SearchMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<String> tips;
  final String? suggestionsLabel;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestion;
  final Widget? action;
  const SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.tips = const [],
    this.suggestionsLabel,
    this.suggestions = const [],
    this.onSuggestion,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          28,
          24,
          28,
          40 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ProfileTheme.purple.withValues(alpha: 0.06),
                ),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ProfileTheme.pink.withValues(alpha: 0.16),
                          ProfileTheme.blue.withValues(alpha: 0.24),
                        ],
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (r) =>
                          ProfileTheme.gradient.createShader(r),
                      child: Icon(icon, size: 48, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Gap(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: ProfileTheme.muted,
              ),
            ),
            if (tips.isNotEmpty) ...[
              const Gap(18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ProfileTheme.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in tips)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 15,
                                color: ProfileTheme.purple,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: ProfileTheme.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const Gap(20),
              Text(
                suggestionsLabel ?? 'Try searching for',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions)
                    Material(
                      color: ProfileTheme.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSuggestion?.call(s),
                        splashColor: ProfileTheme.purple.withValues(
                          alpha: 0.16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: ProfileTheme.deepPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (action != null) ...[const Gap(22), action!],
          ],
        ),
      ),
    );
  }
}

class GradientTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const GradientTextButton({
    required this.text,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          gradient: ProfileTheme.gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: ProfileTheme.purple.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const Gap(8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List / grid layout switch.
class ViewToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;
  const ViewToggle({required this.grid, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, bool value) {
      final active = grid == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            gradient: active ? ProfileTheme.pinkPurple : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active ? Colors.white : ProfileTheme.muted,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ProfileTheme.purple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.view_agenda_rounded, false),
          button(Icons.grid_view_rounded, true),
        ],
      ),
    );
  }
}

// =============================================================================
// Location prompt
// =============================================================================

class EnableLocationCard extends StatelessWidget {
  final VoidCallback onEnable;
  const EnableLocationCard({required this.onEnable, super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: ProfileTheme.purpleBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Gap(14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable location',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                Gap(2),
                Text(
                  'See restaurants near you and how far they are.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: ProfileTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          GestureDetector(
            onTap: onEnable,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: ProfileTheme.pinkPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Enable',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Result cards
// =============================================================================

class NetImage extends StatelessWidget {
  final String? url;
  final IconData fallback;

  /// Logical width it's shown at; the image is decoded at that size (times
  /// the screen density) instead of full resolution.
  final double? cacheWidth;
  const NetImage({
    required this.url,
    this.fallback = Icons.storefront_rounded,
    this.cacheWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        memCacheWidth: cacheWidth == null
            ? null
            : (cacheWidth! * MediaQuery.devicePixelRatioOf(context)).round(),
        placeholder: (_, _) => const _Placeholder(),
        errorWidget: (_, _, _) => _Placeholder(icon: fallback),
      );
    }
    return _Placeholder(icon: fallback);
  }
}

class _Placeholder extends StatelessWidget {
  final IconData? icon;
  const _Placeholder({this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ProfileTheme.coverFallback),
      child: icon == null
          ? null
          : Center(child: Icon(icon, color: Colors.white)),
    );
  }
}

void openRestaurant(String id) => AppRouter.router.pushNamed(
  AppRoute.restaurantProfile.name,
  pathParameters: {'id': id},
);

class VideoResultTile extends StatelessWidget {
  final VideoFeedItem video;
  final VoidCallback? onOpened;
  const VideoResultTile({required this.video, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    final likes = video.likesCount;
    return GestureDetector(
      onTap: () {
        onOpened?.call();
        AppRouter.router.pushNamed(
          AppRoute.videoViewer.name,
          pathParameters: {'id': video.id},
          extra: video,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetImage(
              url: video.thumbnailUrl,
              fallback: Icons.play_circle_outline_rounded,
              cacheWidth: MediaQuery.sizeOf(context).width / 3,
            ),
            // "▶ 2 likes" pill, bottom-left.
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const Gap(2),
                    Text(
                      '${formatCount(likes)} like${likes == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoGrid extends StatelessWidget {
  final List<VideoFeedItem> videos;
  final VoidCallback? onOpened;
  const VideoGrid({required this.videos, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      // Explicit: an unset padding can add hidden extra space.
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) =>
          VideoResultTile(video: videos[i], onOpened: onOpened),
    );
  }
}

// =============================================================================
// Loading skeleton
// =============================================================================

class SearchSkeleton extends HookWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final t = useAnimation(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    final bar = ProfileTheme.purple.withValues(alpha: 0.07 + 0.08 * t);

    Widget block(double w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 5,
      itemBuilder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ProfileTheme.hairline),
        ),
        child: Row(
          children: [
            block(68, 68, 16),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(150, 16),
                  const Gap(8),
                  block(100, 12),
                  const Gap(8),
                  block(190, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
