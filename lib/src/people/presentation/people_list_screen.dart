import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/sign_in_prompt.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:khmer_cat_app/src/social/providers/social_providers.dart';

import '../data/people_remote_datasource.dart';
import '../domain/person.dart';

enum PeopleKind { followers, following, reviewers }

/// Which list of people to show: whose, and what kind.
class PeopleList {
  final PeopleKind kind;
  final String path;
  const PeopleList._(this.kind, this.path);

  PeopleList.restaurantFollowers(String restaurantId)
    : this._(PeopleKind.followers, ApiRoute.restaurantFollowers(restaurantId));
  PeopleList.restaurantFollowing(String restaurantId)
    : this._(PeopleKind.following, ApiRoute.restaurantFollowing(restaurantId));
  PeopleList.restaurantReviewers(String restaurantId)
    : this._(PeopleKind.reviewers, ApiRoute.restaurantReviewers(restaurantId));
  PeopleList.userFollowers(String username)
    : this._(PeopleKind.followers, ApiRoute.userFollowers(username));
  PeopleList.userFollowing(String username)
    : this._(PeopleKind.following, ApiRoute.userFollowing(username));
}

/// Opens [list] on its own screen.
void openPeopleList(BuildContext context, PeopleList list) {
  HapticFeedback.selectionClick();
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PeopleListScreen(list: list)));
}

/// Followers, following or reviewers: one row per person, opening their
/// profile, with a Follow button for anyone the viewer doesn't follow yet.
/// Loads more as it scrolls; pull down to refresh.
class PeopleListScreen extends HookConsumerWidget {
  final PeopleList list;
  const PeopleListScreen({required this.list, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final people = useState(const <Person>[]);
    final page = useRef(0);
    final hasMore = useState(true);
    final loading = useState(false);
    final failed = useState(false);
    // People whose follow request is in flight.
    final busy = useState(const <String>{});
    final scroll = useScrollController();

    Future<void> loadMore({bool reset = false}) async {
      if (loading.value || (!reset && !hasMore.value)) return;
      loading.value = true;
      failed.value = false;
      final next = reset ? 1 : page.value + 1;
      try {
        final result = await ref
            .read(peopleRemoteDataSourceProvider)
            .page(list.path, next);
        if (!context.mounted) return;
        page.value = next;
        people.value = reset
            ? result.people
            : [...people.value, ...result.people];
        hasMore.value = result.hasMore;
      } catch (_) {
        if (context.mounted) failed.value = true;
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    useEffect(() {
      loadMore();
      void onScroll() {
        if (scroll.position.extentAfter < 400) loadMore();
      }

      scroll.addListener(onScroll);
      return () => scroll.removeListener(onScroll);
    }, const []);

    Future<void> toggleFollow(Person person) async {
      if (busy.value.contains(person.id)) return;
      if (!await requireLogin(context, ref, message: l.signInToFollow)) return;
      final follow = !person.isFollowing;
      void setFollowing(bool value) => people.value = [
        for (final p in people.value)
          p.id == person.id ? p.copyWith(isFollowing: value) : p,
      ];

      busy.value = {...busy.value, person.id};
      setFollowing(follow);
      try {
        final social = ref.read(socialRemoteDataSourceProvider);
        follow
            ? await social.followUser(person.username)
            : await social.unfollowUser(person.username);
        HapticFeedback.lightImpact();
      } catch (_) {
        if (context.mounted) {
          setFollowing(!follow);
          AppService.showToast(l.followFailed, isError: true);
        }
      } finally {
        if (context.mounted) {
          busy.value = {...busy.value}..remove(person.id);
        }
      }
    }

    final (title, emptyText) = switch (list.kind) {
      PeopleKind.followers => (l.statFollowers, l.noFollowersYet),
      PeopleKind.following => (l.statFollowing, l.notFollowingAnyoneYet),
      PeopleKind.reviewers => (l.reviewersTitle, l.noReviewersYet),
    };
    final muted = ProfileTheme.textSecondary(context);

    Widget centered(Widget child) => ListView(
      // Scrollable so pull-to-refresh still works on an empty page.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(child: child),
        ),
      ],
    );

    final Widget body;
    if (people.value.isEmpty && loading.value) {
      body = centered(
        const CircularProgressIndicator(color: ProfileTheme.purple),
      );
    } else if (people.value.isEmpty && failed.value) {
      body = centered(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 38, color: muted),
            const Gap(10),
            Text(l.peopleLoadFailed, style: TextStyle(color: muted)),
            TextButton(
              onPressed: () => loadMore(reset: true),
              child: Text(
                l.tryAgain,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: menuAccent,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (people.value.isEmpty) {
      body = centered(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 40, color: muted),
            const Gap(10),
            Text(emptyText, style: TextStyle(fontSize: 14.5, color: muted)),
          ],
        ),
      );
    } else {
      body = ListView.separated(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          0,
          4,
          0,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        // A spinner row at the end while the next page loads.
        itemCount: people.value.length + (hasMore.value ? 1 : 0),
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 76,
          endIndent: 16,
          color: ProfileTheme.hairlineColor(context),
        ),
        itemBuilder: (context, i) {
          if (i == people.value.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: ProfileTheme.purple,
                  ),
                ),
              ),
            );
          }
          final person = people.value[i];
          return _PersonRow(
            person: person,
            subtitle: [
              '@${person.username}',
              if (person.reviewsCount != null)
                l.reviewsCount(person.reviewsCount!),
            ].join(' · '),
            busy: busy.value.contains(person.id),
            onTap: () => AppRouter.router.pushNamed(
              AppRoute.userProfile.name,
              pathParameters: {'username': person.username},
            ),
            onFollowTap: () => toggleFollow(person),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MenuTitleBar(title: title),
            Expanded(
              child: RefreshIndicator(
                color: ProfileTheme.purple,
                onRefresh: () => loadMore(reset: true),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar, name over @username, and Follow / Following (or "You").
class _PersonRow extends StatelessWidget {
  final Person person;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  const _PersonRow({
    required this.person,
    required this.subtitle,
    required this.busy,
    required this.onTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            ImageUserCircleProfile(
              imageUrl: person.profilePicture,
              name: person.name,
              size: 46,
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
            const Gap(10),
            if (person.isMe)
              Text(
                l.youLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              )
            else
              _FollowButton(
                following: person.isFollowing,
                busy: busy,
                onTap: onFollowTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Follow" on the brand wash; a quiet outlined "Following" once followed
/// (tap again to unfollow).
class _FollowButton extends StatelessWidget {
  final bool following;
  final bool busy;
  final VoidCallback onTap;
  const _FollowButton({
    required this.following,
    required this.busy,
    required this.onTap,
  });

  static const _wash = ProfileTheme.brandGradient;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primary = ProfileTheme.textPrimary(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 32,
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: following ? null : _wash,
          borderRadius: BorderRadius.circular(16),
          border: following
              ? Border.all(color: ProfileTheme.textSecondary(context))
              : null,
        ),
        child: Text(
          following ? l.followingAction : l.followAction,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: following ? primary : ProfileTheme.ink,
          ),
        ),
      ),
    );
  }
}
