import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/reverb_socket.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/comment.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/presentation/viewmodel/comments_controller.dart';

/// Opens the comments sheet for [videoId]. [onCountChanged] lets the caller
/// keep the feed's comment count in sync as comments are posted/deleted.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String videoId,
  ValueChanged<int>? onCountChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Lift the sheet above the keyboard so the composer stays visible.
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: CommentsSheet(videoId: videoId, onCountChanged: onCountChanged),
    ),
  );
}

const _quickReactions = ['🔥', '❤️', '👏', '😊', '🍜'];
const _likePink = Color(0xffFF4F9A);
const _liveGreen = Color(0xff22C55E);

/// Header (count, refresh, close) → live status → threaded comments →
/// quick reactions + composer.
///
/// Performance: the list is lazily built and scrolls with the sheet's own
/// controller (dragging the list also drags the sheet). The composer owns
/// its text state, so typing never rebuilds the list.
class CommentsSheet extends HookConsumerWidget {
  final String videoId;
  final ValueChanged<int>? onCountChanged;

  const CommentsSheet({required this.videoId, this.onCountChanged, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = commentsControllerProvider(videoId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final currentUserId = ref.watch(currentUserProvider.select((u) => u?.id));
    final replyTo = useState<VideoComment?>(null);
    final composerFocus = useFocusNode();

    // Single source of truth for keeping the feed's comment count in sync —
    // covers local posts/deletes and ones from other viewers over the
    // socket, replies included, without double-counting.
    ref.listen<CommentsState>(provider, (previous, next) {
      // Skip the first load: the feed's count already includes those.
      if (previous == null || previous.isLoading || next.isLoading) return;
      final delta = next.totalCount - previous.totalCount;
      if (delta != 0) onCountChanged?.call(delta);
    });

    Future<void> handleLike(VideoComment comment) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to like comments',
      )) {
        return;
      }
      HapticFeedback.selectionClick();
      controller.toggleLike(comment.id);
    }

    Future<void> handleReply(VideoComment comment) async {
      if (!await requireLogin(context, ref, message: 'Sign in to reply')) {
        return;
      }
      replyTo.value = comment;
      composerFocus.requestFocus();
    }

