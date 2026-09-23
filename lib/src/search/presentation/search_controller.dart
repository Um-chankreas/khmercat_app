import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/search/providers/search_providers.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentsKey = 'recent_searches';
const _maxRecents = 8;

class SearchState {
  /// The term that was actually sent to the API — what the user typed, or
  /// the cuisine label when a cuisine chip is picked with an empty box.
  final String query;
  final List<Restaurant> restaurants;
  final List<VideoFeedItem> videos;
  final List<PublicProfile> users;
  final bool isLoading;
  final String? errorMessage;

  /// Selected cuisine chip (a restaurant category name), or null for "All".
  final String? cuisine;
  final List<String> recents;

  const SearchState({
    this.query = '',
    this.restaurants = const [],
    this.videos = const [],
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.cuisine,
    this.recents = const [],
  });

  bool get hasSearched => query.isNotEmpty;

  SearchState copyWith({
    String? query,
    List<Restaurant>? restaurants,
    List<VideoFeedItem>? videos,
    List<PublicProfile>? users,
    bool? isLoading,
    String? errorMessage,
    String? cuisine,
    bool clearCuisine = false,
    List<String>? recents,
  }) {
    return SearchState(
      query: query ?? this.query,
      restaurants: restaurants ?? this.restaurants,
      videos: videos ?? this.videos,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cuisine: clearCuisine ? null : (cuisine ?? this.cuisine),
      recents: recents ?? this.recents,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  Timer? _debounce;

  /// What's currently in the text box (as opposed to [SearchState.query],
  /// which can be a cuisine label).
  String _typed = '';

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadRecents);
    return const SearchState();
  }

  // ---- input ------------------------------------------------------------

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _typed = query.trim();
    if (_typed.isEmpty) {
      _resetResults();
      // A cuisine chip is still selected: fall back to searching by it.
      final cuisine = state.cuisine;
      if (cuisine != null) _run(cuisine);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(_typed));
  }

  /// Runs [term] immediately (keyboard "search", or tapping a recent search)
  /// and remembers it.
  void submit(String term) {
    _debounce?.cancel();
    _typed = term.trim();
    if (_typed.isEmpty) return;
    _run(_typed);
    _remember(_typed);
  }

  /// Remembers the current typed query — called when the user opens a result,
  /// which is the signal that the search was actually useful.
  void commitSearch() {
    if (_typed.isNotEmpty) _remember(_typed);
  }

  void setCuisine(String? cuisine) {
    if (cuisine == state.cuisine) return;
    if (cuisine == null) {
      state = state.copyWith(clearCuisine: true);
      if (_typed.isEmpty) _resetResults();
      return;
    }
    state = state.copyWith(cuisine: cuisine);
    // No text typed: a cuisine on its own becomes the search term. With text
    // typed it just filters the results already on screen.
    if (_typed.isEmpty) _run(cuisine);
  }

  void _resetResults() {
    _debounce?.cancel();
    state = SearchState(cuisine: state.cuisine, recents: state.recents);
  }

  Future<void> _run(String term) async {
    state = state.copyWith(query: term, isLoading: true);
    try {
      final results = await ref.read(searchRepositoryProvider).search(term);
      // A newer query may have replaced this one while it was in flight.
      if (state.query != term) return;
      state = state.copyWith(
        restaurants: results.restaurants,
        videos: results.videos,
        users: results.users,
        isLoading: false,
      );
    } catch (_) {
      if (state.query != term) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not search right now.',
      );
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
