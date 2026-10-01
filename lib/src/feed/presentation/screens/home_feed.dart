import 'dart:io';

// lib/features/feed/presentation/screens/home_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart'
    show AppRouter, routeObserver;
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/video_upload/domain/video_upload_state.dart';
import 'package:khmer_cat_app/src/video_upload/presentation/video_upload_viewmodel.dart';
import '../../domain/feed_tab.dart';
import '../../providers/feed_providers.dart';
import '../viewmodel/feed_controller.dart';
import '../widgets/feed_action_rail.dart';
import '../widgets/feed_info_overlay.dart';
import '../widgets/feed_top_tabs.dart';
import '../widgets/feed_video_page.dart';
import '../widgets/share_video.dart';
import '../widgets/video_controller_manager.dart';
import 'comments_sheet.dart';

/// PageView's default snap-back spring (stiffness: 100) settles slowly
/// enough after you release a swipe that short-form feeds feel "soft"
/// compared to TikTok/Reels — the drag itself already tracks the finger
/// 1:1, so the difference people notice is specifically how fast the page
/// snaps into place once you let go. A stiffer, still-critically-damped
/// spring makes that snap read as an instant catch instead of a settle.
class _SnappyPageScrollPhysics extends PageScrollPhysics {
  const _SnappyPageScrollPhysics({super.parent});

  @override
  _SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 400, ratio: 1.1);
}