    Future<void> handleLongPress(VideoComment comment) async {
      HapticFeedback.mediumImpact();
      final isMine = comment.user.id == currentUserId;
      final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _CommentActions(isMine: isMine),
      );
      if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: comment.body));
        AppService.showToast('Copied');
      } else if (action == 'delete') {
        if (replyTo.value?.id == comment.id) replyTo.value = null;
        final ok = await controller.delete(comment.id);
        if (!ok && context.mounted) {
          AppService.showToast('Could not delete comment.', isError: true);
        }
      }
    }

    Future<bool> handleSend(String text) async {
      if (!await requireLogin(context, ref, message: 'Sign in to comment')) {
        return false;
      }
      final ok = await controller.post(text, replyTo: replyTo.value);
      if (ok) {
        replyTo.value = null;
      } else if (context.mounted) {
        AppService.showToast('Could not post comment.', isError: true);
      }
      return ok;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const Gap(10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: ProfileTheme.textSecondary(
                    context,
                  ).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _Header(
                total: state.totalCount,
                isRefreshing: state.isRefreshing,
                onRefresh: controller.refresh,
                onClose: () => Navigator.of(context).pop(),
              ),
              _LiveStatus(status: state.connectionState),
              const Gap(8),
              Expanded(
                child: _CommentsBody(
                  state: state,
                  scrollController: sheetScrollController,
                  currentUserId: currentUserId,
                  onLoadMore: controller.loadMore,
                  onRetry: controller.loadInitial,
                  onLike: handleLike,
                  onReply: handleReply,
                  onLongPress: handleLongPress,
                  onMoreReplies: controller.loadMoreReplies,
                ),
              ),
              _Composer(
                focusNode: composerFocus,
                replyTo: replyTo.value,
                isPosting: state.isPosting,
                onCancelReply: () => replyTo.value = null,
                onSend: handleSend,
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Header + live status
// =============================================================================

class _Header extends StatelessWidget {
  final int total;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  const _Header({
    required this.total,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final border = ProfileTheme.hairlineColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 6),
      child: Row(
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          const Gap(10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, a) =>
                ScaleTransition(scale: a, child: child),
            child: Container(
              key: ValueKey(total),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                gradient: ProfileTheme.pinkPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                formatCount(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isRefreshing ? null : onRefresh,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    _SpinningIcon(spinning: isRefreshing),
                    const Gap(6),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(8),
          Material(
            color: Colors.transparent,
            shape: CircleBorder(side: BorderSide(color: border)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinningIcon extends HookWidget {
  final bool spinning;
  const _SpinningIcon({required this.spinning});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    useEffect(() {
      spinning ? ctrl.repeat() : ctrl.stop();
      return null;
    }, [spinning]);
    return RotationTransition(
      turns: ctrl,
      child: const Icon(Icons.sync_rounded, size: 16, color: _likePink),
    );
  }
}

class _LiveStatus extends StatelessWidget {
  final SocketConnectionState status;
  const _LiveStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketConnectionState.connected => ('Live updates connected', _liveGreen),
      SocketConnectionState.connecting => (
        'Connecting to live updates…',
        const Color(0xffF5A524),
      ),
      SocketConnectionState.reconnecting => (
        'Reconnecting…',
        const Color(0xffF5A524),
      ),
      SocketConnectionState.failed => (
        'Offline — checking for new comments',
        const Color(0xffEF4444),
      ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: ProfileTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Body: loading / error / empty / threaded list
// =============================================================================

class _CommentsBody extends StatelessWidget {
  final CommentsState state;
  final ScrollController scrollController;
  final String? currentUserId;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final ValueChanged<VideoComment> onLike;
  final ValueChanged<VideoComment> onReply;
  final ValueChanged<VideoComment> onLongPress;
  final ValueChanged<String> onMoreReplies;

  const _CommentsBody({
    required this.state,
    required this.scrollController,
    required this.currentUserId,
    required this.onLoadMore,
    required this.onRetry,
    required this.onLike,
    required this.onReply,
    required this.onLongPress,
    required this.onMoreReplies,
  });

  @override
  Widget build(BuildContext context) {
    // Every state is a scrollable on the sheet's controller, so the sheet can
    // be dragged from anywhere, even while loading or empty.
    if (state.isLoading && state.items.isEmpty) {
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, _) => const _CommentSkeleton(),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _Message(
        controller: scrollController,
        icon: Icons.cloud_off_rounded,
        title: state.errorMessage!,
        action: TextButton(onPressed: onRetry, child: const Text('Try again')),
      );
    }
    if (state.items.isEmpty) {
      return _Message(
        controller: scrollController,
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No comments yet',
        subtitle: 'Be the first to share your thoughts.',
      );
    }

    final items = state.items;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400) onLoadMore();
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        itemCount: items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
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
          final c = items[index];
          return _CommentThread(
            key: ValueKey(c.id),
            comment: c,
            currentUserId: currentUserId,
            loadingReplies: state.loadingReplies.contains(c.id),
            onLike: onLike,
            onReply: onReply,
            onLongPress: onLongPress,
            onMoreReplies: () => onMoreReplies(c.id),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final ScrollController controller;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const _Message({
    required this.controller,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(icon, size: 44, color: muted.withValues(alpha: 0.6)),
        const Gap(12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ProfileTheme.textPrimary(context),
          ),
        ),
        if (subtitle != null) ...[
          const Gap(4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: muted),
          ),
        ],
        if (action != null) ...[const Gap(8), Center(child: action)],
      ],
    );
  }
}

// =============================================================================
// Comment thread + card
// =============================================================================

/// A top-level comment card followed by its replies (indented, pink rail)
/// and a "View more replies" link when the server has more.
class _CommentThread extends StatelessWidget {
  final VideoComment comment;
  final String? currentUserId;
  final bool loadingReplies;
  final ValueChanged<VideoComment> onLike;
  final ValueChanged<VideoComment> onReply;
  final ValueChanged<VideoComment> onLongPress;
  final VoidCallback onMoreReplies;

  const _CommentThread({
    required this.comment,
    required this.currentUserId,
    required this.loadingReplies,
    required this.onLike,
    required this.onReply,
    required this.onLongPress,
    required this.onMoreReplies,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hidden = comment.hiddenReplies;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommentCard(
            comment: comment,
            onLike: onLike,
            onReply: onReply,
            onLongPress: onLongPress,
          ),
          for (final r in comment.replies)
            Padding(
              key: ValueKey(r.id),
              padding: const EdgeInsets.only(left: 26, top: 10),
              child: _CommentCard(
                comment: r,
                isReply: true,
                onLike: onLike,
                onReply: onReply,
                onLongPress: onLongPress,
              ),
            ),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loadingReplies ? null : onMoreReplies,
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 1.5,
                      color: ProfileTheme.textSecondary(
                        context,
                      ).withValues(alpha: 0.4),
                    ),
                    const Gap(8),
                    if (loadingReplies)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: _likePink,
                        ),
                      )
                    else
                      Text(
                        'View $hidden more repl${hidden == 1 ? 'y' : 'ies'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _likePink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final VideoComment comment;
  final bool isReply;
  final ValueChanged<VideoComment> onLike;
  final ValueChanged<VideoComment> onReply;
  final ValueChanged<VideoComment> onLongPress;

  const _CommentCard({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onLongPress,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = comment;
    final muted = ProfileTheme.textSecondary(context);
    final primary = ProfileTheme.textPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(author: c.user, size: isReply ? 38 : 44),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: c.user.username,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      if (c.user.isVerified)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xff3B82F6),
                            ),
                          ),
                        ),
                      if (c.isCreator)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: _CreatorBadge(),
                          ),
                        ),
                      if (c.createdAt != null)
                        TextSpan(
                          text: '  •  ${_ago(c.createdAt!)}',
                          style: TextStyle(fontSize: 12.5, color: muted),
                        ),
                    ],
                  ),
                ),
                const Gap(5),
                _BodyText(text: c.body, color: primary),
                const Gap(6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onReply(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply_rounded, size: 16, color: muted),
                        const Gap(4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _LikeButton(comment: c, onTap: () => onLike(c)),
        ],
      ),
    );

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.035)
          : ProfileTheme.purple.withValues(alpha: 0.035),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ProfileTheme.hairlineColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () => onLongPress(c),
        child: isReply
            ? DecoratedBox(
                // Pink rail down the left edge of replies.
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: _likePink, width: 3)),
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

