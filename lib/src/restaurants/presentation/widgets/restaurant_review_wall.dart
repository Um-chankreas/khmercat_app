import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/profile/profile_empty_tab_body.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/providers/feed_providers.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_review.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_reviews_controller.dart';

const _star = Color(0xffF5B400);
const _crimson = Color(0xffB0125A);

/// The Reviews tab: rating summary with a 5→1 breakdown, "Write a review",
/// All / With video filter and the reviews, newest first. The parent's
/// scroll view asks for more pages via [RestaurantReviewsController.loadMore].
class RestaurantReviewWall extends ConsumerWidget {
  final String restaurantId;

  /// Shown on the restaurant's replies ("Reply from …").
  final String restaurantName;

  /// The restaurant's team: may reply to reviews, and can't write one.
  final bool isTeam;
  final VoidCallback onWrite;

  const RestaurantReviewWall({
    required this.restaurantId,
    required this.restaurantName,
    required this.isTeam,
    required this.onWrite,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(restaurantReviewsControllerProvider(restaurantId));
    final controller = ref.read(
      restaurantReviewsControllerProvider(restaurantId).notifier,
    );

    if (state.isLoading && state.reviews.isEmpty && state.summary.total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (state.failed && state.reviews.isEmpty) {
      return _Retry(onRetry: controller.reload);
    }
    if (state.summary.total == 0) {
      return Column(
        children: [
          ProfileEmptyTabBody(
            asset: AssetsName.comment,
            title: l.noReviewersYet,
            message: isTeam ? l.reviewsEmptyTeam : l.reviewsEmptyVisitor,
          ),
          if (!isTeam)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _WriteButton(label: l.writeReview, onTap: onWrite),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(summary: state.summary),
          if (!isTeam) ...[
            const Gap(18),
            _WriteButton(
              label: state.myReview == null ? l.writeReview : l.editYourReview,
              onTap: onWrite,
            ),
          ],
          const Gap(16),
          Row(
            children: [
              _FilterChip(
                label: l.filterAll(state.summary.total),
                selected: !state.withVideoOnly,
                onTap: () => controller.setWithVideoOnly(false),
              ),
              const Gap(8),
              _FilterChip(
                label: l.filterWithVideo(state.withVideoCount),
                icon: Icons.play_arrow_rounded,
                selected: state.withVideoOnly,
                onTap: () => controller.setWithVideoOnly(true),
              ),
            ],
          ),
          const Gap(6),
          if (state.isLoading && state.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            )
          else if (state.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Text(
                l.noVideoReviewsYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
            ),
          for (final r in state.reviews)
            _ReviewTile(
              key: ValueKey(r.id),
              review: r,
              restaurantName: restaurantName,
              canReply: isTeam,
              onLike: () async {
                if (await requireLogin(
                  context,
                  ref,
                  message: l.signInToLikeReviews,
                )) {
                  controller.toggleLike(r);
                }
              },
              onReply: () => _showReplySheet(context, controller, r),
            ),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const StarRow({required this.rating, this.size = 14, super.key});

  @override
  Widget build(BuildContext context) {
    final off = ProfileTheme.textSecondary(context).withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i <= rating ? _star : off,
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final ReviewSummary summary;
  const _Summary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final total = summary.total;
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(4),
              StarRow(rating: summary.average.round(), size: 14),
              const Gap(4),
              Text(
                AppLocalizations.of(context).ratingsCount(total),
                style: TextStyle(fontSize: 12.5, color: muted),
              ),
            ],
          ),
        ),
        const Gap(20),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                _BarRow(
                  star: star,
                  count: summary.counts[star] ?? 0,
                  max: summary.maxCount,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final int star;
  final int count;
  final int max;
  const _BarRow({required this.star, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$star',
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ),
          const Gap(6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  Container(height: 5, color: muted.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: max == 0 ? 0 : count / max,
                    child: Container(height: 5, color: _star),
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

class _WriteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WriteButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: ProfileTheme.brandGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 18, color: ProfileTheme.ink),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final fg = selected ? ProfileTheme.ink : primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: selected ? ProfileTheme.brandGradient : null,
          color: selected
              ? null
              : ProfileTheme.textSecondary(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const Gap(4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RestaurantReview review;
  final String restaurantName;
  final bool canReply;
  final VoidCallback onLike;
  final VoidCallback onReply;
  const _ReviewTile({
    required this.review,
    required this.restaurantName,
    required this.canReply,
    required this.onLike,
    required this.onReply,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = review;
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(author: r.user),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                    Text(
                      _shortAgo(AppLocalizations.of(context), r.createdAt),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
                const Gap(2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: _star),
                    const Gap(3),
                    Text(
                      r.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                if (r.comment.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    r.comment,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: primary,
                    ),
                  ),
                ],
                if (r.video != null) ...[
                  const Gap(10),
                  _VideoThumb(video: r.video!),
                ],
                const Gap(8),
                Row(
                  children: [
                    _Action(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            r.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: r.likedByMe ? ProfileTheme.pink : muted,
                          ),
                          const Gap(5),
                          Text(
                            formatCount(r.likesCount),
                            style: TextStyle(fontSize: 12.5, color: muted),
                          ),
                        ],
                      ),
                    ),
                    if (canReply) ...[
                      const Gap(18),
                      _Action(
                        onTap: onReply,
                        child: Text(
                          r.reply == null
                              ? AppLocalizations.of(context).replyAction
                              : AppLocalizations.of(context).editReply,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (r.reply != null) ...[
                  const Gap(10),
                  _ReplyBox(restaurantName: restaurantName, reply: r.reply!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "2d", "5d", "1w" — compact, like the rest of the review row.
  static String _shortAgo(AppLocalizations l, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l.adminNow;
    if (diff.inHours < 1) return l.agoShortMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l.agoShortHours(diff.inHours);
    if (diff.inDays < 7) return l.agoShortDays(diff.inDays);
    if (diff.inDays < 30) return l.agoShortWeeks(diff.inDays ~/ 7);
    if (diff.inDays < 365) return l.agoShortMonths(diff.inDays ~/ 30);
    return l.agoShortYears(diff.inDays ~/ 365);
  }
}

class _Action extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Action({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    ),
  );
}

class _Avatar extends StatelessWidget {
  final ReviewAuthor author;
  const _Avatar({required this.author});

  @override
  Widget build(BuildContext context) {
    final url = author.profilePicture;
    final initial = author.name.isEmpty
        ? '?'
        : author.name.characters.first.toUpperCase();
    return GestureDetector(
      onTap: author.username == null
          ? null
          : () => AppRouter.router.pushNamed(
              AppRoute.userProfile.name,
              pathParameters: {'username': author.username!},
            ),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ProfileTheme.textSecondary(context).withValues(alpha: 0.10),
        ),
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
            : Text(
                initial,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
      ),
    );
  }
}

/// Portrait thumbnail; tapping plays the review video full screen.
class _VideoThumb extends HookConsumerWidget {
  final ReviewVideo video;
  const _VideoThumb({required this.video});

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opening = useState(false);
    final unavailable = AppLocalizations.of(context).videoUnavailable;

    Future<void> open() async {
      if (opening.value) return;
      opening.value = true;
      try {
        final item = await ref.read(feedRepositoryProvider).getVideo(video.id);
        AppRouter.router.pushNamed(
          AppRoute.videoViewer.name,
          pathParameters: {'id': item.id},
          extra: item,
        );
      } catch (_) {
        AppService.showToast(unavailable, isError: true);
      } finally {
        if (context.mounted) opening.value = false;
      }
    }

    final url = video.thumbnailUrl;
    return GestureDetector(
      onTap: open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 96,
          height: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url == null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ProfileTheme.coverFallback,
                  ),
                )
              else
                CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                  ),
                  child: opening.value
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
              if (video.duration != null)
                Positioned(
                  left: 6,
                  bottom: 5,
                  child: Text(
                    _clock(video.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyBox extends StatelessWidget {
  final String restaurantName;
  final ReviewReply reply;
  const _ReplyBox({required this.restaurantName, required this.reply});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ProfileTheme.textSecondary(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).replyFrom(restaurantName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _crimson,
            ),
          ),
          const Gap(4),
          Text(
            reply.text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Text(
          AppLocalizations.of(context).reviewsLoadFailed,
          style: TextStyle(color: ProfileTheme.textSecondary(context)),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).tryAgain),
        ),
      ],
    ),
  );
}

/// The team writes, edits or removes the restaurant's reply to a review.
Future<void> _showReplySheet(
  BuildContext context,
  RestaurantReviewsController controller,
  RestaurantReview review,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReplySheet(controller: controller, review: review),
  );
}

class _ReplySheet extends HookWidget {
  final RestaurantReviewsController controller;
  final RestaurantReview review;
  const _ReplySheet({required this.controller, required this.review});

  @override
  Widget build(BuildContext context) {
    final text = useTextEditingController(text: review.reply?.text ?? '');
    useListenable(text);
    final busy = useState(false);
    final l = AppLocalizations.of(context);

    Future<void> run(Future<void> Function() action, String done) async {
      busy.value = true;
      try {
        await action();
        if (context.mounted) Navigator.pop(context);
        AppService.showToast(done);
      } catch (_) {
        AppService.showToast(l.accountActionFailed, isError: true);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.replyTo(review.user.name),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          const Gap(12),
          TextField(
            controller: text,
            autofocus: true,
            maxLength: 500,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.replyHint),
          ),
          const Gap(8),
          Row(
            children: [
              if (review.reply != null)
                TextButton(
                  onPressed: busy.value
                      ? null
                      : () => run(
                          () => controller.deleteReply(review),
                          l.replyRemoved,
                        ),
                  child: Text(
                    l.removeAction,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: busy.value || text.text.trim().isEmpty
                    ? null
                    : () => run(
                        () => controller.reply(review, text.text.trim()),
                        l.replyPosted,
                      ),
                child: Text(
                  review.reply == null ? l.replyAction : l.saveAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
