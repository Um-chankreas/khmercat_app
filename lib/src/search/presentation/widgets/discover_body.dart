import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

// Rows shown per ranking tab, and trending videos before "See all".
const _rankRows = 5;
const _trendingShown = 6;

/// What the search screen shows before anything is typed: recent searches,
/// a carousel of nearby restaurants (or an enable-location prompt), tabbed
/// rankings and a grid of trending videos.
class DiscoverBody extends HookConsumerWidget {
  final ValueChanged<String> onTapRecent;
  const DiscoverBody({required this.onTapRecent, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(searchViewModelProvider.select((s) => s.recents));
    final position = ref.watch(locationProvider);
    final discover = ref.watch(discoverProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final nearby = discover.valueOrNull?.nearby ?? const <NearbyRestaurant>[];

    return RefreshIndicator(
      color: searchAccent,
      onRefresh: () => ref.refresh(discoverProvider.future),
      child: ListView(
        // Scrolls behind the glass nav bar; the bottom padding clears it.
        padding: EdgeInsets.only(
          top: 8,
          bottom: 28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // ---- Recent searches
          if (recents.isNotEmpty) ...[
            _Inset(
              child: SectionTitle(
                title: 'Recent searches',
                actionText: 'Clear',
                onAction: vm.clearRecents,
              ),
            ),
            const Gap(12),
            _Inset(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final term in recents)
                    _RecentChip(
                      label: term,
                      onTap: () => onTapRecent(term),
                      onRemove: () => vm.removeRecent(term),
                    ),
                ],
              ),
            ),
            const Gap(14),
          ],

          // ---- Nearby
          _Inset(
            child: SectionTitle(
              title: 'Nearby restaurants',
              actionText: nearby.length > 1 ? 'See all' : null,
              onAction: () => _showAllNearby(context, nearby),
            ),
          ),
          const Gap(14),
          if (position == null)
            _Inset(
              child: EnableLocationCard(
                onEnable: () => ref.read(locationProvider.notifier).enable(),
              ),
            )
          else
            discover.when(
              loading: () => const _CardRowSkeleton(),
              error: (_, _) => const _Inset(
                child: _InlineNote('Couldn\'t load nearby places.'),
              ),
              data: (d) => d.nearby.isEmpty
                  ? const _Inset(
                      child: _InlineNote('No restaurants found near you yet.'),
                    )
                  : _NearbyCarousel(items: d.nearby),
            ),
          const Gap(14),

          // ---- Rankings + trending
          ...discover.when(
            loading: () => const [_Inset(child: _ListSkeleton())],
            error: (_, _) => const <Widget>[],
            data: (d) => [
              if (d.popular.isNotEmpty ||
                  d.topRated.isNotEmpty ||
                  d.mostReviewed.isNotEmpty) ...[
                _Rankings(data: d),
                const Gap(14),
              ],
              if (d.trendingVideos.isNotEmpty) ...[
                _Inset(
                  child: SectionTitle(
                    title: 'Trending videos',
                    actionText: d.trendingVideos.length > _trendingShown
                        ? 'See all'
                        : null,
                    onAction: () => _showAllTrending(context, d.trendingVideos),
                  ),
                ),
                const Gap(14),
                _Inset(
                  child: VideoGrid(
                    videos: d.trendingVideos.take(_trendingShown).toList(),
                  ),
                ),
              ],
              if (d.popular.isEmpty &&
                  d.nearby.isEmpty &&
                  d.trendingVideos.isEmpty)
                const _Inset(
                  child: _InlineNote(
                    'Find your next favorite spot — search above or pick a cuisine.',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The page's 20px side margin. Applied per section (not on the ListView)
/// so the nearby carousel can scroll edge to edge.
class _Inset extends StatelessWidget {
  final Widget child;
  const _Inset({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );
}

class _RecentChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _RecentChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 15,
                color: ProfileTheme.textSecondary(context),
              ),
              const Gap(6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
              ),
              const Gap(2),
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: ProfileTheme.muted,
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

class _InlineNote extends StatelessWidget {
  final String text;
  const _InlineNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: ProfileTheme.textSecondary(context),
      ),
    );
  }
}

// =============================================================================
// Nearby
// =============================================================================

/// "Beverage · 2.1 km" — whichever parts exist.
String _nearbyMeta(NearbyRestaurant item) => [
  ?item.restaurant.category?.name,
  if (item.meters != null) formatDistance(item.meters!),
].join(' · ');

class _NearbyCarousel extends StatelessWidget {
  final List<NearbyRestaurant> items;
  const _NearbyCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    // About two-thirds of the screen, so the next card peeks in.
    final width = (MediaQuery.sizeOf(context).width * 0.68).clamp(220.0, 320.0);
    final imageHeight = width * 0.59;
    return SizedBox(
      height: imageHeight + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Gap(14),
        itemBuilder: (context, i) =>
            _NearbyCard(item: items[i], width: width, imageHeight: imageHeight),
      ),
    );
  }
}

/// Photo with rounded corners; name + rating, then category · distance
/// underneath. No card chrome.
class _NearbyCard extends StatelessWidget {
  final NearbyRestaurant item;
  final double width;
  final double imageHeight;
  const _NearbyCard({
    required this.item,
    required this.width,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;
    final meta = _nearbyMeta(item);
    return _Pressable(
      onTap: () => openRestaurant(r.id),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: width,
                height: imageHeight,
                child: NetImage(
                  url: r.coverPicture ?? r.profilePicture,
                  cacheWidth: width,
                ),
              ),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (r.avgRating != null) ...[
                  const Gap(8),
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: ProfileTheme.textPrimary(context),
                  ),
                  const Gap(3),
                  Text(
                    r.avgRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                ],
              ],
            ),
            if (meta.isNotEmpty) ...[
              const Gap(4),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Every nearby restaurant as a list, closest first.
void _showAllNearby(BuildContext context, List<NearbyRestaurant> items) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView.separated(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        itemCount: items.length + 1,
        separatorBuilder: (_, i) => i == 0 ? const Gap(6) : const _RowDivider(),
        itemBuilder: (context, i) {
          if (i == 0) return const SectionTitle(title: 'Nearby restaurants');
          final item = items[i - 1];
          final r = item.restaurant;
          return _RestaurantRow(
            picture: r.profilePicture ?? r.coverPicture,
            name: r.name,
            subtitle: _nearbyMeta(item),
            trailingIcon: r.avgRating == null ? null : Icons.star_rounded,
            trailingText: r.avgRating?.toStringAsFixed(1),
            onTap: () {
              Navigator.pop(sheetContext);
              openRestaurant(r.id);
            },
          );
        },
      ),
    ),
  );
}

/// Every trending video in one scrollable grid.
void _showAllTrending(BuildContext context, List<VideoFeedItem> videos) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const SectionTitle(title: 'Trending videos'),
          const Gap(14),
          VideoGrid(
            videos: videos,
            onOpened: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// Rankings
// =============================================================================

typedef _Ranking = ({
  String label,
  List<RestaurantHighlight> items,
  (IconData, String) Function(RestaurantHighlight) stat,
});

String _plural(int n, String word) =>
    '${formatCount(n)} $word${n == 1 ? '' : 's'}';

/// "Rankings" with Most loved | Top rated | Most reviewed tabs over a
/// numbered list. Tabs with nothing to show are left out.
class _Rankings extends HookWidget {
  final DiscoverData data;
  const _Rankings({required this.data});

  @override
  Widget build(BuildContext context) {
    final rankings = <_Ranking>[
      (
        label: 'Most loved',
        items: data.popular,
        stat: (h) => (Icons.favorite_border_rounded, _plural(h.likes, 'like')),
      ),
      (
        label: 'Top rated',
        items: data.topRated,
        stat: (h) => (Icons.star_rounded, h.avgRating!.toStringAsFixed(1)),
      ),
      (
        label: 'Most reviewed',
        items: data.mostReviewed,
        stat: (h) =>
            (Icons.chat_bubble_outline_rounded, _plural(h.reviews, 'review')),
      ),
    ].where((r) => r.items.isNotEmpty).toList();

    final selected = useState(0);
    final index = selected.value.clamp(0, rankings.length - 1);
    final current = rankings[index];
    final rows = current.items.take(_rankRows).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // A soft white card, slightly see-through so the backdrop tints it.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: isDark ? 0.6 : 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: searchShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Inset(child: SectionTitle(title: 'Rankings')),
          const Gap(10),
          _RankTabs(
            labels: [for (final r in rankings) r.label],
            selected: index,
            onChanged: (i) => selected.value = i,
          ),
          // Height follows the list as tabs change; rows cross-fade.
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: _Inset(
                key: ValueKey(current.label),
                child: Column(
                  children: [
                    for (final (i, h) in rows.indexed) ...[
                      if (i > 0) const _RowDivider(),
                      _RestaurantRow(
                        rank: i + 1,
                        picture: h.picture,
                        name: h.name,
                        subtitle: [
                          if (h.avgRating != null)
                            '${h.avgRating!.toStringAsFixed(1)} rating',
                          if (h.reviews > 0) _plural(h.reviews, 'review'),
                          if (h.avgRating == null && h.reviews == 0)
                            _plural(h.videos, 'video'),
                        ].join(' · '),
                        trailingIcon: current.stat(h).$1,
                        trailingText: current.stat(h).$2,
                        onTap: () => openRestaurant(h.id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text tabs on a hairline, with a dark underline under the selected one.
class _RankTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _RankTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final line = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    // Full width, so the hairline runs edge to edge of the section.
    return SizedBox(
      width: double.infinity,
      child: _Inset(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Hairline across the full width, under the tabs' own underline.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColoredBox(color: line, child: const SizedBox(height: 1)),
            ),
            // Scrolls sideways rather than overflowing on narrow phones or
            // with large system text.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, label) in labels.indexed) ...[
                    if (i > 0) const Gap(22),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i == selected) return;
                        HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2,
                              color: i == selected
                                  ? primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: i == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == selected
                                ? primary
                                : ProfileTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
  );
}

/// [rank] · square photo · name over a grey line · icon + stat on the right.
class _RestaurantRow extends StatelessWidget {
  final int? rank;
  final String? picture;
  final String name;
  final String subtitle;
  final IconData? trailingIcon;
  final String? trailingText;
  final VoidCallback onTap;
  const _RestaurantRow({
    required this.picture,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.rank,
    this.trailingIcon,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return _Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (rank != null) ...[
              // #1 sits in a solid dark circle; the rest are plain numbers.
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1 ? primary : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: rank == 1
                        ? Theme.of(context).colorScheme.surface
                        : muted,
                  ),
                ),
              ),
              const Gap(14),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: NetImage(url: picture, cacheWidth: 56),
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: primary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const Gap(3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const Gap(10),
              if (trailingIcon != null) ...[
                Icon(trailingIcon, size: 16, color: primary),
                const Gap(5),
              ],
              Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dims slightly while pressed — tap feedback without a card or ripple.
class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedOpacity(
        opacity: _down ? 0.6 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// Loading placeholders
// =============================================================================

Color _skeleton(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);

class _CardRowSkeleton extends StatelessWidget {
  const _CardRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.68).clamp(220.0, 320.0);
    return SizedBox(
      height: width * 0.59 + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (_, _) => const Gap(14),
        itemBuilder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width,
            height: width * 0.59,
            decoration: BoxDecoration(
              color: _skeleton(context),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _skeleton(context),
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(110, 22),
        const Gap(22),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                box(52, 52, 10),
                const Gap(14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [box(140, 14), const Gap(8), box(96, 12)],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
