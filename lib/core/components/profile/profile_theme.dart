import 'package:flutter/material.dart';

/// Shared pink → purple → blue palette for the user / restaurant profile
/// screens and their building blocks.
abstract class ProfileTheme {
  static const pink = Color(0xffFF54AB);
  static const purple = Color(0xff9B6BFF);
  static const blue = Color(0xff74BFFF);
  static const ink = Color(0xff1F1B3A);
  static const muted = Color(0xff7A7896);
  static const deepPurple = Color(0xff6B4EFF);

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

  static const pinkBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, blue],
  );

  /// Vivid indigo → magenta wash used behind a profile with no cover photo.
  static const coverFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff4F46E5), Color(0xff9333EA), Color(0xffDB2777)],
  );

  /// Brand-colored wash laid over a cover photo for a moodier, on-brand
  /// look, in place of showing the raw photo.
  static Gradient get coverMoodTint => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      pink.withValues(alpha: 0.5),
      purple.withValues(alpha: 0.5),
      blue.withValues(alpha: 0.5),
    ],
  );

  static Color get hairline => purple.withValues(alpha: 0.10);

  /// Dark-mode reading of [ink] — a near-white so headline text stays legible
  /// on a near-black surface instead of the light-mode deep-navy ink.
  static const _inkDark = Color(0xffF2F1F7);

  /// Dark-mode reading of [muted] — a light lavender-grey (rather than a
  /// plain grey) so secondary text still reads as part of the pink/purple
  /// brand family.
  static const _mutedDark = Color(0xffA9A6C4);

  /// Primary text color, adapted to the current [Brightness] — [ink] in
  /// light mode, a near-white in dark mode.
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _inkDark : ink;

  /// Secondary/label text color, adapted to the current [Brightness] —
  /// [muted] in light mode, a light lavender-grey in dark mode.
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _mutedDark : muted;

  /// Card/surface background, following the app's [ThemeData.colorScheme].
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// [hairline], boosted in dark mode where a 10%-alpha tint all but
  /// disappears against a near-black surface.
  static Color hairlineColor(BuildContext context) => purple.withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.10,
  );

  static List<BoxShadow> cardShadow() => [
    BoxShadow(
      color: const Color(0xff3B1C7A).withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Rounded surface card with a hairline border and a subtle shadow. Follows
/// the app theme, so it reads as a white card in light mode and a dark
/// surface in dark mode.
class ProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ProfileTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
        boxShadow: ProfileTheme.cardShadow(),
      ),
      child: child,
    );
  }
}
