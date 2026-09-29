import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';
import 'package:khmer_cat_app/src/notifications/domain/app_notification.dart';
import 'package:khmer_cat_app/src/notifications/domain/notification_group.dart';
import 'package:khmer_cat_app/src/notifications/presentation/viewmodel/notifications_controller.dart';
import 'package:khmer_cat_app/src/notifications/presentation/widgets/notification_tile.dart';

/// Notifications, grouped by date like Facebook:
///  header (title, mark all read, more) → sections (Today / Yesterday /
///  This week / Earlier) of rows, where same-day repeats are folded into
///  one ("@a liked 8 of your reviews"). Unread rows are highlighted.
/// Tap opens the video or profile (and marks it read); swipe left deletes;
/// pull to refresh.
class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    // Regroup only when the list itself changes.
    final groups = useMemoized(() => groupNotifications(state.items), [
      state.items,
    ]);

    Future<void> open(NotificationGroup g) async {
      controller.markRead(g.ids);
      final n = g.latest;

      if (n.type == NotificationType.follow) {
        final username = n.actor?.username;
        if (username != null) {
          AppRouter.router.pushNamed(
            AppRoute.userProfile.name,
            pathParameters: {'username': username},
          );
        }
        return;
      }

      final videoId = n.videoId;
      if (videoId == null) return;
      try {
        final video = await ref.read(feedRepositoryProvider).getVideo(videoId);
        if (context.mounted) {
          AppRouter.router.pushNamed(
            AppRoute.videoViewer.name,
            pathParameters: {'id': videoId},
            extra: video,
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppService.showToast('That video is no longer available.');
        }
      }
    }

    Future<void> followBack(NotificationGroup g) async {
      final actor = g.latest.actor;
      if (actor == null) return;
      HapticFeedback.lightImpact();
      final ok = await controller.followBack(actor);
      if (ok) {
        AppService.showToast('You follow @${actor.username} now');
      } else {
        AppService.showToast('Could not follow. Try again.', isError: true);
      }
    }

    void clearAll() => AppDialogs.showConfirm(
      context,
      title: 'Clear all notifications?',
      message: 'This removes every notification and can\'t be undone.',
      confirmText: 'Clear all',
      isDestructive: true,
      onConfirm: controller.deleteAll,
    );

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const _Skeleton();
    } else if (state.errorMessage != null && state.items.isEmpty) {
      body = _Empty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load notifications',
        message: 'Check your connection and try again.',
        action: TextButton(
          onPressed: controller.loadInitial,
          child: const Text('Try again'),
        ),
      );
    } else if (groups.isEmpty) {
      body = const _Empty(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message: 'Likes, comments and new followers will show up here.',
      );
    } else {
      // Flatten into section headers + rows for one lazy list.
      final now = DateTime.now();
      final rows = <Object>[];
      NotificationSection? current;
      NotificationSection? first;
      for (final g in groups) {
        final section = NotificationSection.of(g, now);
        if (section != current) {
          rows.add(section);
          current = section;
          first ??= section;
        }
        rows.add(g);
      }

      body = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) controller.loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: rows.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= rows.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProfileTheme.purple,
                    ),
                  ),
                ),
              );
            }
            final row = rows[i];
            if (row is NotificationSection) {
              return _SectionHeader(
                section: row,
                showMarkRead: row == first && state.unreadCount > 0,
                onMarkRead: controller.markAllRead,
              );
            }
            final g = row as NotificationGroup;
            return Dismissible(
              key: ValueKey(g.ids.join(',')),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: const Color(0xffE5484D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) async {
                final ok = await controller.delete(g.ids);
                if (!ok) {
                  AppService.showToast('Could not delete.', isError: true);
                }
              },
              child: NotificationTile(
                group: g,
                onTap: () => open(g),
                onFollowBack: () => followBack(g),
              ),
            );
          },
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(
            unreadCount: state.unreadCount,
            hasItems: state.items.isNotEmpty,
            onMarkAllRead: controller.markAllRead,
            onClearAll: clearAll,
          ),
          Expanded(
            child: RefreshIndicator(
              color: ProfileTheme.purple,
              onRefresh: controller.refresh,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(state.isLoading && state.items.isEmpty),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header + filter tabs
// =============================================================================

class _Header extends StatelessWidget {
  final int unreadCount;
  final bool hasItems;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  const _Header({
    required this.unreadCount,
    required this.hasItems,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
                const Gap(1),
                Text(
                  unreadCount == 0
                      ? 'You\'re all caught up'
                      : '$unreadCount unread',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: unreadCount == 0 ? muted : ProfileTheme.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: unreadCount > 0 ? onMarkAllRead : null,
            icon: Icon(
              Icons.done_all_rounded,
              color: unreadCount > 0
                  ? ProfileTheme.deepPurple
                  : muted.withValues(alpha: 0.4),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_horiz_rounded, color: muted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabled: hasItems,
            onSelected: (v) {
              if (v == 'clear') onClearAll();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Color(0xffE5484D)),
                    Gap(10),
                    Text(
                      'Clear all',
                      style: TextStyle(color: Color(0xffE5484D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final NotificationSection section;
  final bool showMarkRead;
  final VoidCallback onMarkRead;
  const _SectionHeader({
    required this.section,
    required this.showMarkRead,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              section.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
          ),
          if (showMarkRead)
            GestureDetector(
              onTap: onMarkRead,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.deepPurple,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty + loading
// =============================================================================

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // Scrollable so pull-to-refresh works on an empty list too.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ProfileTheme.pink.withValues(alpha: 0.14),
                  ProfileTheme.blue.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Icon(icon, size: 40, color: ProfileTheme.purple),
          ),
        ),
        const Gap(16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        const Gap(6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
        if (action != null) ...[const Gap(10), Center(child: action)],
      ],
    );
  }
}

class _Skeleton extends HookWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      ctrl.repeat(reverse: true);
      return null;
    }, const []);
    final t = useAnimation(ctrl);
    final bar = ProfileTheme.purple.withValues(alpha: 0.06 + 0.07 * t);

    Widget block(double w, double h, [double r = 6]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: 7,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: bar, shape: BoxShape.circle),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(double.infinity, 13),
                  const Gap(8),
                  block(90, 11),
                ],
              ),
            ),
            const Gap(12),
            block(48, 48, 10),
          ],
        ),
      ),
    );
  }
}
