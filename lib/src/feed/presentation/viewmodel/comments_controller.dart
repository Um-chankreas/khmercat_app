import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/core/network/reverb_socket.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/comment.dart';
import 'package:khmer_cat_app/src/feed/providers/comments_providers.dart';

class CommentsState {
  final List<VideoComment> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isPosting;
  final String? errorMessage;
  final SocketConnectionState connectionState;

  const CommentsState({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isPosting = false,
    this.errorMessage,
    this.connectionState = SocketConnectionState.connecting,
  });

  CommentsState copyWith({
    List<VideoComment>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isPosting,
    String? errorMessage,
    SocketConnectionState? connectionState,
  }) {
    return CommentsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isPosting: isPosting ?? this.isPosting,
      errorMessage: errorMessage,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class CommentsController extends FamilyNotifier<CommentsState, String> {
  String get _videoId => arg;
  String get _channelName => 'video.$_videoId.comments';

  StreamSubscription? _eventsSub;
  StreamSubscription? _connectionSub;
  Timer? _pollTimer;

  @override
  CommentsState build(String videoId) {
    Future.microtask(loadInitial);
    final socket = ref.read(reverbSocketProvider);
    _connectSocket(socket);
    ref.onDispose(() {
      _eventsSub?.cancel();
      _connectionSub?.cancel();
      _pollTimer?.cancel();
      ref.read(reverbSocketProvider).unsubscribe(_channelName);
    });
    // The socket connects once at app startup (see main.dart), so by the
    // time a comments sheet opens it's very likely already connected — seed
    // from its current state rather than defaulting to "connecting" and
    // waiting on a stream event that, if already connected, won't fire
    // again (a broadcast stream doesn't replay past events to new listeners).
    return CommentsState(connectionState: socket.state);
  }

  void _connectSocket(ReverbSocket socket) {
    _connectionSub = socket.connectionState.listen((connectionState) {
      state = state.copyWith(connectionState: connectionState);
      // The socket is the source of truth while it's up; polling only
      // covers the gap while it's down or still trying to reconnect.
      if (connectionState == SocketConnectionState.connected) {
        _pollTimer?.cancel();
        _pollTimer = null;
      } else {
        _startPollingFallback();
      }
    });

    _eventsSub = socket.subscribe(_channelName).listen(_handleSocketEvent);

    // Same reasoning as above: if we're already disconnected by the time
    // this subscribes, start polling immediately instead of waiting for a
    // state-change event that already happened.
    if (socket.state != SocketConnectionState.connected) {
      _startPollingFallback();
    }
  }

  void _startPollingFallback() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _pollForNewComments();
    });
  }

  /// Add-only merge of page 1 — never removes or reorders anything a local
  /// action (post/delete/like) already changed, so a slow poll response
  /// can't clobber an in-flight optimistic update.
  Future<void> _pollForNewComments() async {
    try {
      final json = await ref
          .read(commentsRemoteDataSourceProvider)
          .getComments(_videoId, page: 1);
      final fetched = (json['contents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoComment.fromJson)
          .toList();
      final knownIds = state.items.map((c) => c.id).toSet();
      final newOnes = fetched.where((c) => !knownIds.contains(c.id));
      if (newOnes.isEmpty) return;
      state = state.copyWith(items: [...newOnes, ...state.items]);
    } catch (_) {
      // silent — next tick tries again
    }
  }

  void _handleSocketEvent(PusherMessage message) {
    final data = message.data;
    if (data is! Map) return;
    final json = data.cast<String, dynamic>();

    switch (message.event) {
      case 'comment.new':
        final incoming = VideoComment.fromJson(json);
        // Our own just-posted comment already landed via post()'s REST
        // response — don't add it twice.
        if (state.items.any((c) => c.id == incoming.id)) return;
        state = state.copyWith(items: [incoming, ...state.items]);
      case 'comment.deleted':
        final id = json['comment_id']?.toString();
        if (id == null) return;
        state = state.copyWith(
          items: state.items.where((c) => c.id != id).toList(),
        );
      case 'comment.liked':
        final id = json['comment_id']?.toString();
        final likesCount = (json['likes_count'] as num?)?.toInt();
        if (id == null || likesCount == null) return;
        state = state.copyWith(
          items: [
            for (final c in state.items)
              if (c.id == id) c.copyWith(likesCount: likesCount) else c,
          ],
        );
    }
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final json = await ref
          .read(commentsRemoteDataSourceProvider)
          .getComments(_videoId, page: 1);
      final contents = (json['contents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoComment.fromJson)
          .toList();
      final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      state = CommentsState(
        items: contents,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
        hasMore: meta['has_more'] == true,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load comments.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final json = await ref
          .read(commentsRemoteDataSourceProvider)
          .getComments(_videoId, page: nextPage);
      final contents = (json['contents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoComment.fromJson)
          .toList();
      final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        items: [...state.items, ...contents],
        currentPage: nextPage,
        hasMore: meta['has_more'] == true,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> post(String body) async {
    if (!ref.read(isAuthenticatedProvider) || body.trim().isEmpty) return false;

    state = state.copyWith(isPosting: true);
    try {
      final data = await ref
          .read(commentsRemoteDataSourceProvider)
          .postComment(_videoId, body.trim());
      final comment = VideoComment.fromJson(data);
      state = state.copyWith(
        items: [comment, ...state.items],
        isPosting: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(isPosting: false);
      return false;
    }
  }

  Future<bool> delete(String commentId) async {
    final original = state.items;
    state = state.copyWith(
      items: original.where((c) => c.id != commentId).toList(),
    );
    try {
      await ref.read(commentsRemoteDataSourceProvider).deleteComment(commentId);
      return true;
    } catch (_) {
      state = state.copyWith(items: original); // roll back
      return false;
    }
  }

  Future<void> toggleLike(String commentId) async {
    if (!ref.read(isAuthenticatedProvider)) return;

    final index = state.items.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final original = state.items[index];
    final optimistic = original.copyWith(
      isLikedByMe: !original.isLikedByMe,
      likesCount: original.isLikedByMe
          ? original.likesCount - 1
          : original.likesCount + 1,
    );
    state = state.copyWith(
      items: [
        for (final c in state.items) if (c.id == commentId) optimistic else c,
      ],
    );

    try {
      final data = await ref
          .read(commentsRemoteDataSourceProvider)
          .toggleLike(commentId);
      final confirmed = optimistic.copyWith(
        likesCount: (data['likes_count'] as num?)?.toInt(),
        isLikedByMe: data['is_liked'] as bool?,
      );
      state = state.copyWith(
        items: [
          for (final c in state.items)
            if (c.id == commentId) confirmed else c,
        ],
      );
    } catch (_) {
      state = state.copyWith(
        items: [
          for (final c in state.items) if (c.id == commentId) original else c,
        ],
      );
    }
  }
}

final commentsControllerProvider =
    NotifierProvider.family<CommentsController, CommentsState, String>(
      CommentsController.new,
    );
