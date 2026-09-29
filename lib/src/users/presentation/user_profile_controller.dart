import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';
import 'package:khmer_cat_app/src/users/domain/public_profile.dart';
import 'package:khmer_cat_app/src/users/providers/user_providers.dart';

class UserProfileState {
  final PublicProfile? profile;
  final bool isLoading;
  final bool isFollowingLocally;
  final String? errorMessage;

  const UserProfileState({
    this.profile,
    this.isLoading = true,
    this.isFollowingLocally = false,
    this.errorMessage,
  });

  UserProfileState copyWith({
    PublicProfile? profile,
    bool? isLoading,
    bool? isFollowingLocally,
    String? errorMessage,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isFollowingLocally: isFollowingLocally ?? this.isFollowingLocally,
      errorMessage: errorMessage,
    );
  }
}

class UserProfileController extends FamilyNotifier<UserProfileState, String> {
  @override
  UserProfileState build(String username) {
    Future.microtask(load);
    return const UserProfileState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await ref.read(userRemoteDataSourceProvider).show(arg);
      final profile = PublicProfile.fromJson(data);
      state = UserProfileState(
        profile: profile,
        isLoading: false,
        // Real follow state from the API (was session-only before).
        isFollowingLocally: profile.isFollowing,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'User not found.');
    }
  }

  /// Same limitation as the restaurant profile — no `is_following` flag on
  /// GET /users/{username}, so this is optimistic-only for the session.
  Future<void> toggleFollow() async {
    final profile = state.profile;
    if (profile == null) return;

    final wasFollowing = state.isFollowingLocally;
    final delta = wasFollowing ? -1 : 1;
    state = state.copyWith(
      isFollowingLocally: !wasFollowing,
      profile: profile.copyWith(
        followersCount: (profile.followersCount ?? 0) + delta,
      ),
    );

    try {
      final social = ref.read(socialRemoteDataSourceProvider);
      final count = wasFollowing
          ? await social.unfollowUser(arg)
          : await social.followUser(arg);
      state = state.copyWith(
        profile: state.profile!.copyWith(followersCount: count),
      );
    } catch (_) {
      state = state.copyWith(
        isFollowingLocally: wasFollowing,
        profile: profile,
      );
    }
  }
}

final userProfileControllerProvider =
    NotifierProvider.family<UserProfileController, UserProfileState, String>(
      UserProfileController.new,
    );