class _CreatorBadge extends StatelessWidget {
  const _CreatorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: ProfileTheme.purple.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ProfileTheme.purple.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'Creator',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ProfileTheme.purple,
        ),
      ),
    );
  }
}

/// Comment text with @mentions highlighted in pink.
class _BodyText extends StatelessWidget {
  final String text;
  final Color color;
  const _BodyText({required this.text, required this.color});

  static final _mention = RegExp(r'@[\w.]+');

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14.5, height: 1.4, color: color);
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _mention.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(color: _likePink, fontWeight: FontWeight.w600),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class _LikeButton extends StatelessWidget {
  final VideoComment comment;
  final VoidCallback onTap;
  const _LikeButton({required this.comment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final liked = comment.isLikedByMe;
    final muted = ProfileTheme.textSecondary(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        child: Column(
          children: [
            AnimatedScale(
              scale: liked ? 1.15 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: liked ? _likePink : muted,
              ),
            ),
            const Gap(3),
            if (comment.likesCount > 0)
              Text(
                formatCount(comment.likesCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: liked ? _likePink : muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Profile photo, or the username's initials on a color picked from the
/// username (so each person keeps the same color).
class _Avatar extends StatelessWidget {
  final FeedAuthor author;
  final double size;
  const _Avatar({required this.author, required this.size});

  static const _palettes = [
    [Color(0xff8B5CF6), Color(0xff6366F1)],
    [Color(0xff10B981), Color(0xff059669)],
    [Color(0xffF97316), Color(0xffEC4899)],
    [Color(0xff3B82F6), Color(0xff06B6D4)],
    [Color(0xffEF4444), Color(0xffF59E0B)],
    [Color(0xffEC4899), Color(0xff8B5CF6)],
  ];

  String get _initials {
    final source = author.username.isNotEmpty ? author.username : author.name;
    final parts = source
        .split(RegExp(r'[\s_.\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1
        ? parts[1][0]
        : (parts.first.length > 1 ? parts.first[1] : '');
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final picture = author.profilePicture;
    if (picture != null && picture.trim().isNotEmpty) {
      return ImageUserCircleProfile(
        imageUrl: picture,
        name: author.name,
        size: size,
      );
    }
    final palette =
        _palettes[author.username.hashCode.abs() % _palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CommentSkeleton extends HookWidget {
  const _CommentSkeleton();

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
    final bar = ProfileTheme.purple.withValues(alpha: 0.06 + 0.08 * t);
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bar, shape: BoxShape.circle),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(140, 13),
                const Gap(10),
                block(double.infinity, 12),
                const Gap(6),
                block(180, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentActions extends StatelessWidget {
  final bool isMine;
  const _CommentActions({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy text'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (isMine)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xffEF4444),
                ),
                title: const Text(
                  'Delete comment',
                  style: TextStyle(color: Color(0xffEF4444)),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Composer
// =============================================================================

/// Quick reactions, "Replying to @x" banner, the viewer's avatar, the text
/// field and the gradient send button. Keeps its own text state so typing
/// only rebuilds this widget.
class _Composer extends HookConsumerWidget {
  final FocusNode focusNode;
  final VideoComment? replyTo;
  final bool isPosting;
  final VoidCallback onCancelReply;
  final Future<bool> Function(String text) onSend;

  const _Composer({
    required this.focusNode,
    required this.replyTo,
    required this.isPosting,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctr = useTextEditingController();
    final hasText = useListenableSelector(
      ctr,
      () => ctr.text.trim().isNotEmpty,
    );
    final user = ref.watch(currentUserProvider);
    final muted = ProfileTheme.textSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Starting a reply pre-fills the @mention (like the design's
    // "@dara_travels Yes! …").
    useEffect(() {
      final target = replyTo;
      if (target != null) {
        final mention = '@${target.user.username} ';
        if (!ctr.text.startsWith(mention)) {
          ctr.text = mention + ctr.text;
        }
        ctr.selection = TextSelection.collapsed(offset: ctr.text.length);
      }
      return null;
    }, [replyTo?.id]);

    void insert(String emoji) {
      HapticFeedback.selectionClick();
      final sel = ctr.selection;
      final text = ctr.text;
      final start = sel.isValid ? sel.start : text.length;
      final end = sel.isValid ? sel.end : text.length;
      ctr.value = TextEditingValue(
        text: text.replaceRange(start, end, emoji),
        selection: TextSelection.collapsed(offset: start + emoji.length),
      );
    }

    Future<void> send() async {
      final text = ctr.text;
      if (text.trim().isEmpty || isPosting) return;
      if (await onSend(text)) ctr.clear();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ProfileTheme.hairlineColor(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Quick reaction:',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const Spacer(),
                  for (final e in _quickReactions)
                    GestureDetector(
                      onTap: () => insert(e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(e, style: const TextStyle(fontSize: 21)),
                      ),
                    ),
                ],
              ),
              if (replyTo != null) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: _likePink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: _likePink,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Replying to ',
                            style: TextStyle(fontSize: 12.5, color: muted),
                            children: [
                              TextSpan(
                                text: '@${replyTo!.user.username}',
                                style: const TextStyle(
                                  color: _likePink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final mention = '@${replyTo!.user.username} ';
                          if (ctr.text.startsWith(mention)) {
                            ctr.text = ctr.text.substring(mention.length);
                          }
                          onCancelReply();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ProfileTheme.pinkPurple,
                    ),
                    child: user == null
                        ? CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            child: Icon(Icons.person_rounded, color: muted),
                          )
                        : ImageUserCircleProfile(
                            imageUrl: user.profilePicture,
                            name: user.name,
                            size: 36,
                          ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: ctr,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      onTapOutside: (_) => focusNode.unfocus(),
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: ProfileTheme.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: replyTo == null
                            ? 'Add a comment...'
                            : 'Write a reply...',
                        hintStyle: TextStyle(color: muted),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : ProfileTheme.purple.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: ProfileTheme.hairlineColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: ProfileTheme.hairlineColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _likePink),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  GestureDetector(
                    onTap: send,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: hasText || isPosting ? 1 : 0.5,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ProfileTheme.pinkPurple,
                        ),
                        child: isPosting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "just now", "5 min ago", "3 h ago", "2 d ago", then a date.
String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  final local = time.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