class HomeFeed extends StatefulWidget {
  final bool isTabActive;
  const HomeFeed({this.isTabActive = true, super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed>
    with RouteAware, WidgetsBindingObserver {
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Whether the feed is covered is read from the route itself in build(),
  // not tracked from these callbacks: go_router *removes* routes on go()
  // (e.g. posting a video: upload -> camera -> goNamed(index)), and a
  // removal never calls didPopNext — so a flag set here stayed "covered"
  // and the feed never loaded another video. These just force a rebuild.
  @override
  void didPushNext() => setState(() {});

  @override
  void didPopNext() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _appInForeground = state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    // True only while nothing is pushed on top of this route. Flutter
    // rebuilds this widget whenever that changes, removals included.
    final isTopRoute = ModalRoute.isCurrentOf(context) ?? true;
    return _HomeFeedContent(
      isActive: widget.isTabActive && isTopRoute && _appInForeground,
    );
  }
}

class _HomeFeedContent extends HookConsumerWidget {
  final bool isActive;
  const _HomeFeedContent({required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialIndex = tabOrder.indexOf(FeedTab.forYou);
    final tabPageController = usePageController(initialPage: initialIndex);
    final tabController = useTabController(
      initialLength: tabOrder.length,
      initialIndex: initialIndex,
    );
    // Rebuild whenever the controller's index/animation changes so
    // `tabController.index` below stays live, the same role the old
    // `currentTabIndex` useState played.
    useListenable(tabController);

    // Two-way sync between the TabBar's controller and the feed's own
    // PageView (kept separate from TabBarView so vertical swiping through
    // videos stays a plain PageView — see _TabFeedView).
    //  - Tap a tab -> TabBar calls tabController.animateTo() internally,
    //    which sets indexIsChanging true for the animation's duration; the
    //    listener below catches that and drives the PageView to match.
    //  - Swipe the PageView -> onOuterPageChanged sets tabController.index
    //    directly (no `duration`), which updates the index and repaints the
    //    indicator without animating and without setting indexIsChanging —
    //    so it does NOT re-trigger the listener below. No feedback loop.
    useEffect(() {
      void listener() {
        if (tabController.indexIsChanging) {
          tabPageController.animateToPage(
            tabController.index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController, tabPageController]);

    void onOuterPageChanged(int index) {
      if (tabController.index == index) return;
      tabController.index = index;
    }

    void tapTab(FeedTab tab) {
      tabController.animateTo(tabOrder.indexOf(tab));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: tabPageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: onOuterPageChanged,
              allowImplicitScrolling: true,
              itemCount: tabOrder.length,
              itemBuilder: (context, index) {
                final tab = tabOrder[index];
                return _TabFeedView(
                  tab: tab,
                  isVisible: isActive && tabController.index == index,
                  onDiscover: () => tapTab(FeedTab.forYou),
                );
              },
            ),
            // Faint fade (not a box) so the white tab text stays readable
            // over bright videos.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top + 56,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FeedTopTabs(controller: tabController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab's full vertical video feed. Lives permanently inside the outer
/// horizontal PageView (so swiping back to it doesn't rebuild it from
/// scratch mid-gesture) but only plays video while [isVisible] — i.e. while
/// its tab is the one currently on screen.
class _TabFeedView extends HookConsumerWidget {
  final FeedTab tab;
  final bool isVisible;
  final VoidCallback onDiscover;

  const _TabFeedView({
    required this.tab,
    required this.isVisible,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = useState(0);
    final pageController = usePageController();

    final state = ref.watch(feedControllerProvider(tab));
    final controller = ref.read(feedControllerProvider(tab).notifier);

    // Prefetches current ± 1 so the next/previous video is already
    // buffering by the time the user swipes to it. All hooks must run
    // unconditionally before the early returns below, so this stays here
    // even though it has nothing to do while state.items is empty.
    final videoManager = useMemoized(() => VideoControllerManager(), [tab]);
    useEffect(() => videoManager.dispose, [videoManager]);
    useListenable(videoManager);
    // Ids around the current page, so swapping a pending upload for the
    // server's video (same list length) still reloads its player.
    final windowKey = [
      for (var i = currentPage.value - 1; i <= currentPage.value + 1; i++)
        if (i >= 0 && i < state.items.length) state.items[i].id,
    ].join(',');
    useEffect(() {
      videoManager.syncWindow(
        state.items,
        currentPage.value,
        tabIsVisible: isVisible,
      );
      return null;
    }, [currentPage.value, isVisible, state.items.length, windowKey]);

    // The user just posted a video — jump to it at the top of the feed.
    final firstPendingId = state.items.isNotEmpty && state.items.first.isPending
        ? state.items.first.id
        : null;
    useEffect(() {
      if (firstPendingId != null && currentPage.value != 0) {
        currentPage.value = 0;
        if (pageController.hasClients) pageController.jumpToPage(0);
      }
      return null;
    }, [firstPendingId]);

    // One view per video the user actually lands on while this tab is shown.
    final visibleVideoId =
        isVisible &&
            currentPage.value < state.items.length &&
            !state.items[currentPage.value].isPending
        ? state.items[currentPage.value].id
        : null;
    useEffect(() {
      if (visibleVideoId != null) {
        ref.read(feedRepositoryProvider).recordView(visibleVideoId);
      }
      return null;
    }, [visibleVideoId]);

    Future<void> handleLike(String videoId) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to like videos',
      )) {
        return;
      }
      controller.toggleLike(videoId);
    }

    Future<void> handleSave(String videoId) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to save videos',
      )) {
        return;
      }
      controller.toggleSave(videoId);
    }

    Future<void> handleFollow(String videoId) async {
      if (!await requireLogin(
        context,
        ref,
        message: 'Sign in to follow this account',
      )) {
        return;
      }
      controller.toggleFollowRestaurant(videoId);
    }

    // Returns the sheet's future so the comment button stays highlighted for
    // as long as the sheet is open.
    Future<void> handleComment(String videoId) {
      return showCommentsSheet(
        context,
        videoId: videoId,
        onCountChanged: (delta) =>
            controller.incrementCommentCount(videoId, delta),
      );
    }

    if (state.requiresAuth) {
      return _SignInToSeeFollowing();
    }

    if (state.isInitialLoading) {
      return const _FeedLoading();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return _FeedMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn\'t load videos',
        message: state.errorMessage!,
        buttonText: 'Try again',
        buttonIcon: Icons.refresh_rounded,
        onButton: controller.refresh,
      );
    }

    if (state.items.isEmpty) {
      return tab == FeedTab.forYou
          ? _FeedMessage(
              icon: Icons.videocam_off_rounded,
              title: 'No videos yet',
              message: 'Nothing here right now — check back soon.',
              buttonText: 'Refresh',
              buttonIcon: Icons.refresh_rounded,
              onButton: controller.refresh,
            )
          : _FeedMessage(
              icon: Icons.group_add_rounded,
              title: 'Start following creators',
              message:
                  'Follow restaurants and creators to see their videos here.',
              buttonText: 'Discover videos',
              buttonIcon: Icons.explore_rounded,
              onButton: onDiscover,
            );
    }

    final videoCount = state.items.length;

    // Once the server says there's nothing more, one extra page closes the
    // feed with a friendly "all caught up" instead of just stopping.
    final showEnd = !state.hasMore;

    Future<void> onRefresh() async {
      await controller.refresh(keepItems: true);
      if (pageController.hasClients) pageController.jumpToPage(0);
      currentPage.value = 0;
    }

    // PageView defaults to a 0px cache extent (nothing beyond the viewport
    // is built/painted ahead of time) unless allowImplicitScrolling is set,
    // in which case it builds a full extra viewport on each side. Without
    // it, the next/previous full-screen video page only gets built once the
    // swipe drag actually reveals it, which is what made the swipe itself
    // feel like it was popping content in instead of being smooth. The
    // video itself is already buffered this far ahead by
    // VideoControllerManager (current ± 1); this matches the page's own
    // build/paint window to that same range.
    final feed = RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xff9B6BFF),
      backgroundColor: Colors.white,
      edgeOffset: MediaQuery.paddingOf(context).top + 64,
      child: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        physics: const _SnappyPageScrollPhysics(),
        allowImplicitScrolling: true,
        itemCount: videoCount + (showEnd ? 1 : 0),
        onPageChanged: (page) {
          currentPage.value = page;
          if (page >= videoCount - 2) controller.loadMore();
        },
        itemBuilder: (context, index) {
          if (index >= videoCount) {
            return _EndOfFeed(
              onBackToTop: () => pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              ),
            );
          }
          final item = state.items[index];

          // Each page gets its own compositing layer so a swipe transition
          // doesn't force neighboring pages' video textures to repaint, and
          // the video texture itself is isolated from the overlay (gradient,
          // action rail, caption) so the two don't repaint each other on
          // every frame.
          return RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: FeedVideoPage(
                    item: item,
                    controller: videoManager.controllerFor(item.id),
                    failed: videoManager.hasFailed(item.id),
                    onRetry: () => videoManager.retry(item),
                    onDoubleTapLike: () {
                      if (!item.likedByMe) handleLike(item.id);
                    },
                  ),
                ),

                // Bottom scrim, tinted deep purple so the overlay text and
                // action rail stay readable and match the brand.
                IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xC01F1B3A)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 12,
                  bottom: context.sc(50),
                  child: IgnorePointer(
                    ignoring: item.isPending,
                    child: Opacity(
                      opacity: item.isPending ? 0.4 : 1,
                      child: FeedActionRail(
                        item: item,
                        onLike: () => handleLike(item.id),
                        onComment: () => handleComment(item.id),
                        onSave: () => handleSave(item.id),
                        onShare: () => shareVideo(item),
                        onFollowTap: () => handleFollow(item.id),
                        onAvatarTap: () => AppRouter.router.pushNamed(
                          AppRoute.userProfile.name,
                          pathParameters: {'username': item.user.username},
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: context.sc(14),
                  right: 90,
                  bottom: context.sc(14),
                  child: FeedInfoOverlay(
                    item: item,
                    onFollowTap: () => handleFollow(item.id),
                    onUserTap: () => AppRouter.router.pushNamed(
                      AppRoute.userProfile.name,
                      pathParameters: {'username': item.user.username},
                    ),
                    onRestaurantTap: item.restaurant == null
                        ? null
                        : () => AppRouter.router.pushNamed(
                            AppRoute.restaurantProfile.name,
                            pathParameters: {'id': item.restaurant!.id},
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // TikTok-style: loading the next page is just a small spinner at the
    // bottom edge, in the gap under the info card — nothing over the video.
    final pending = state.items.where((v) => v.isPending).firstOrNull;
    return Stack(
      children: [
        feed,
        // TikTok-style: your post's thumbnail with its progress, top-left,
        // over whichever video you're watching. Tap to jump to it.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: pending == null
                ? const SizedBox.shrink()
                : _PostingIndicator(
                    key: ValueKey(pending.id),
                    thumbnailPath: pending.localThumbnailPath,
                    onTap: () {
                      if (!pageController.hasClients) return;
                      pageController.animateToPage(
                        state.items.indexOf(pending),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.sc(14),
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoadingMore
                  ? const Center(child: _LoadingMoreSpinner())
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _blue = Color(0xff74BFFF);

const _brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_pink, _purple, _blue],
);

/// Deep-purple → black backdrop shared by the full-screen states.
class _StateBackdrop extends StatelessWidget {
  final Widget child;
  const _StateBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff2A1F4D), Color(0xff0E0B1F)],
        ),
      ),
      child: Center(
        child: Padding(padding: const EdgeInsets.all(28), child: child),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        decoration: BoxDecoration(
          gradient: _brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _pink.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: Colors.white),
            const Gap(8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon in a gradient-tinted circle, title, message and an optional button.
class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final IconData buttonIcon;
  final VoidCallback? onButton;

  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.buttonIcon = Icons.arrow_forward_rounded,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return _StateBackdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _pink.withValues(alpha: 0.28),
                    _blue.withValues(alpha: 0.28),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: ShaderMask(
                shaderCallback: (r) => _brandGradient.createShader(r),
                child: Icon(icon, size: 46, color: Colors.white),
              ),
            ),
          ),
          const Gap(22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Gap(8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (buttonText != null && onButton != null) ...[
            const Gap(24),
            _GradientButton(
              text: buttonText!,
              icon: buttonIcon,
              onTap: onButton!,
            ),
          ],
        ],
      ),
    );
  }
}

class _SignInToSeeFollowing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _FeedMessage(
      icon: Icons.people_alt_rounded,
      title: 'Sign in to see who you follow',
      message: 'Videos from restaurants and people you follow show up here.',
      buttonText: 'Sign in',
      buttonIcon: Icons.login_rounded,
      onButton: () => AppRouter.router.pushNamed(AppRoute.login.name),
    );
  }
}

/// Full-screen first load: pulsing brand ring instead of a bare spinner.
class _FeedLoading extends HookWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    final t = useAnimation(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );

    return _StateBackdrop(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.92 + 0.12 * t,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.4 + 0.3 * t),
                    blurRadius: 22 + 10 * t,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xff14102B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Gap(20),
          const Text(
            'Finding delicious videos…',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Your post while it's on its way: a small thumbnail with a progress ring
/// and percentage while compressing (first half) and uploading (second
/// half), then a spinning ring while the server finishes processing it.
class _PostingIndicator extends ConsumerWidget {
  final String? thumbnailPath;
  final VoidCallback onTap;
  const _PostingIndicator({
    required this.thumbnailPath,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = ref.watch(videoUploadViewModelProvider);
    final double? progress = switch (upload.stage) {
      UploadStage.compressing => upload.compressionProgress * 0.5,
      UploadStage.uploading => 0.5 + upload.uploadProgress * 0.5,
      // Uploaded; the server is still processing it.
      _ => null,
    };
    final thumb = thumbnailPath;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.file(File(thumb), fit: BoxFit.cover)
              else
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: _brandGradient),
                ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
              Center(
                child: SizedBox.square(
                  dimension: 26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.2,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                      if (progress != null)
                        Text(
                          '${(progress * 100).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
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

/// Small white spinner with a soft shadow, so it reads on light videos too.
class _LoadingMoreSpinner extends StatelessWidget {
  const _LoadingMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 1.8,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

/// Last page once the feed is exhausted.
class _EndOfFeed extends StatelessWidget {
  final VoidCallback onBackToTop;
  const _EndOfFeed({required this.onBackToTop});

  @override
  Widget build(BuildContext context) {
    return _FeedMessage(
      icon: Icons.check_circle_rounded,
      title: 'No more videos',
      message: 'You\'re all caught up. Check back later for new videos.',
      buttonText: 'Back to top',
      buttonIcon: Icons.arrow_upward_rounded,
      onButton: onBackToTop,
    );
  }
}
