import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/rating/star_rating_input.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_logo.dart';
import 'package:video_player/video_player.dart';
import 'widgets/upload_target_sheet.dart';
import 'video_upload_viewmodel.dart';
import '../domain/video_upload_state.dart';

const _maxTitleLength = 500;

/// Pink → purple → blue palette used across this screen.
abstract class _Brand {
  static const pink = Color(0xffFF54AB);
  static const purple = Color(0xff9B6BFF);
  static const blue = Color(0xff74BFFF);
  static const ink = Color(0xff1F1B3A);
  static const muted = Color(0xff7A7896);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, purple, blue],
  );
  static const pinkPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, purple],
  );
  static const purpleBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue],
  );
  static const pinkBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, blue],
  );

  /// Soft shadow so white cards lift off the white background.
  static List<BoxShadow> cardShadow() => [
    BoxShadow(
      color: const Color(0xff3B1C7A).withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> softShadow(Color c, {double alpha = 0.14}) => [
    BoxShadow(
      color: c.withValues(alpha: alpha),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

const _suggestedHashtags = [
  'khmerfood',
  'foodreview',
  'phnompenh',
  'delicious',
  'restaurant',
];

class VideoUploadScreen extends HookConsumerWidget {
  final File? initialVideoFile;

  const VideoUploadScreen({this.initialVideoFile, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoUploadViewModelProvider);
    final vm = ref.read(videoUploadViewModelProvider.notifier);

    final titleCtr = useTextEditingController();

    final hashtags = useState<List<String>>([]);
    final tagInputCtr = useTextEditingController();
    final tagInputFocus = useFocusNode();
    final isAddingTag = useState(false);

    // When the user is acting as a restaurant, post as it by default.
    final activeRestaurant = ref.watch(activeRestaurantProvider);
    final selectedTarget = useState<UploadTargetSelection?>(
      activeRestaurant == null
          ? null
          : (mode: UploadMode.restaurantPost, restaurant: activeRestaurant),
    );
    final rating = useState(0);

    useEffect(() {
      if (initialVideoFile != null) {
        Future.microtask(() => vm.setPickedFile(initialVideoFile!));
      }
      return null;
    }, [initialVideoFile]);

    // The restaurants list may still be loading on first build — pre-select
    // the active restaurant once it arrives, unless the user already picked.
    useEffect(() {
      if (activeRestaurant != null) {
        Future.microtask(() {
          selectedTarget.value ??= (
            mode: UploadMode.restaurantPost,
            restaurant: activeRestaurant,
          );
        });
      }
      return null;
    }, [activeRestaurant?.id]);

    final isProcessing =
        state.stage == UploadStage.compressing ||
        state.stage == UploadStage.uploading;

    void addTag(String raw) {
      final tag = raw.trim().replaceAll('#', '').replaceAll(RegExp(r'\s+'), '');
      if (tag.isNotEmpty && !hashtags.value.contains(tag)) {
        hashtags.value = [...hashtags.value, tag];
      }
      tagInputCtr.clear();
    }

    void removeTag(String tag) {
      hashtags.value = hashtags.value.where((t) => t != tag).toList();
    }

    // Title + hashtags are two separate inputs but the backend takes a single
    // `caption` field, so they're combined on send (title, blank line, tags).
    String buildCaption() {
      final title = titleCtr.text.trim();
      final tags = hashtags.value.map((t) => '#$t').join(' ');
      return [
        if (title.isNotEmpty) title,
        if (tags.isNotEmpty) tags,
      ].join('\n\n');
    }

    Future<void> pickTarget() async {
      final picked = await showUploadTargetSheet(context);
      if (picked != null) selectedTarget.value = picked;
    }

    void handleUpload() {
      final target = selectedTarget.value;
      // Kick off the upload and immediately leave — compression + upload run
      // in the background and progress is shown on the bottom-nav create
      // button (see IndexScreen / AppBottomNavBar).
      vm.compressAndUpload(
        caption: buildCaption(),
        postAsRestaurant: target?.mode == UploadMode.restaurantPost,
        restaurantId: target?.restaurant.id,
        restaurant: target?.restaurant,
        rating: target?.mode == UploadMode.restaurantPost ? null : rating.value,
      );
      // This screen was pushed imperatively (Navigator.push) on top of the
      // camera route, so go_router alone can't dismiss it — pop it first,
      // then return to the feed.
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
      AppRouter.router.goNamed(AppRoute.index.name);
    }

    final canPost =
        state.originalPath != null &&
        selectedTarget.value != null &&
        (selectedTarget.value!.mode == UploadMode.restaurantPost ||
            rating.value > 0) &&
        !isProcessing;

    return GestureDetector(
      onTap: () => AppService.dismissKeyboard(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.white,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Center(
              child: _BackButton(
                onTap: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                },
              ),
            ),
            title: const Text(
              'New Post',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
                color: _Brand.ink,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _VideoPreviewCard(
                          path: state.originalPath,
                          onChange: vm.pickVideo,
                        ),

                        const Gap(14),

                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionHeader(
                                icon: Icons.edit_rounded,
                                gradient: _Brand.pinkPurple,
                                title: 'Caption',
                                subtitle: 'Tell people what this is about',
                              ),
                              const Gap(14),
                              TextField(
                                controller: titleCtr,
                                maxLength: _maxTitleLength,
                                maxLines: null,
                                minLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 1.4,
                                  color: _Brand.ink,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Write a caption...',
                                  hintStyle: TextStyle(
                                    color: _Brand.muted.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  counterStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: _Brand.muted.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(14),

                        // ---- Hashtags ------------------------------------
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: _SectionHeader(
                                      icon: Icons.tag_rounded,
                                      gradient: _Brand.purpleBlue,
                                      title: 'Hashtags',
                                      subtitle:
                                          'Help people discover your post',
                                    ),
                                  ),
                                  _CircleIconButton(
                                    icon: Icons.add,
                                    onTap: () {
                                      isAddingTag.value = true;
                                      tagInputFocus.requestFocus();
                                    },
                                  ),
                                ],
                              ),
                              if (isAddingTag.value) ...[
                                const Gap(12),
                                TextField(
                                  controller: tagInputCtr,
                                  focusNode: tagInputFocus,
                                  autofocus: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: addTag,
                                  decoration: InputDecoration(
                                    hintText: 'Add a hashtag...',
                                    prefixIcon: const Icon(
                                      Icons.tag_rounded,
                                      size: 18,
                                      color: _Brand.purple,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_rounded,
                                        color: _Brand.purple,
                                      ),
                                      onPressed: () => addTag(tagInputCtr.text),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ],
                              if (hashtags.value.isNotEmpty) ...[
                                const Gap(12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: hashtags.value
                                      .map(
                                        (tag) => _HashtagChip(
                                          label: tag,
                                          onRemove: () => removeTag(tag),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              Builder(
                                builder: (context) {
                                  final suggestions = _suggestedHashtags
                                      .where((t) => !hashtags.value.contains(t))
                                      .toList();
                                  if (suggestions.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Suggested',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _Brand.muted,
                                          ),
                                        ),
                                        const Gap(8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: suggestions
                                                  .map(
                                                    (tag) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: _SuggestedChip(
                                                        label: tag,
                                                        onTap: () =>
                                                            addTag(tag),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const Gap(14),

                        // ---- Restaurant ------------------------------------
                        InkWell(
                          onTap: pickTarget,
                          borderRadius: BorderRadius.circular(24),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: _Card(
                            highlight: selectedTarget.value != null,
                            child: Row(
                              children: [
                                selectedTarget.value != null
                                    ? RestaurantLogo(
                                        restaurant:
                                            selectedTarget.value!.restaurant,
                                        size: 34,
                                        borderRadius: 12,
                                      )
                                    : const _IconBadge(
                                        icon: Icons.storefront_rounded,
                                        gradient: _Brand.pinkBlue,
                                      ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedTarget.value == null
                                            ? 'Select restaurant'
                                            : selectedTarget.value!.mode ==
                                                  UploadMode.restaurantPost
                                            ? 'Posting as ${selectedTarget.value!.restaurant.name}'
                                            : 'Reviewing ${selectedTarget.value!.restaurant.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: _Brand.ink,
                                        ),
                                      ),
                                      const Gap(2),
                                      const Text(
                                        'Tag where this was taken or created',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: _Brand.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _Brand.purple.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: _Brand.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ---- Rating (reviews only) -------------------------
                        if (selectedTarget.value != null &&
                            selectedTarget.value!.mode !=
                                UploadMode.restaurantPost) ...[
                          const Gap(14),
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionHeader(
                                  icon: Icons.star_rounded,
                                  gradient: LinearGradient(
                                    colors: [Color(0xffFFB800), _Brand.pink],
                                  ),
                                  title: 'Your rating',
                                  subtitle: 'How was your experience?',
                                ),
                                const Gap(16),
                                Center(
                                  child: StarRatingInput(
                                    value: rating.value,
                                    onChanged: (v) => rating.value = v,
                                    enabled: !isProcessing,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (isProcessing) ...[
                          const Gap(14),
                          _Card(child: _ProgressSection(state: state)),
                        ],

                        if (state.stage == UploadStage.error) ...[
                          const Gap(14),
                          _ErrorBanner(
                            message: state.errorMessage ?? 'Upload failed',
                          ),
                        ],

                        if (state.stage == UploadStage.success) ...[
                          const Gap(14),
                          _SuccessBanner(status: state.uploadedVideoStatus),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomAction(
                  state: state,
                  canPost: canPost,
                  onUpload: handleUpload,
                  onReset: vm.reset,
                  onDone: () => AppRouter.router.pushReplacementNamed(
                    AppRoute.index.name,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Back button — our standard circular white button + back arrow asset, same
// as the auth screens (login/register/OTP).
// =============================================================================

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _Brand.cardShadow(),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Image.asset(AssetsName.back),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared card / chip pieces
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;

  /// Draws a soft pink→purple→blue outline (used for a completed step).
  final bool highlight;
  const _Card({required this.child, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(highlight ? 22.5 : 24),
        border: highlight
            ? null
            : Border.all(color: _Brand.purple.withValues(alpha: 0.10)),
      ),
      child: child,
    );
    return Container(
      padding: highlight ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: highlight ? _Brand.gradient : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _Brand.cardShadow(),
      ),
      child: inner,
    );
  }
}

/// Gradient icon badge + title/subtitle, used at the top of each card.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(icon: icon, gradient: gradient),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  letterSpacing: -0.2,
                  color: _Brand.ink,
                ),
              ),
              const Gap(1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: _Brand.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  const _IconBadge({required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _Brand.softShadow(_Brand.purple, alpha: 0.10),
      ),
      child: Icon(icon, size: 21, color: Colors.white),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Brand.purple.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: _Brand.purple),
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _HashtagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 9, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _Brand.pink.withValues(alpha: 0.12),
            _Brand.purple.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: _Brand.purple.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xff6B4EFF),
            ),
          ),
          const Gap(6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xff6B4EFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestedChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _Brand.blue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 14, color: _Brand.blue),
            const Gap(3),
            Text(
              '#$label',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xff3E8FE0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Video preview
// =============================================================================

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Hero preview at the top of the form: tap to play/pause, scrub, mute,
/// expand to full screen, or swap the video.
class _VideoPreviewCard extends HookWidget {
  final String? path;
  final VoidCallback onChange;
  const _VideoPreviewCard({required this.path, required this.onChange});

  static const double _height = 320;

  @override
  Widget build(BuildContext context) {
    final controller = useState<VideoPlayerController?>(null);
    final ready = useState(false);
    final muted = useState(false);

    useEffect(() {
      ready.value = false;
      if (path == null) {
        controller.value = null;
        return null;
      }
      final player = VideoPlayerController.file(File(path!));
      controller.value = player;
      var disposed = false;
      player.initialize().then((_) {
        if (disposed) return;
        ready.value = true;
        player.setLooping(true);
        player.play();
      });
      return () {
        disposed = true;
        player.dispose();
      };
    }, [path]);

    final player = controller.value;

    Widget body;
    if (path == null) {
      body = InkWell(
        onTap: onChange,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_call_rounded, size: 44, color: _Brand.purple),
              Gap(8),
              Text(
                'Tap to choose a video',
                style: TextStyle(
                  color: _Brand.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (!ready.value || player == null) {
      body = const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      body = ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: player,
        builder: (context, v, _) {
          final playing = v.isPlaying;
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => playing ? player.pause() : player.play(),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: v.aspectRatio == 0 ? 9 / 16 : v.aspectRatio,
                    child: VideoPlayer(player),
                  ),
                ),
              ),
              // Bottom scrim with scrubber + time.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_fmt(v.position)} / ${_fmt(v.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: VideoProgressIndicator(
                          player,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: VideoProgressColors(
                            playedColor: _Brand.pink,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!playing)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Top-right actions.
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    _PreviewAction(
                      icon: muted.value
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: () {
                        muted.value = !muted.value;
                        player.setVolume(muted.value ? 0 : 1);
                      },
                    ),
                    const Gap(8),
                    _PreviewAction(
                      icon: Icons.fullscreen_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => _FullscreenPreview(player: player),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Top-left: change video.
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: onChange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        Gap(6),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: _Brand.gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _Brand.softShadow(_Brand.pink, alpha: 0.12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: _height,
          color: path == null
              ? _Brand.purple.withValues(alpha: 0.08)
              : Colors.black,
          child: body,
        ),
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PreviewAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

/// Full-screen preview sharing the inline player (not disposed here).
class _FullscreenPreview extends StatelessWidget {
  final VideoPlayerController player;
  const _FullscreenPreview({required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: player,
        builder: (context, v, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => v.isPlaying ? player.pause() : player.play(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: v.aspectRatio == 0 ? 9 / 16 : v.aspectRatio,
                  child: VideoPlayer(player),
                ),
              ),
              if (!v.isPlaying)
                const IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SafeArea(
                  child: VideoProgressIndicator(
                    player,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    colors: VideoProgressColors(
                      playedColor: _Brand.pink,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white24,
                    ),
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

// =============================================================================
// Progress / error / success
// =============================================================================

/// One unified progress view — deliberately doesn't surface compression
/// internals to the user. Only the upload step shows a real percentage.
class _ProgressSection extends StatelessWidget {
  final VideoUploadState state;
  const _ProgressSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final isUploading = state.stage == UploadStage.uploading;
    final percent = (state.uploadProgress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUploading ? 'Uploading...' : 'Preparing video...',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _Brand.ink,
              ),
            ),
            if (isUploading)
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _Brand.purple,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: isUploading ? state.uploadProgress : null,
            minHeight: 8,
            color: _Brand.purple,
            backgroundColor: _Brand.purple.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String? status;
  const _SuccessBanner({this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Uploaded! Your video is $status — it\'ll appear in the feed '
              'once it\'s ready.',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom action
// =============================================================================

class _BottomAction extends StatelessWidget {
  final VideoUploadState state;
  final bool canPost;
  final VoidCallback onUpload;
  final VoidCallback onReset;
  final VoidCallback onDone;

  const _BottomAction({
    required this.state,
    required this.canPost,
    required this.onUpload,
    required this.onReset,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    if (state.stage == UploadStage.compressing ||
        state.stage == UploadStage.uploading) {
      return const SizedBox.shrink();
    }

    if (state.stage == UploadStage.success) {
      return _BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradientButton(
              onTap: onDone,
              text: 'Back to Feed',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Upload Another Video'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _Brand.purple,
                side: BorderSide(color: _Brand.purple.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label = state.stage == UploadStage.error ? 'Try Again' : 'Post';
    return _BottomBar(
      child: _GradientButton(
        onTap: canPost ? onUpload : null,
        text: label,
        icon: Icons.send_rounded,
      ),
    );
  }
}

/// White sheet pinned under the form so the action stays prominent.
class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _Brand.purple.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Signature pink → purple → blue button with a glow, press-scale and hover
/// lift. A null [onTap] renders the muted disabled state.
class _GradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const _GradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered && enabled ? 1.015 : 1),
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: enabled
                  ? _Brand.gradient
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade300],
                    ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _Brand.pink.withValues(
                          alpha: _hovered ? 0.5 : 0.35,
                        ),
                        blurRadius: _hovered ? 28 : 20,
                        offset: const Offset(-4, 8),
                      ),
                      BoxShadow(
                        color: _Brand.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(4, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: enabled ? Colors.white : Colors.grey.shade500,
                ),
                const Gap(10),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: enabled ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
