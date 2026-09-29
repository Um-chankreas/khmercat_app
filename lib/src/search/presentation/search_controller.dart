import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/cuisine_category_selector.dart';
import 'package:khmer_cat_app/src/search/providers/search_providers.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentsKey = 'recent_searches';
const _maxRecents = 8;

class SearchState {
  /// What the results are for: the typed text, or the cuisine label when a
  /// cuisine chip is picked with an empty box. Empty = nothing searched yet.
  final String query;
  final List<Restaurant> restaurants;
  final List<Restaurant> recommended;
  final List<VideoFeedItem> videos;
  final List<PublicProfile> users;

  /// Total matches per section from the API (may exceed the list lengths).
  final int restaurantsTotal;
  final int videosTotal;
  final int usersTotal;
  final bool isLoading;
  final String? errorMessage;

  /// Selected cuisine chip (a restaurant category name), or null for "All".
  final String? cuisine;

  /// "Nearest" chip: the API sorts restaurants by distance.
  final bool nearest;
  final List<String> recents;

  const SearchState({
    this.query = '',
    this.restaurants = const [],
    this.recommended = const [],
    this.videos = const [],
    this.users = const [],
    this.restaurantsTotal = 0,
    this.videosTotal = 0,
    this.usersTotal = 0,
    this.isLoading = false,
    this.errorMessage,
    this.cuisine,
    this.nearest = false,
    this.recents = const [],
  });

  bool get hasSearched => query.isNotEmpty;

  bool get isEmpty => restaurants.isEmpty && videos.isEmpty && users.isEmpty;

  SearchState copyWith({
    String? query,
    List<Restaurant>? restaurants,
    List<Restaurant>? recommended,
    List<VideoFeedItem>? videos,
    List<PublicProfile>? users,
    int? restaurantsTotal,
    int? videosTotal,
    int? usersTotal,
    bool? isLoading,
    String? errorMessage,
    String? cuisine,
    bool clearCuisine = false,
    bool? nearest,
    List<String>? recents,
  }) {
    return SearchState(
      query: query ?? this.query,
      restaurants: restaurants ?? this.restaurants,
      recommended: recommended ?? this.recommended,
      videos: videos ?? this.videos,
      users: users ?? this.users,
      restaurantsTotal: restaurantsTotal ?? this.restaurantsTotal,
      videosTotal: videosTotal ?? this.videosTotal,
      usersTotal: usersTotal ?? this.usersTotal,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cuisine: clearCuisine ? null : (cuisine ?? this.cuisine),
      nearest: nearest ?? this.nearest,
      recents: recents ?? this.recents,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  Timer? _debounce;

  /// What's currently in the text box (as opposed to [SearchState.query],
  /// which can be a cuisine label).
  String _typed = '';

  /// Bumped per request so a slow, older response can't overwrite a newer one.
  int _seq = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    // Location arriving after a search: refetch so distances show up.
    ref.listen(locationProvider, (prev, next) {
      if (prev == null && next != null && state.hasSearched) _run();
    });
    Future.microtask(_loadRecents);
    return const SearchState();
  }

  // ---- input ------------------------------------------------------------

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _typed = query.trim();
    if (_typed.isEmpty) {
      // A cuisine chip is still selected: fall back to searching by it.
      state.cuisine != null ? _run() : _resetResults();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  /// Runs [term] immediately (keyboard "search", or tapping a recent search)
  /// and remembers it.
  void submit(String term) {
    _debounce?.cancel();
    _typed = term.trim();
    if (_typed.isEmpty) return;
    _run();
    _remember(_typed);
  }

  /// Re-runs the current search (e.g. "Try again").
  void retry() {
    if (state.hasSearched) _run();
  }

  /// Remembers the current typed query — called when the user opens a result,
  /// which is the signal that the search was actually useful.
  void commitSearch() {
    if (_typed.isNotEmpty) _remember(_typed);
  }

  void setCuisine(String? cuisine) {
    if (cuisine == state.cuisine) return;
    state = cuisine == null
        ? state.copyWith(clearCuisine: true)
        : state.copyWith(cuisine: cuisine);
    if (_typed.isEmpty && cuisine == null) {
      _resetResults();
    } else {
      _run();
    }
  }

  void setNearest(bool nearest) {
    if (nearest == state.nearest) return;
    state = state.copyWith(nearest: nearest);
    if (state.hasSearched) _run();
  }

  void _resetResults() {
    _debounce?.cancel();
    _seq++;
    state = SearchState(
      cuisine: state.cuisine,
      nearest: state.nearest,
      recents: state.recents,
    );
  }

  Future<void> _run() async {
    final seq = ++_seq;
    final cuisine = state.cuisine;
    final typed = _typed;
    final position = ref.read(locationProvider);
    state = state.copyWith(
      query: typed.isNotEmpty ? typed : cuisine,
      isLoading: true,
    );
    try {
      final r = await ref
          .read(searchRepositoryProvider)
          .search(
            query: typed,
            categoryId: cuisine == null ? null : cuisineCategoryIds[cuisine],
            lat: position?.latitude,
            lng: position?.longitude,
            nearest: state.nearest,
          );
      if (seq != _seq) return;
      state = state.copyWith(
        restaurants: r.restaurants,
        recommended: r.recommended,
        videos: r.videos,
        users: r.users,
        restaurantsTotal: r.counts.restaurants,
        videosTotal: r.counts.videos,
        usersTotal: r.counts.users,
        isLoading: false,
      );
    } catch (_) {
      if (seq != _seq) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not search right now.',
      );
    }
  }

  // ---- follow -------------------------------------------------------------

  /// Optimistically follows / unfollows a user shown in the results.
  Future<void> toggleFollowUser(PublicProfile user) async {
    final following = !user.isFollowing;
    void apply(bool value, int? followers) {
      state = state.copyWith(
        users: [
          for (final u in state.users)
            u.id == user.id
                ? u.copyWith(isFollowing: value, followersCount: followers)
                : u,
        ],
      );
    }

    final before = user.followersCount;
    apply(following, before == null ? null : before + (following ? 1 : -1));
    try {
      final social = ref.read(socialRemoteDataSourceProvider);
      final count = following
          ? await social.followUser(user.username)
          : await social.unfollowUser(user.username);
      apply(following, count);
    } catch (_) {
      apply(!following, before);
    }
  }

  // ---- recent searches --------------------------------------------------

  Future<void> _loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        recents: prefs.getStringList(_recentsKey) ?? const [],
        query: state.query,
      );
    } catch (_) {}
  }

  Future<void> _remember(String term) async {
    final next = [
      term,
      ...state.recents.where((r) => r.toLowerCase() != term.toLowerCase()),
    ].take(_maxRecents).toList();
    state = state.copyWith(recents: next);
    await _persist(next);
  }

  Future<void> removeRecent(String term) async {
    final next = state.recents.where((r) => r != term).toList();
    state = state.copyWith(recents: next);
    await _persist(next);
  }

  Future<void> clearRecents() async {
    state = state.copyWith(recents: const []);
    await _persist(const []);
  }

  Future<void> _persist(List<String> recents) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentsKey, recents);
    } catch (_) {}
  }
}

final searchViewModelProvider = NotifierProvider<SearchViewModel, SearchState>(
  SearchViewModel.new,
);
