import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

const _amber = Color(0xffFFB800);
const _amberPink = LinearGradient(colors: [_amber, ProfileTheme.pink]);

/// What the search screen shows before anything is typed: recent searches,
/// nearby restaurants (or an enable-location prompt), and recommendations.
class DiscoverBody extends ConsumerWidget {
  final ValueChanged<String> onTapRecent;
  const DiscoverBody({required this.onTapRecent, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(searchViewModelProvider.select((s) => s.recents));
    final position = ref.watch(locationProvider);
    final discover = ref.watch(discoverProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

    return RefreshIndicator(
      color: ProfileTheme.purple,
      onRefresh: () => ref.refresh(discoverProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // ---- Recent searches
          if (recents.isNotEmpty) ...[
            SectionTitle(
              icon: Icons.history_rounded,
              gradient: ProfileTheme.purpleBlue,
              title: 'Recent searches',
              actionText: 'Clear',
              onAction: vm.clearRecents,
            ),
            const Gap(12),
            Wrap(
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
            const Gap(28),
          ],

          // ---- Nearby
          const SectionTitle(
            icon: Icons.near_me_rounded,
            gradient: ProfileTheme.pinkPurple,
            title: 'Nearby restaurants',
            subtitle: 'Closest to you first',
          ),
          const Gap(14),
          if (position == null)
            EnableLocationCard(
              onEnable: () => ref.read(locationProvider.notifier).enable(),
            )
          else
            discover.when(
              loading: () => const _CardRowSkeleton(),
              error: (_, _) =>
                  const _InlineNote('Couldn\'t load nearby places.'),
              data: (d) => d.nearby.isEmpty
                  ? const _InlineNote('No restaurants found near you yet.')
                  : SizedBox(
                      height: 198,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: d.nearby.length,
                        separatorBuilder: (_, _) => const Gap(12),
                        itemBuilder: (context, i) =>
                            _NearbyCard(item: d.nearby[i]),
                      ),
                    ),
            ),
          const Gap(28),

          // ---- Recommendations
          ...discover.when(
            loading: () => const [_CardRowSkeleton()],
            error: (_, _) => const <Widget>[],
            data: (d) => [
              if (d.popular.isNotEmpty)
                _HighlightSection(
                  icon: Icons.local_fire_department_rounded,
                  gradient: ProfileTheme.pinkPurple,
                  title: 'Popular right now',
                  subtitle: 'Most loved by the community',
                  items: d.popular,
                  statBuilder: (h) =>
                      (Icons.favorite_rounded, '${h.likes} likes'),
                ),
              if (d.topRated.isNotEmpty)
                _HighlightSection(
                  icon: Icons.star_rounded,
                  gradient: _amberPink,
                  title: 'Top rated',
                  subtitle: 'Best average review score',
                  items: d.topRated,
                  statBuilder: (h) =>
                      (Icons.star_rounded, h.avgRating!.toStringAsFixed(1)),
                ),
              if (d.mostReviewed.isNotEmpty)
                _HighlightSection(
                  icon: Icons.rate_review_rounded,
                  gradient: ProfileTheme.purpleBlue,
                  title: 'Most reviewed',
                  subtitle: 'Where people share the most',
                  items: d.mostReviewed,
                  statBuilder: (h) => (
                    Icons.rate_review_rounded,
                    '${h.reviews} review${h.reviews == 1 ? '' : 's'}',
                  ),
                ),
              if (d.trendingVideos.isNotEmpty) ...[
                const SectionTitle(
                  icon: Icons.trending_up_rounded,
                  gradient: ProfileTheme.pinkBlueGradient,
                  title: 'Trending videos',
                  subtitle: 'What everyone is watching',
                ),
                const Gap(14),
                VideoGrid(videos: d.trendingVideos),
              ],
              if (d.popular.isEmpty &&
                  d.nearby.isEmpty &&
                  d.trendingVideos.isEmpty)
                const SearchMessage(
                  icon: Icons.search_rounded,
                  title: 'Find your next favorite spot',
                  message:
                      'Search for a restaurant, a dish or a person — or pick a cuisine above.',
                ),
            ],
          ),
        ],
      ),
    );
  }
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
      color: ProfileTheme.purple.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ProfileTheme.purple.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 15,
                color: ProfileTheme.deepPurple,
              ),
              const Gap(6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.deepPurple,
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
    return ProfileCard(
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: ProfileTheme.muted),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final NearbyRestaurant item;
  const _NearbyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;
    return SizedBox(
      width: 176,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ProfileTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openRestaurant(r.id),
          splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(url: r.coverPicture ?? r.profilePicture),
                    if (item.meters != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: ProfileTheme.pinkPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const Gap(4),
                              Text(
                                formatDistance(item.meters!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (r.category != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
                  child: Text(
                    r.category!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
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

class _HighlightSection extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final List<RestaurantHighlight> items;
  final (IconData, String) Function(RestaurantHighlight) statBuilder;

  const _HighlightSection({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.statBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: icon,
            gradient: gradient,
            title: title,
            subtitle: subtitle,
          ),
          const Gap(14),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Gap(12),
              itemBuilder: (context, i) {
                final h = items[i];
                final (statIcon, statText) = statBuilder(h);
                return _HighlightCard(
                  highlight: h,
                  statIcon: statIcon,
                  statText: statText,
                  rank: i + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final RestaurantHighlight highlight;
  final IconData statIcon;
  final String statText;
  final int rank;
  const _HighlightCard({
    required this.highlight,
    required this.statIcon,
    required this.statText,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ProfileTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openRestaurant(highlight.id),
          splashColor: ProfileTheme.purple.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(url: highlight.picture),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: ProfileTheme.pinkPurple,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
                child: Text(
                  highlight.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                child: Row(
                  children: [
                    Icon(
                      statIcon,
                      size: 14,
                      color: statIcon == Icons.star_rounded
                          ? _amber
                          : ProfileTheme.pink,
                    ),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        statText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _CardRowSkeleton extends StatelessWidget {
  const _CardRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const Gap(12),
        itemBuilder: (_, _) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: ProfileTheme.purple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
