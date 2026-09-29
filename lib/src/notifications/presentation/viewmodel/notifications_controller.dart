import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';
import 'package:khmer_cat_app/core/network/reverb_socket.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';
import 'package:khmer_cat_app/src/notifications/data/notifications_repository.dart';
import 'package:khmer_cat_app/src/notifications/providers/notifications_providers.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';

class NotificationsState {
  final List<AppNotification> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final int unreadCount;

  /// Unread count per filter tab (badges).
  final Map<NotificationFilter, int> unreadByFilter;

  /// The selected filter tab; [items] only holds notifications that match.
  final NotificationFilter filter;
  final String? errorMessage;
  final SocketConnectionState connectionState;

  const NotificationsState({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.unreadCount = 0,
    this.unreadByFilter = const {},
    this.filter = NotificationFilter.all,
    this.errorMessage,
    this.connectionState = SocketConnectionState.connecting,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    int? unreadCount,
    Map<NotificationFilter, int>? unreadByFilter,
    NotificationFilter? filter,
    String? errorMessage,
    SocketConnectionState? connectionState,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadByFilter: unreadByFilter ?? this.unreadByFilter,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class NotificationsController extends Notifier<NotificationsState> {
  static const _channelPrefix = 'private-App.Models.User.';

  StreamSubscription? _eventsSub;
  StreamSubscription? _connectionSub;
  Timer? _pollTimer;
  String? _channelName;

  @override
  NotificationsState build() {
    Future.microtask(loadInitial);

    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null) {
      _channelName = '$_channelPrefix$userId';
      _connectSocket();
    }

    ref.onDispose(() {
      _eventsSub?.cancel();
      _connectionSub?.cancel();
      _pollTimer?.cancel();
      final channel = _channelName;
      if (channel != null) ref.read(reverbSocketProvider).unsubscribe(channel);
    });

    final socket = ref.read(reverbSocketProvider);
    return NotificationsState(connectionState: socket.state);
  }

  void _connectSocket() {
    final socket = ref.read(reverbSocketProvider);

    _connectionSub = socket.connectionState.listen((connectionState) {
      state = state.copyWith(connectionState: connectionState);
      if (connectionState == SocketConnectionState.connected) {
        _pollTimer?.cancel();
        _pollTimer = null;
      } else {
        _startPollingFallback();
      }
    });

    _eventsSub = socket
        .subscribePrivate(
          _channelName!,
          getAuth: ref.read(privateChannelAuthProvider),
        )
        .listen(_handleSocketEvent);

    if (socket.state != SocketConnectionState.connected) {
      _startPollingFallback();
    }
  }

  void _startPollingFallback() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollForNew();
    });
  }

  /// Add-only merge of page 1 — mirrors CommentsController's approach so a
  /// slow poll can't clobber an in-flight optimistic mark-read/delete.
  Future<void> _pollForNew() async {
    try {
      final page = await _fetch(1);
      final knownIds = state.items.map((n) => n.id).toSet();
      final newOnes = page.items.where((n) => !knownIds.contains(n.id));
      if (newOnes.isEmpty) return;
      state = state.copyWith(
        items: [...newOnes, ...state.items],
        unreadCount: page.unreadCount,
        unreadByFilter: page.unreadByFilter,
      );
    } catch (_) {
      // silent — next tick tries again
    }
  }

  void _handleSocketEvent(PusherMessage message) {
    if (message.event != 'notification') return;
    final data = message.data;
    if (data is! Map) return;

    // BroadcastNotificationCreated wraps the notification's own toArray()
    // payload flat alongside `id`/`type`/`read_at` — same shape as the
    // REST list, minus `is_read` (always false — it just arrived).
    final json = data.cast<String, dynamic>();
    final incoming = AppNotification.fromJson({
      ...json,
      'is_read': false,
      'created_at': json['created_at'] ?? DateTime.now().toIso8601String(),
    });

    if (state.items.any((n) => n.id == incoming.id)) return;
    final counts = _bump(
      state.unreadByFilter,
      NotificationFilter.of(incoming.type),
      1,
    );
    state = state.copyWith(
      // Only list it if it belongs in the tab being shown; the badges
      // update either way.
      items: state.filter.matches(incoming.type)
          ? [incoming, ...state.items]
          : state.items,
      unreadCount: state.unreadCount + 1,
      unreadByFilter: counts,
    );
  }

  static Map<NotificationFilter, int> _bump(
    Map<NotificationFilter, int> counts,
    NotificationFilter filter,
    int delta,
  ) {
    int v(NotificationFilter f) => ((counts[f] ?? 0) + delta).clamp(0, 1 << 30);
    return {
      ...counts,
      NotificationFilter.all: v(NotificationFilter.all),
      if (filter != NotificationFilter.all) filter: v(filter),
    };
  }

  Future<NotificationsPage> _fetch(int page) => ref
      .read(notificationsRepositoryProvider)
      .getNotifications(page: page, filter: state.filter);

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final filter = state.filter;
    try {
      final page = await _fetch(1);
      if (filter != state.filter) return; // switched tabs meanwhile
      state = state.copyWith(
        items: page.items,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        unreadCount: page.unreadCount,
        unreadByFilter: page.unreadByFilter,
        isLoading: false,
      );
    } catch (_) {
      if (filter != state.filter) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load notifications.',
      );
    }
  }

  /// Pull-to-refresh: reloads without the loading skeleton.
  Future<void> refresh() async {
    final filter = state.filter;
    try {
      final page = await _fetch(1);
      if (filter != state.filter) return;
      state = state.copyWith(
        items: page.items,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        unreadCount: page.unreadCount,
        unreadByFilter: page.unreadByFilter,
      );
    } catch (_) {}
  }

  /// Switches the filter tab and loads its first page.
  void setFilter(NotificationFilter filter) {
    if (filter == state.filter) return;
    state = state.copyWith(
      filter: filter,
      items: const [],
      currentPage: 0,
      hasMore: true,
    );
    loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final filter = state.filter;
    try {
      final page = await _fetch(state.currentPage + 1);
      if (filter != state.filter) return;
      final known = state.items.map((n) => n.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((n) => !known.contains(n.id)),
        ],
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Marks these read locally right away (opening a notification shouldn't
  /// wait on a round-trip), then tells the server in one call.
  void markRead(List<String> ids) {
    final unread = state.items
        .where((n) => ids.contains(n.id) && !n.isRead)
        .toList();
    if (unread.isEmpty) return;

    var counts = state.unreadByFilter;
    for (final n in unread) {
      counts = _bump(counts, NotificationFilter.of(n.type), -1);
    }
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (ids.contains(n.id)) n.copyWith(isRead: true) else n,
      ],
      unreadCount: (state.unreadCount - unread.length).clamp(0, 1 << 30),
      unreadByFilter: counts,
    );
    ref
        .read(notificationsRepositoryProvider)
        .markManyRead(unread.map((n) => n.id).toList())
        .catchError((_) {});
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;
    final original = state;
    state = state.copyWith(
      items: [for (final n in state.items) n.copyWith(isRead: true)],
      unreadCount: 0,
      unreadByFilter: {for (final f in NotificationFilter.values) f: 0},
    );
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {
      state = original; // roll back
    }
  }

  /// Deletes a (possibly grouped) row.
  Future<bool> delete(List<String> ids) async {
    final original = state;
    final removed = state.items.where((n) => ids.contains(n.id)).toList();
    var counts = state.unreadByFilter;
    var unread = state.unreadCount;
    for (final n in removed.where((n) => !n.isRead)) {
      counts = _bump(counts, NotificationFilter.of(n.type), -1);
      unread--;
    }
    state = state.copyWith(
      items: state.items.where((n) => !ids.contains(n.id)).toList(),
      unreadCount: unread.clamp(0, 1 << 30),
      unreadByFilter: counts,
    );
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      ids.length == 1
          ? await repo.delete(ids.first)
          : await repo.deleteMany(ids);
      return true;
    } catch (_) {
      state = original;
      return false;
    }
  }

  Future<void> deleteAll() async {
    final original = state;
    state = state.copyWith(
      items: const [],
      unreadCount: 0,
      unreadByFilter: {for (final f in NotificationFilter.values) f: 0},
    );
    try {
      await ref.read(notificationsRepositoryProvider).deleteAll();
    } catch (_) {
      state = original; // roll back
    }
  }

  /// "Follow back" on a follow notification: flips every row from that
  /// person right away, rolls back if the request fails.
  Future<bool> followBack(NotificationActor actor) async {
    void set(bool following) {
      state = state.copyWith(
        items: [
          for (final n in state.items)
            if (n.actor?.id == actor.id)
              n.copyWith(actor: n.actor!.copyWith(isFollowing: following))
            else
              n,
        ],
      );
    }

    set(true);
    try {
      await ref.read(socialRemoteDataSourceProvider).followUser(actor.username);
      return true;
    } catch (_) {
      set(false);
      return false;
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );
