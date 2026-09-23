import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/network/reverb_socket.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/feed/domain/comment.dart';
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
    builder: (_) =>
        CommentsSheet(videoId: videoId, onCountChanged: onCountChanged),
  );
}

class CommentsSheet extends HookConsumerWidget {
  final String videoId;
  final ValueChanged<int>? onCountChanged;

  const CommentsSheet({required this.videoId, this.onCountChanged, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsControllerProvider(videoId));
    final controller = ref.read(commentsControllerProvider(videoId).notifier);
    final inputCtr = useTextEditingController();
    final scrollCtr = useScrollController();
    final currentUser = ref.watch(currentUserProvider);

    // Single source of truth for keeping the feed's comment count in sync —
    // covers a locally posted/deleted comment *and* one that arrived over
    // the WebSocket from another viewer, without double-counting either.
    ref.listen<CommentsState>(commentsControllerProvider(videoId), (
      previous,
      next,
    ) {
      if (previous != null && next.items.length != previous.items.length) {
        onCountChanged?.call(next.items.length - previous.items.length);
      }
    });

    useEffect(() {
      void listener() {
        if (scrollCtr.position.pixels >
            scrollCtr.position.maxScrollExtent - 200) {
          controller.loadMore();
        }
      }

      scrollCtr.addListener(listener);
      return () => scrollCtr.removeListener(listener);
    }, [scrollCtr]);

    Future<void> handleSend() async {
      final text = inputCtr.text;
      if (text.trim().isEmpty) return;
      if (!await requireLogin(context, ref, message: 'Sign in to comment')) {
        return;
      }
      final ok = await controller.post(text);
      if (ok) {
        inputCtr.clear();
      } else if (context.mounted) {
        AppService.showToast('Could not post comment.', isError: true);
      }
    }

    Future<void> handleLike(VideoComment comment) async {
      if (!await requireLogin(context, ref, message: 'Sign in to like comments')) {
        return;
      }
      controller.toggleLike(comment.id);
    }

    Future<void> handleDelete(VideoComment comment) async {
      final ok = await controller.delete(comment.id);
      if (!ok && context.mounted) {
        AppService.showToast('Could not delete comment.', isError: true);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const Gap(10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(14),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _ConnectionStatusLabel(status: state.connectionState),
                const Gap(8),
                const Divider(height: 1),
                Expanded(
                  child: _buildBody(
                    context,
                    state,
                    controller,
                    currentUser,
                    handleDelete,
                    handleLike,
                    scrollCtr,
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputCtr,
                            maxLength: 1000,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              filled: true,
                              fillColor: AppColors.lightGrey.withValues(
                                alpha: 0.06,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => handleSend(),
                          ),
                        ),
                        const Gap(8),
                        state.isPosting
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: handleSend,
                                icon: Icon(
                                  Icons.send_rounded,
                                  color: AppColors.appPrimaryPink,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CommentsState state,
    CommentsController controller,
    dynamic currentUser,
    Future<void> Function(VideoComment) onDelete,
    Future<void> Function(VideoComment) onLike,
    ScrollController scrollCtr,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return Center(child: Text(state.errorMessage!));
    }
    if (state.items.isEmpty) {
      return Center(
        child: Text(
          'No comments yet — be the first to say something.',
          style: TextStyle(color: AppColors.lightGrey),
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtr,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final comment = state.items[index];
        final isMine = currentUser != null && currentUser.id == comment.user.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageUserCircleProfile(
                imageUrl: comment.user.profilePicture,
                name: comment.user.name,
                size: 34,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user.username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(2),
                    Text(comment.body),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      comment.isLikedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: comment.isLikedByMe
                          ? AppColors.appPrimaryPink
                          : AppColors.lightGrey,
                    ),
                    onPressed: () => onLike(comment),
                  ),
                  if (comment.likesCount > 0)
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lightGrey,
                      ),
                    ),
                ],
              ),
              if (isMine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => onDelete(comment),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionStatusLabel extends StatelessWidget {
  final SocketConnectionState status;
  const _ConnectionStatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SocketConnectionState.connecting => 'Connecting…',
      SocketConnectionState.reconnecting => 'Reconnecting…',
      SocketConnectionState.connected => null,
      SocketConnectionState.failed => null,
    };
    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: AppColors.lightGrey),
      ),
    );
  }
}
