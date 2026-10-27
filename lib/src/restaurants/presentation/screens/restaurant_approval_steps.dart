import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/profile_switching_screen.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

// How long each step shows as "in progress" before it ticks.
const _stepTime = Duration(milliseconds: 900);

/// After a restaurant is created: Submitted → Reviewing → Approved, ticking
/// one by one, then the app reloads as the new restaurant and lands on Home.
///
/// The server approves new restaurants straight away; this only walks the
/// owner through it. If the server still left it pending (an older backend),
/// the last step says it's waiting for approval instead.
Future<void> showRestaurantApprovalSteps(
  BuildContext context,
  Restaurant restaurant,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _ApprovalSteps(restaurant: restaurant),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ApprovalSteps extends HookConsumerWidget {
  final Restaurant restaurant;
  const _ApprovalSteps({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final approved = restaurant.status == 'approved';
    // How many steps have ticked: 0 → 3.
    final done = useState(0);

    useEffect(() {
      var alive = true;
      Future<void> run() async {
        for (var i = 1; i <= 3; i++) {
          await Future.delayed(_stepTime);
          if (!alive) return;
          done.value = i;
          HapticFeedback.selectionClick();
        }
        await Future.delayed(const Duration(milliseconds: 700));
        if (!alive || !context.mounted) return;
        Navigator.of(context).pop();
        // The server made the new restaurant the active profile: reload
        // everything as it.
        refreshAfterProfileSwitch(ref);
        AppRouter.router.goNamed(AppRoute.index.name);
        HapticFeedback.lightImpact();
      }

      run();
      return () => alive = false;
    }, const []);

    final steps = [
      (l.approvalStepSubmitted, l.approvalStepSubmitted),
      (l.approvalStepReviewing, l.approvalStepReviewed),
      approved
          ? (l.adminApproved, l.adminApproved)
          : (l.adminWaitingApproval, l.adminWaitingApproval),
    ];
    final finished = done.value >= 3;

    return PopScope(
      // Nothing to go back to: the restaurant already exists.
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: SearchBackdrop()),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: ImageUserCircleProfile(
                        imageUrl: restaurant.profilePicture,
                        name: restaurant.name,
                        size: 88,
                      ),
                    ),
                    const Gap(18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        finished && approved
                            ? l.approvalLiveTitle
                            : l.approvalWorkingTitle(restaurant.name),
                        key: ValueKey(finished && approved),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: ProfileTheme.textPrimary(context),
                        ),
                      ),
                    ),
                    const Gap(28),
                    for (final (i, (active, ticked)) in steps.indexed)
                      _StepRow(
                        label: done.value > i ? ticked : active,
                        state: done.value > i
                            ? _StepState.done
                            : done.value == i
                            ? _StepState.active
                            : _StepState.waiting,
                        last: i == steps.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepState { waiting, active, done }

/// A dot (spinner while active, tick when done) and its label, with a line
/// down to the next step.
class _StepRow extends StatelessWidget {
  final String label;
  final _StepState state;
  final bool last;
  const _StepRow({
    required this.label,
    required this.state,
    required this.last,
  });

  static const _dot = 28.0;

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final done = state == _StepState.done;
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _dot,
                height: _dot,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done ? ProfileTheme.brandGradient : null,
                  color: done ? null : muted.withValues(alpha: 0.12),
                ),
                child: switch (state) {
                  _StepState.done => const Icon(
                    Icons.check_rounded,
                    size: 17,
                    color: ProfileTheme.ink,
                  ),
                  _StepState.active => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProfileTheme.purple,
                    ),
                  ),
                  _StepState.waiting => const SizedBox.shrink(),
                },
              ),
              if (!last)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 2,
                  height: 22,
                  color: done
                      ? ProfileTheme.brandPink
                      : muted.withValues(alpha: 0.18),
                ),
            ],
          ),
          const Gap(14),
          // Longer labels (Khmer) wrap instead of overflowing.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: state == _StepState.waiting
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: state == _StepState.waiting
                      ? muted
                      : ProfileTheme.textPrimary(context),
                ),
                child: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
