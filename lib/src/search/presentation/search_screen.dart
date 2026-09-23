import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/discover_body.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

const _restaurantPage = 10;
const _videoPage = 12;
const _userPage = 10;

// Items each section shows on the "All" tab before "See all".
const _allRestaurants = 3;
const _allVideos = 6;
const _allUsers = 3;

/// A restaurant plus its distance from the device (when both are known).
typedef _Result = ({Restaurant restaurant, double? meters});

/// Layout, top to bottom: sticky search bar → cuisine / sort chips → (once
/// searching) All | Restaurants | Videos | Users tabs → the body, which is
/// discovery content (recent, nearby, recommended) until something is typed
/// or a cuisine is picked, then the organised results.
class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final position = ref.watch(locationProvider);

    final inputCtr = useTextEditingController();
    final focus = useFocusNode();
    useListenable(inputCtr);
    useListenable(focus);
    final tab = useState(0);
    final nearest = useState(false);

    // Cuisine filter is client-side (the API has no filter params): keep only
    // restaurants whose category matches, then optionally sort by distance.
    var results = <_Result>[
      for (final r in state.restaurants)
        if (state.cuisine == null || r.category?.name == state.cuisine)
          (restaurant: r, meters: distanceTo(position, r)),
    ];
    if (nearest.value) {
      results = [...results]
        ..sort(
          (a, b) => (a.meters ?? double.infinity).compareTo(
            b.meters ?? double.infinity,
          ),
        );
    }

    void enableLocation() => ref.read(locationProvider.notifier).enable();

    void runTerm(String term) {
      inputCtr.text = term;
      inputCtr.selection = TextSelection.collapsed(offset: term.length);
      vm.submit(term);
    }

    final pills = <FilterPill>[
      FilterPill(
        label: 'Nearest',
        icon: Icons.near_me_rounded,
        selected: nearest.value,
        divider: true,
        onTap: () {
          if (position == null) {
            enableLocation();
            return;
          }
          nearest.value = !nearest.value;
        },
      ),
      FilterPill(
        label: 'All',
        selected: state.cuisine == null,
        onTap: () => vm.setCuisine(null),
      ),
      for (final c in cuisineOptions)
        FilterPill(
          label: c,
          selected: state.cuisine == c,
          onTap: () => vm.setCuisine(state.cuisine == c ? null : c),
        ),
    ];

    Widget body;
    if (!state.hasSearched) {
      body = DiscoverBody(onTapRecent: runTerm);
    } else if (state.isLoading) {
      body = const SearchSkeleton();
    } else if (state.errorMessage != null) {
      body = SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: state.errorMessage!,
        action: GradientTextButton(
          text: 'Try again',
          icon: Icons.refresh_rounded,
          onTap: () => vm.submit(state.query),
        ),
      );
    } else if (results.isEmpty && state.videos.isEmpty && state.users.isEmpty) {
      body = SearchMessage(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        message: state.cuisine != null
            ? 'We couldn\'t find anything for "${state.query}" in ${state.cuisine}.'
            : 'We couldn\'t find anything for "${state.query}".',
        tips: [
          'Check the spelling',
          'Try fewer or different words',
          if (state.cuisine != null) 'Clear the cuisine filter',
        ],
        suggestionsLabel: 'Browse by cuisine',
        suggestions: cuisineOptions
            .where((c) => c != state.cuisine)
            .take(4)
            .toList(),
        onSuggestion: (c) {
          inputCtr.clear();
          vm.onQueryChanged('');
          vm.setCuisine(c);
        },
        action: state.cuisine != null
            ? GradientTextButton(
                text: 'Clear filter',
                icon: Icons.filter_alt_off_rounded,
                onTap: () => vm.setCuisine(null),
              )
            : null,
      );
    } else {
      body = KeyedSubtree(
        key: ValueKey(
          '${state.query}|${state.cuisine}|${nearest.value}|${tab.value}',
        ),
        child: switch (tab.value) {
          1 => _RestaurantsTab(results: results, onOpened: vm.commitSearch),
          2 => _VideosTab(state: state, onOpened: vm.commitSearch),
          3 => _UsersTab(state: state, onOpened: vm.commitSearch),
          _ => _AllTab(
            results: results,
            state: state,
            onSeeAll: (t) => tab.value = t,
            onOpened: vm.commitSearch,
          ),
        },
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ---- Sticky header: search bar, filter chips, tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SearchInputBar(
              controller: inputCtr,
              focusNode: focus,
              isLoading: state.isLoading,
              onChanged: vm.onQueryChanged,
              onSubmitted: vm.submit,
              onClear: () {
                inputCtr.clear();
                vm.onQueryChanged('');
              },
            ),
          ),
          FilterChipsRow(pills: pills),
          const Gap(10),
          if (state.hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchTabs(
                labels: [
                  'All',
                  'Restaurants ${results.length}',
                  'Videos ${state.videos.length}',
                  'Users ${state.users.length}',
                ],
                selected: tab.value,
                onChanged: (i) => tab.value = i,
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

String? _distanceText(double? meters) =>
    meters == null ? null : formatDistance(meters);

class _AllTab extends StatelessWidget {
  final List<_Result> results;
  final SearchState state;
  final ValueChanged<int> onSeeAll;
  final VoidCallback onOpened;
  const _AllTab({
    required this.results,
    required this.state,
    required this.onSeeAll,
    required this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        if (results.isNotEmpty) ...[
          SectionTitle(
            icon: Icons.storefront_rounded,
            gradient: ProfileTheme.pinkPurple,
            title: 'Restaurants',
            actionText: results.length > _allRestaurants ? 'See all' : null,
            onAction: () => onSeeAll(1),
          ),
          const Gap(14),
          for (final r in results.take(_allRestaurants))
            RestaurantResultCard(
              restaurant: r.restaurant,
              distanceText: _distanceText(r.meters),
              onOpened: onOpened,
            ),
          const Gap(16),
        ],
        if (state.videos.isNotEmpty) ...[
          SectionTitle(
            icon: Icons.play_circle_rounded,
            gradient: ProfileTheme.purpleBlue,
            title: 'Videos',
            actionText: state.videos.length > _allVideos ? 'See all' : null,
            onAction: () => onSeeAll(2),
          ),
          const Gap(12),
          VideoGrid(
            videos: state.videos.take(_allVideos).toList(),
            onOpened: onOpened,
          ),
          const Gap(28),
        ],
        if (state.users.isNotEmpty) ...[
          SectionTitle(
            icon: Icons.people_alt_rounded,
            gradient: ProfileTheme.pinkBlueGradient,
            title: 'Users',
            actionText: state.users.length > _allUsers ? 'See all' : null,
            onAction: () => onSeeAll(3),
          ),
          const Gap(12),
          for (final u in state.users.take(_allUsers))
            UserResultTile(user: u, onOpened: onOpened),
        ],
      ],
    );
  }
}

class _RestaurantsTab extends HookWidget {
  final List<_Result> results;
  final VoidCallback onOpened;
  const _RestaurantsTab({required this.results, required this.onOpened});

  @override
  Widget build(BuildContext context) {
    final shown = useState(_restaurantPage);
    final grid = useState(false);
    if (results.isEmpty) {
      return const SearchMessage(
        icon: Icons.storefront_outlined,
        title: 'No restaurants',
        message: 'No restaurants match your search.',
      );
    }
    final visible = results.take(shown.value).toList();
    final hasMore = results.length > visible.length;

    // Infinite scroll: the sentinel is the last (lazily built) child, so it
    // only appears — and asks for more — when the user nears the end.
    final sentinel = hasMore
        ? LoadMoreSentinel(
            key: ValueKey(visible.length),
            onVisible: () => shown.value += _restaurantPage,
          )
        : const Gap(8);

    Widget header() => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${results.length} restaurant${results.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.muted,
              ),
            ),
          ),
          ViewToggle(grid: grid.value, onChanged: (g) => grid.value = g),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        header(),
        if (grid.value)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) => RestaurantGridCard(
              restaurant: visible[i].restaurant,
              distanceText: _distanceText(visible[i].meters),
              onOpened: onOpened,
            ),
          )
        else
          for (final r in visible)
            RestaurantResultCard(
              restaurant: r.restaurant,
              distanceText: _distanceText(r.meters),
              onOpened: onOpened,
            ),
        sentinel,
      ],
    );
  }
}

