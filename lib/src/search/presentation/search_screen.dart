import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/discover_body.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_result_cards.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';

// Items each section shows on the "All" tab before "See all".
const _allRestaurants = 3;
const _allVideos = 4;
const _allUsers = 3;

/// Layout, top to bottom: sticky search bar → Nearest / cuisine chips →
/// (once searching) All | Restaurants | Users tabs → the body, which
/// is discovery content (recent, nearby, recommended) until something is
/// typed or a cuisine is picked, then the results.
///
/// The cuisine chip and "Nearest" are sent to the API (`category_id`,
/// `sort=nearest`), so result counts and ordering come from the server.
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

    void runTerm(String term) {
      inputCtr.text = term;
      inputCtr.selection = TextSelection.collapsed(offset: term.length);
      vm.submit(term);
    }

    Future<void> toggleFollow(PublicProfile user) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow people',
      )) {
        return;
      }
      vm.toggleFollowUser(user);
    }

    final pills = <FilterPill>[
      FilterPill(
        label: 'All',
        selected: state.cuisine == null,
        onTap: () => vm.setCuisine(null),
      ),
      FilterPill(
        label: 'Nearest',
        icon: Icons.location_on_outlined,
        selected: state.nearest && position != null,
        onTap: () {
          if (position == null) {
            ref.read(locationProvider.notifier).enable();
            return;
          }
          vm.setNearest(!state.nearest);
        },
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
    } else if (state.isLoading && state.isEmpty) {
      body = const SearchSkeleton();
    } else if (state.errorMessage != null) {
      body = SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: state.errorMessage!,
        action: GradientTextButton(
          text: 'Try again',
          icon: Icons.refresh_rounded,
          onTap: vm.retry,
        ),
      );
    } else if (state.isEmpty && !state.isLoading) {
      body = SearchMessage(
        imageAsset: AssetsName.appLogoTrsm,
        title: 'No results for "${state.query}"',
        message: state.cuisine != null
            ? 'Check the spelling, try other words, or clear the cuisine '
                  'filter.'
            : 'Check the spelling or try other words.',
        suggestionsLabel: 'Browse by cuisine',
        suggestions: cuisineOptions.where((c) => c != state.cuisine).toList(),
        onSuggestion: (c) {
          inputCtr.clear();
          vm.onQueryChanged('');
          vm.setCuisine(c);
        },
        action: state.cuisine != null
            ? GradientTextButton(
                text: 'Clear filter',
                icon: Icons.close_rounded,
                onTap: () => vm.setCuisine(null),
              )
            : null,
      );
    } else {
      final currentUserId = ref.watch(authControllerProvider).user?.id;
      body = KeyedSubtree(
        key: ValueKey('${state.query}|${state.cuisine}|${tab.value}'),
        child: switch (tab.value) {
          1 => _RestaurantsTab(state: state, onOpened: vm.commitSearch),
          2 => _UsersTab(
            state: state,
            onOpened: vm.commitSearch,
            onToggleFollow: toggleFollow,
            currentUserId: currentUserId,
          ),
          _ => _AllTab(
            state: state,
            onSeeAll: (t) => tab.value = t,
            onOpened: vm.commitSearch,
            onToggleFollow: toggleFollow,
            currentUserId: currentUserId,
          ),
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Black status-bar icons over the light backdrop (white in dark mode).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Stack(
        children: [
          // The backdrop runs behind the glass nav bar; the content stops
          // above it.
          const Positioned.fill(child: SearchBackdrop()),
          // No bottom inset here: the lists scroll behind the glass nav
          // bar and pad their own content to clear it.
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ---- Sticky header: search bar, filter chips, tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
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
                      const Gap(10),
                      SearchActionButton(
                        icon: Icons.map_outlined,
                        tooltip: 'Map',
                        onTap: () => AppRouter.router.pushNamed(
                          AppRoute.restaurantMap.name,
                        ),
                      ),
                    ],
                  ),
                ),
                FilterChipsRow(pills: pills),

                if (state.hasSearched)
                  SearchTabs(
                    tabs: [
                      (label: 'All', count: null),
                      (label: 'Restaurants', count: state.restaurantsTotal),
                      (label: 'Users', count: state.usersTotal),
                    ],
                    selected: tab.value,
                    onChanged: (i) => tab.value = i,
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    // The default builder keys each transition by its child's key,
                    // so switching quickly (e.g. a filter tap: results -> loading ->
                    // results) can put two same-keyed children — like two unkeyed
                    // skeletons — in the switcher's Stack at once, which throws
                    // "Duplicate keys found". Unkeyed here, AnimatedSwitcher falls
                    // back to its own per-transition counter, always unique.
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllTab extends StatelessWidget {
  final SearchState state;
  final ValueChanged<int> onSeeAll;
  final VoidCallback onOpened;
  final ValueChanged<PublicProfile> onToggleFollow;
  final String? currentUserId;
  const _AllTab({
    required this.state,
    required this.onSeeAll,
    required this.onOpened,
    required this.onToggleFollow,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final nearby = state.restaurants.take(_allRestaurants).toList();
    // Don't repeat restaurants already listed right above.
    final shownIds = {for (final r in nearby) r.id};
    final recommended = state.recommended
        .where((r) => !shownIds.contains(r.id))
        .toList();
    final hasDistances = nearby.any((r) => r.distanceKm != null);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        18,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (nearby.isNotEmpty) ...[
          SearchSectionHeader(
            title: hasDistances ? 'Nearby restaurants' : 'Restaurants',
            actionText: state.restaurantsTotal > nearby.length
                ? 'See all (${state.restaurantsTotal})'
                : null,
            onAction: () => onSeeAll(1),
          ),
          for (final r in nearby)
            NearbyRestaurantCard(restaurant: r, onOpened: onOpened),
          const Gap(14),
        ],
        if (recommended.isNotEmpty) ...[
          SearchSectionHeader(
            title: 'Recommended restaurants',
            trailingLabel: recommended.any((r) => r.isSponsored)
                ? 'Sponsored'
                : null,
          ),
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Explicit: an unset padding can add hidden extra space.
              padding: EdgeInsets.zero,
              clipBehavior: Clip.none,
              itemCount: recommended.length,
              separatorBuilder: (_, _) => const Gap(12),
              itemBuilder: (context, i) => RecommendedRestaurantCard(
                restaurant: recommended[i],
                onOpened: onOpened,
              ),
            ),
          ),
          const Gap(14),
        ],
        if (state.videos.isNotEmpty) ...[
          SearchSectionHeader(title: 'Food reviews & videos'),
          VideoReviewGrid(
            videos: state.videos.take(_allVideos).toList(),
            onOpened: onOpened,
          ),
          const Gap(14),
        ],
        if (state.users.isNotEmpty) ...[
          SearchSectionHeader(
            title: 'Popular reviewers',
            actionText: state.usersTotal > _allUsers ? 'See all' : null,
            onAction: () => onSeeAll(2),
          ),
          ReviewerList(
            users: state.users.take(_allUsers).toList(),
            onToggleFollow: onToggleFollow,
            onOpened: onOpened,
            currentUserId: currentUserId,
          ),
        ],
      ],
    );
  }
}

