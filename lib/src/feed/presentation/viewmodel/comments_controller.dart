import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/core/network/reverb_socket.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/comment.dart';
import 'package:khmer_cat_app/src/feed/providers/comments_providers.dart';

class CommentsState {
  /// Top-level comments, newest first, each with its loaded replies.
  final List<VideoComment> items;

  /// Every comment including replies (the header badge).
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isPosting;
  final bool isRefreshing;

  /// Ids of top-level comments whose extra replies are being fetched.
  final Set<String> loadingReplies;
  final String? errorMessage;
  final SocketConnectionState connectionState;

  const CommentsState({
    this.items = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isPosting = false,
    this.isRefreshing = false,
    this.loadingReplies = const {},
    this.errorMessage,
    this.connectionState = SocketConnectionState.connecting,
  });

  CommentsState copyWith({
    List<VideoComment>? items,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isPosting,
    bool? isRefreshing,
    Set<String>? loadingReplies,
    String? errorMessage,
    SocketConnectionState? connectionState,
  }) {
    return CommentsState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isPosting: isPosting ?? this.isPosting,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      loadingReplies: loadingReplies ?? this.loadingReplies,
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
      final page = await _fetchPage(1);
      final knownIds = state.items.map((c) => c.id).toSet();
      final newOnes = page.items.where((c) => !knownIds.contains(c.id));
      if (newOnes.isEmpty) return;
      state = state.copyWith(
        items: [...newOnes, ...state.items],
        totalCount: page.totalAll,
      );
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
        if (_find(incoming.id) != null) return;
        _insert(incoming);
      case 'comment.deleted':
        final id = json['comment_id']?.toString();
        if (id == null) return;
        _remove(
          id,
          parentId: json['parent_id']?.toString(),
          removed: (json['removed_count'] as num?)?.toInt(),
        );
      case 'comment.liked':
        final id = json['comment_id']?.toString();
        final likesCount = (json['likes_count'] as num?)?.toInt();
        if (id == null || likesCount == null) return;
        _update(id, (c) => c.copyWith(likesCount: likesCount));
    }
  }

  // ---- tree helpers -------------------------------------------------------

  VideoComment? _find(String id) {
    for (final c in state.items) {
      if (c.id == id) return c;
      for (final r in c.replies) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  /// Applies [change] to the comment or reply with [id].
  void _update(String id, VideoComment Function(VideoComment) change) {
    state = state.copyWith(
      items: [
        for (final c in state.items)
          if (c.id == id)
            change(c)
          else if (c.replies.any((r) => r.id == id))
            c.copyWith(
              replies: [for (final r in c.replies) r.id == id ? change(r) : r],
            )
          else
            c,
      ],
    );
  }

  /// Adds a new top-level comment at the top, or a reply at the end of its
  /// thread.
  void _insert(VideoComment comment) {
    final parentId = comment.parentId;
    if (parentId == null) {
      state = state.copyWith(
        items: [comment, ...state.items],
        totalCount: state.totalCount + 1,
      );
      return;
    }
    state = state.copyWith(
      items: [
        for (final c in state.items)
          if (c.id == parentId)
            c.copyWith(
              replies: [...c.replies, comment],
              repliesCount: c.repliesCount + 1,
            )
          else
            c,
      ],
      totalCount: state.totalCount + 1,
    );
  }

  /// Removes a comment (with its replies) or a single reply. [removed] is
  /// the server's count of deleted rows when known.
  void _remove(String id, {String? parentId, int? removed}) {
    final target = _find(id);
    if (target == null) return;
    final pid = parentId ?? target.parentId;
    final gone = removed ?? (1 + (pid == null ? target.repliesCount : 0));
    state = state.copyWith(
      items: [
        for (final c in state.items)
          if (c.id == id)
            ...[]
          else if (c.id == pid)
            c.copyWith(
              replies: c.replies.where((r) => r.id != id).toList(),
              repliesCount: (c.repliesCount - 1).clamp(0, 1 << 30),
            )
          else
            c,
      ],
      totalCount: (state.totalCount - gone).clamp(0, 1 << 30),
    );
  }

  // ---- loading ------------------------------------------------------------

  Future<({List<VideoComment> items, bool hasMore, int page, int totalAll})>
  _fetchPage(int page) async {
    final json = await ref
        .read(commentsRemoteDataSourceProvider)
        .getComments(_videoId, page: page);
    final items = (json['contents'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(VideoComment.fromJson)
        .toList();
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? {};
    return (
      items: items,
      hasMore: meta['has_more'] == true,
      page: (meta['current_page'] as num?)?.toInt() ?? page,
      totalAll:
          ((meta['total_all'] ?? meta['total']) as num?)?.toInt() ??
          items.length,
    );
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final page = await _fetchPage(1);
      state = state.copyWith(
        items: page.items,
        totalCount: page.totalAll,
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load comments.',
      );
    }
  }

  /// Reloads page 1 in place — the list stays on screen meanwhile.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      final page = await _fetchPage(1);
      state = state.copyWith(
        items: page.items,
        totalCount: page.totalAll,
        currentPage: page.page,
        hasMore: page.hasMore,
        isRefreshing: false,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _fetchPage(state.currentPage + 1);
      // Live comments shift pages, so skip anything already on screen.
      final known = state.items.map((c) => c.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((c) => !known.contains(c.id)),
        ],
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  static const _repliesPerPage = 10;

  /// Loads the next batch of replies for a top-level comment.
  Future<void> loadMoreReplies(String commentId) async {
    final parent = _find(commentId);
    if (parent == null || state.loadingReplies.contains(commentId)) return;
    state = state.copyWith(
      loadingReplies: {...state.loadingReplies, commentId},
    );
    try {
      final json = await ref
          .read(commentsRemoteDataSourceProvider)
          .getReplies(
            commentId,
            page: parent.replies.length ~/ _repliesPerPage + 1,
            perPage: _repliesPerPage,
          );
      final fetched = (json['contents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(VideoComment.fromJson)
          .toList();
      final total = ((json['meta'] as Map?)?['total'] as num?)?.toInt();
      _update(commentId, (c) {
        final known = c.replies.map((r) => r.id).toSet();
        final merged =
            [...c.replies, ...fetched.where((r) => !known.contains(r.id))]
              ..sort(
                (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
                  b.createdAt ?? DateTime(0),
                ),
              );
        return c.copyWith(replies: merged, repliesCount: total);
      });
    } catch (_) {
      // Leave the "View more replies" link so the user can try again.
    } finally {
      state = state.copyWith(
        loadingReplies: {...state.loadingReplies}..remove(commentId),
      );
    }
  }

  // ---- actions ------------------------------------------------------------

  /// Posts a comment, or a reply when [replyTo] is given (a reply to a
  /// reply joins the same thread).
  Future<bool> post(String body, {VideoComment? replyTo}) async {
    if (!ref.read(isAuthenticatedProvider) || body.trim().isEmpty) return false;

    state = state.copyWith(isPosting: true);
    try {
      final data = await ref
          .read(commentsRemoteDataSourceProvider)
          .postComment(_videoId, body.trim(), parentId: replyTo?.id);
      final comment = VideoComment.fromJson(data);
      state = state.copyWith(isPosting: false);
      // The socket echo may have beaten the REST response here.
      if (_find(comment.id) == null) _insert(comment);
      return true;
    } catch (_) {
      state = state.copyWith(isPosting: false);
      return false;
    }
  }

  Future<bool> delete(String commentId) async {
    final snapshot = state;
    _remove(commentId);
    try {
      await ref.read(commentsRemoteDataSourceProvider).deleteComment(commentId);
      return true;
    } catch (_) {
      state = state.copyWith(
        items: snapshot.items,
        totalCount: snapshot.totalCount,
      ); // roll back
      return false;
    }
  }

  Future<void> toggleLike(String commentId) async {
    if (!ref.read(isAuthenticatedProvider)) return;

    final original = _find(commentId);
    if (original == null) return;

    final optimistic = original.copyWith(
      isLikedByMe: !original.isLikedByMe,
      likesCount: original.isLikedByMe
          ? original.likesCount - 1
          : original.likesCount + 1,
    );
    _update(commentId, (_) => optimistic);

    try {
      final data = await ref
          .read(commentsRemoteDataSourceProvider)
          .toggleLike(commentId);
      _update(
        commentId,
        (c) => c.copyWith(
          likesCount: (data['likes_count'] as num?)?.toInt(),
          isLikedByMe: data['is_liked'] as bool?,
        ),
      );
    } catch (_) {
      _update(
        commentId,
        (c) => c.copyWith(
          likesCount: original.likesCount,
          isLikedByMe: original.isLikedByMe,
        ),
      );
    }
  }
}

final commentsControllerProvider =
    NotifierProvider.family<CommentsController, CommentsState, String>(
      CommentsController.new,
    );
