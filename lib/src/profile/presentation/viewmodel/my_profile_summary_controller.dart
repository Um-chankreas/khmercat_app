import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/profile/domain/my_profile_summary.dart';
import 'package:khmer_cat_app/src/profile/providers/profile_providers.dart';

/// Loads the signed-in user's own profile counts (Following/Followers/Posts/
/// Likes) from GET /profile/{userId}. Keyed by userId so it naturally resets
/// if the signed-in account changes.
class MyProfileSummaryController
    extends FamilyNotifier<MyProfileSummary?, String> {
  @override
  MyProfileSummary? build(String userId) {
    Future.microtask(load);
    return null;
  }

  Future<void> load() async {
    try {
      state = await ref.read(profileRepositoryProvider).getProfile(arg);
    } catch (_) {
      // Keep the previous (or null) state — the header already renders
      // fine with counts at 0 while this is null.
    }
  }

  /// Called after a post is deleted so the "Posts" count reflects it
  /// immediately instead of waiting for the next full reload.
  void decrementPostsCount() {
    final current = state;
    if (current == null) return;
    state = MyProfileSummary(
      id: current.id,
      name: current.name,
      username: current.username,
      avatar: current.avatar,
      bio: current.bio,
      email: current.email,
      followingCount: current.followingCount,
      followersCount: current.followersCount,
      postsCount: (current.postsCount - 1).clamp(0, 1 << 31),
      likesCount: current.likesCount,
    );
  }
}

final myProfileSummaryControllerProvider =
    NotifierProvider.family<
      MyProfileSummaryController,
      MyProfileSummary?,
      String
    >(MyProfileSummaryController.new);
