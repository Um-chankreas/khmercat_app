import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/feed_tab.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';

class FeedState {
  final List<VideoFeedItem> items;
  final String? cursor;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool requiresAuth;
  final String? errorMessage;

  const FeedState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.requiresAuth = false,
    this.errorMessage,
  });

  FeedState copyWith({
    List<VideoFeedItem>? items,
    String? cursor,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? requiresAuth,
    String? errorMessage,
  }) {
    return FeedState(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      errorMessage: errorMessage,
    );
  }
}

class FeedController extends FamilyNotifier<FeedState, FeedTab> {
  @override
  FeedState build(FeedTab arg) {
    // Rebuild (and re-fetch) on login/logout — a guest's for_you feed gains
    // `liked_by_me` once signed in, and following flips to/from the sign-in
    // prompt without waiting for the user to switch tabs and back.
    ref.watch(isAuthenticatedProvider);

    // If location shows up after our first (location-less) fetch, refine
    // the for_you feed once rather than blocking on permission upfront.
    ref.listen(locationProvider, (previous, next) {
      if (arg == FeedTab.forYou && previous == null && next != null) {
        refresh();
      }
    });

    Future.microtask(refresh);
    return const FeedState();
  }

  String get _tabParam => arg == FeedTab.forYou ? 'for_you' : 'following';

  /// [keepItems] is for pull-to-refresh: the current videos stay on screen
  /// (no full-screen spinner) until the fresh page replaces them.
  Future<void> refresh({bool keepItems = false}) async {
    if (arg == FeedTab.following && !ref.read(isAuthenticatedProvider)) {
      state = state.copyWith(isInitialLoading: false, requiresAuth: true);
      return;
    }

    state = state.copyWith(
      isInitialLoading: !(keepItems && state.items.isNotEmpty),
      requiresAuth: false,
    );
    try {
      final position = ref.read(locationProvider);
      final page = await ref
          .read(feedRepositoryProvider)
          .getFeed(
            tab: _tabParam,
            lat: position?.latitude,
            lng: position?.longitude,
          );
      state = FeedState(
        items: page.items,
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        isInitialLoading: false,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        state = state.copyWith(isInitialLoading: false, requiresAuth: true);
      } else {
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: e.message,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final position = ref.read(locationProvider);
      final page = await ref
          .read(feedRepositoryProvider)
          .getFeed(
            tab: _tabParam,
            cursor: state.cursor,
            lat: position?.latitude,
            lng: position?.longitude,
          );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      // silent — infinite scroll just stops advancing, user can retry by
      // scrolling again since isLoadingMore resets
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String videoId) async {
    final index = state.items.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final original = state.items[index];
    final optimistic = original.copyWith(
      likedByMe: !original.likedByMe,
      likesCount: original.likedByMe
          ? original.likesCount - 1
          : original.likesCount + 1,
    );
    _replaceAt(index, optimistic);

    try {
      final repo = ref.read(feedRepositoryProvider);
      final likesCount = optimistic.likedByMe
          ? await repo.like(videoId)
          : await repo.unlike(videoId);
      _replaceAt(index, optimistic.copyWith(likesCount: likesCount));
    } catch (_) {
      _replaceAt(index, original); // roll back
    }
  }

  Future<void> toggleSave(String videoId) async {
    final index = state.items.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final original = state.items[index];
    final optimistic = original.copyWith(savedByMe: !original.savedByMe);
    _replaceAt(index, optimistic);

    try {
      final repo = ref.read(feedRepositoryProvider);
      if (optimistic.savedByMe) {
        await repo.save(videoId);
      } else {
        await repo.unsave(videoId);
      }
    } catch (_) {
      _replaceAt(index, original); // roll back
    }
  }

  void markFollowedLocally(String videoId) {
    final index = state.items.indexWhere((v) => v.id == videoId);
    if (index == -1) return;
    _replaceAt(index, state.items[index].copyWith(followingLocally: true));
  }

  void _replaceAt(int index, VideoFeedItem item) {
    final updated = List<VideoFeedItem>.from(state.items);
    updated[index] = item;
    state = state.copyWith(items: updated);
  }

  void incrementCommentCount(String videoId, int delta) {
    final index = state.items.indexWhere((v) => v.id == videoId);
    if (index == -1) return;
    final item = state.items[index];
    _replaceAt(index, item.copyWith(commentsCount: item.commentsCount + delta));
  }
}

final feedControllerProvider =
    NotifierProvider.family<FeedController, FeedState, FeedTab>(
      FeedController.new,
    );
