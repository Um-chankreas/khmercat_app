import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';

// =============================================================================
// Search bar + filter chips + tabs (the sticky header)
// =============================================================================

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: focused
              ? ProfileTheme.purple
              : ProfileTheme.purple.withValues(alpha: 0.14),
          width: focused ? 1.8 : 1.2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: ProfileTheme.purple.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : ProfileTheme.cardShadow(),
      ),
      child: Row(
        children: [
          const Gap(8),
          // Gradient badge behind the search icon.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: ProfileTheme.gradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const Gap(4),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search restaurants, dishes or people',
                hintStyle: TextStyle(
                  fontSize: 15.5,
                  color: ProfileTheme.muted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: ProfileTheme.purple,
                ),
              ),
            )
          else if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: ProfileTheme.muted),
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: selected ? ProfileTheme.pinkPurple : null,
            color: selected ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : ProfileTheme.purple.withValues(alpha: 0.2),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ProfileTheme.purple.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pill.icon != null) ...[
                Icon(
                  pill.icon,
                  size: 17,
                  color: selected ? Colors.white : ProfileTheme.deepPurple,
                ),
                const Gap(6),
              ],
              Text(
                pill.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : ProfileTheme.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All | Restaurants | Videos | Users with a sliding gradient underline.
class SearchTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const SearchTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return SizedBox(
      height: 42,
      child: Stack(
        children: [
          Row(
            children: List.generate(n, (i) {
              final active = i == selected;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active
                            ? ProfileTheme.deepPurple
                            : ProfileTheme.muted,
                      ),
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: ProfileTheme.hairline),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * selected / (n - 1), 1),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              child: Center(
                child: Container(
                  width: 34,
                  height: 3.5,
                  decoration: BoxDecoration(
                    gradient: ProfileTheme.gradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
// Section chrome
// =============================================================================

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionTitle({
    required this.icon,
    required this.gradient,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ProfileTheme.muted,
                  ),
                ),
            ],
          ),
        ),
        if (actionText != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ProfileTheme.deepPurple,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ProfileTheme.deepPurple,
                  ),
                ],
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
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
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

/// "Show more" button for the client-side paging of long result lists.
/// Infinite-scroll trigger: placed as the last child of a lazily-built list,
/// it only gets built once the user scrolls near the end, and then asks for
/// the next page. Re-key it (e.g. by item count) so it fires again per page.
class LoadMoreSentinel extends StatefulWidget {
  final VoidCallback onVisible;
  const LoadMoreSentinel({required this.onVisible, super.key});

  @override
  State<LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<LoadMoreSentinel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: ProfileTheme.purple,
          ),
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
  const NetImage({
    required this.url,
    this.fallback = Icons.storefront_rounded,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
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

class RestaurantResultCard extends StatelessWidget {
  final Restaurant restaurant;
  final String? distanceText;
  final VoidCallback? onOpened;
  const RestaurantResultCard({
    required this.restaurant,
    this.distanceText,
    this.onOpened,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final category = r.category?.name;
    final address = r.address?.trim();
    final followers = r.followersCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: ProfileTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(boxShadow: ProfileTheme.cardShadow()),
          child: InkWell(
            onTap: () {
              onOpened?.call();
              openRestaurant(r.id);
            },
            splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
            highlightColor: ProfileTheme.purple.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: NetImage(url: r.profilePicture),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (category != null && category.isNotEmpty) ...[
                          const Gap(3),
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ProfileTheme.deepPurple,
                            ),
                          ),
                        ],
                        const Gap(7),
                        // Quiet meta row: icon + text, no chip backgrounds.
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (distanceText != null)
                              _Meta(
                                icon: Icons.near_me_rounded,
                                text: distanceText!,
                                color: ProfileTheme.pink,
                              ),
                            if (followers != null)
                              _Meta(
                                icon: Icons.people_alt_rounded,
                                text: '$followers',
                                color: ProfileTheme.blue,
                              ),
                            if (address != null && address.isNotEmpty)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 170,
                                ),
                                child: _Meta(
                                  icon: Icons.location_on_rounded,
                                  text: address,
                                  color: ProfileTheme.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: ProfileTheme.purple.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: ProfileTheme.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + short text, used for the quiet metadata rows.
class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Meta({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ProfileTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Two-column variant of the restaurant card for the grid layout.
class RestaurantGridCard extends StatelessWidget {
  final Restaurant restaurant;
  final String? distanceText;
  final VoidCallback? onOpened;
  const RestaurantGridCard({
    required this.restaurant,
    this.distanceText,
    this.onOpened,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: ProfileTheme.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(boxShadow: ProfileTheme.cardShadow()),
        child: InkWell(
          onTap: () {
            onOpened?.call();
            openRestaurant(r.id);
          },
          splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(url: r.coverPicture ?? r.profilePicture),
                      if (distanceText != null)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: ProfileTheme.pinkPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  distanceText!,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (r.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.category!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ProfileTheme.deepPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small chip-style badge, used on user tiles.
class _MiniChip extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  const _MiniChip({this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color == ProfileTheme.purple
                  ? ProfileTheme.deepPurple
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}

class UserResultTile extends StatelessWidget {
  final PublicProfile user;
  final VoidCallback? onOpened;
  const UserResultTile({required this.user, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: ProfileTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            onOpened?.call();
            AppRouter.router.pushNamed(
              AppRoute.userProfile.name,
              pathParameters: {'username': user.username},
            );
          },
          splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: ProfileTheme.gradient,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ImageUserCircleProfile(
                      imageUrl: user.profilePicture,
                      name: user.name,
                      size: 48,
                    ),
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ProfileTheme.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.followersCount != null)
                  _MiniChip(
                    icon: Icons.people_alt_rounded,
                    text: '${user.followersCount}',
                    color: ProfileTheme.blue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoResultTile extends StatelessWidget {
  final VideoFeedItem video;
  final VoidCallback? onOpened;
  const VideoResultTile({required this.video, this.onOpened, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onOpened?.call();
        AppRouter.router.pushNamed(
          AppRoute.videoViewer.name,
          pathParameters: {'id': video.id},
          extra: video,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: ProfileTheme.cardShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(
                url: video.thumbnailUrl,
                fallback: Icons.play_circle_outline_rounded,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 6,
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const Gap(4),
                    Text(
                      formatCount(video.likesCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
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