class _RestaurantsTab extends HookWidget {
  final SearchState state;
  final VoidCallback onOpened;
  const _RestaurantsTab({required this.state, required this.onOpened});

  @override
  Widget build(BuildContext context) {
    final grid = useState(false);
    final results = state.restaurants;
    if (results.isEmpty) {
      return const SearchMessage(
        icon: Icons.storefront_outlined,
        title: 'No restaurants',
        message: 'No restaurants match your search.',
      );
    }
    final total = state.restaurantsTotal;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  total > results.length
                      ? 'Top ${results.length} of $total restaurants'
                      : '$total restaurant${total == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.textSecondary(context),
                  ),
                ),
              ),
              ViewToggle(grid: grid.value, onChanged: (g) => grid.value = g),
            ],
          ),
        ),
        if (grid.value)
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: results.length,
            itemBuilder: (context, i) => RecommendedRestaurantCard(
              restaurant: results[i],
              onOpened: onOpened,
              width: null,
            ),
          )
        else
          for (final r in results)
            NearbyRestaurantCard(restaurant: r, onOpened: onOpened),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  final SearchState state;
  final VoidCallback onOpened;
  final ValueChanged<PublicProfile> onToggleFollow;
  final String? currentUserId;
  const _UsersTab({
    required this.state,
    required this.onOpened,
    required this.onToggleFollow,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (state.users.isEmpty) {
      return const SearchMessage(
        icon: Icons.person_search_rounded,
        title: 'No people found',
        message: 'No users match your search.',
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        ReviewerList(
          users: state.users,
          onToggleFollow: onToggleFollow,
          onOpened: onOpened,
          currentUserId: currentUserId,
        ),
      ],
    );
  }
}