class _VideosTab extends HookWidget {
  final SearchState state;
  final VoidCallback onOpened;
  const _VideosTab({required this.state, required this.onOpened});

  @override
  Widget build(BuildContext context) {
    final shown = useState(_videoPage);
    if (state.videos.isEmpty) {
      return const SearchMessage(
        icon: Icons.videocam_off_rounded,
        title: 'No videos',
        message: 'No videos match your search.',
      );
    }
    final visible = state.videos.take(shown.value).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        VideoGrid(videos: visible, onOpened: onOpened),
        if (state.videos.length > visible.length)
          LoadMoreSentinel(
            key: ValueKey(visible.length),
            onVisible: () => shown.value += _videoPage,
          )
        else
          const Gap(8),
      ],
    );
  }
}

class _UsersTab extends HookWidget {
  final SearchState state;
  final VoidCallback onOpened;
  const _UsersTab({required this.state, required this.onOpened});

  @override
  Widget build(BuildContext context) {
    final shown = useState(_userPage);
    if (state.users.isEmpty) {
      return const SearchMessage(
        icon: Icons.person_search_rounded,
        title: 'No people found',
        message: 'No users match your search.',
      );
    }
    final visible = state.users.take(shown.value).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        for (final u in visible) UserResultTile(user: u, onOpened: onOpened),
        if (state.users.length > visible.length)
          LoadMoreSentinel(
            key: ValueKey(visible.length),
            onVisible: () => shown.value += _userPage,
          )
        else
          const Gap(8),
      ],
    );
  }
}
