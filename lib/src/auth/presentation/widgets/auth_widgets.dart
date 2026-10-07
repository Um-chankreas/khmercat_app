import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

// Shared look for the login and register screens: gradient backdrop with a
// large soft cat-head watermark, a frosted-glass animated card, rounded icon
// fields and a gradient pill button.

/// Brand pink → blue, same as the app's gradient buttons.
const _buttonGradient = [Color(0xffFF54AB), Color(0xff74BFFF)];
const authAccentPink = Color(0xffE066A8);

final authEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Secondary text color on the card, for light and dark mode.
Color authMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.white.withValues(alpha: 0.55)
    : AppColors.lightGrey.withValues(alpha: 0.6);

/// The whole auth page: gradient background with the cat watermark, back
/// button, and a glass [AuthCard] holding the heading and [children].
/// Tapping outside a field hides the keyboard; the page scrolls when the
/// keyboard is open.
class AuthScaffold extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final String? subtitle;

  /// Replaces the plain [title] text (e.g. a title with a gradient word).
  final Widget? titleWidget;

  /// Giggling logo, wordmark and tagline above the title.
  final bool showBrand;

  /// Where the card sits when the page is taller than it. Slightly below
  /// center leaves the cat's face showing above the card.
  final Alignment cardAlignment;
  final List<Widget> children;
  const AuthScaffold({
    required this.formKey,
    required this.title,
    required this.children,
    this.subtitle,
    this.titleWidget,
    this.showBrand = true,
    this.cardAlignment = Alignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = authMuted(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.appPrimaryBlue,
      ),
      child: GestureDetector(
        onTap: () => AppService.dismissKeyboard(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned.fill(child: AuthCatBackdrop()),
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.sc(20),
                        vertical: context.sc(72),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - context.sc(144))
                              .clamp(0, double.infinity),
                        ),
                        child: Align(
                          alignment: cardAlignment,
                          child: Form(
                            key: formKey,
                            child: AuthCard(
                              children: [
                                if (showBrand) ...[
                                  const AuthLogo(),
                                  Gap(context.sc(12)),
                                  const AuthWordmark(),
                                  Gap(context.sc(4)),
                                  Text(
                                    'FOOD & LIFESTYLE EXPRESS',
                                    style: theme.textTheme.labelSmall!.copyWith(
                                      color: muted,
                                      letterSpacing: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Gap(context.sc(24)),
                                ] else
                                  Gap(context.sc(8)),
                                titleWidget ??
                                    Text(title, style: authTitleStyle(context)),
                                if (subtitle != null) ...[
                                  Gap(context.sc(4)),
                                  Text(
                                    subtitle!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ],
                                Gap(context.sc(24)),
                                ...children,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: context.sc(16),
                    top: context.sc(8),
                    child: AuthBackButton(onTap: () => context.pop()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card heading style, shared with custom [AuthScaffold.titleWidget]s.
TextStyle authTitleStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.headlineSmall!.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: theme.colorScheme.onSurface,
  );
}

/// "Welcome to khmercat" — the last word in the brand gradient. Shrinks to
/// fit on narrow phones instead of wrapping.
class AuthBrandTitle extends StatelessWidget {
  final String lead;
  final String brand;
  const AuthBrandTitle({
    this.lead = 'Welcome to',
    this.brand = 'khmercat',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final style = authTitleStyle(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$lead ', style: style),
          GradientText(brand, style: style),
        ],
      ),
    );
  }
}

/// The app logo's cat head, big and soft, behind the card: anchored to the
/// left edge (partly off-screen), fading in and bobbing slowly.
class AuthCatBackdrop extends StatelessWidget {
  const AuthCatBackdrop({super.key});

  // Pixel size of assets/company/app_logo_small.png.
  static const _logoAspect = 1198 / 952;
  static const _logoOpacity = 0.10;
  static const _logoBlur = 0.5;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          // Most of the screen's width, hanging a little off the left edge.
          final width = math.min(c.maxWidth * 0.92, 480.0);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -width * 0.16,
                top: c.maxHeight * 0.09,
                width: width,
                height: width / _logoAspect,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.94 + 0.06 * t,
                      child: child,
                    ),
                  ),
                  child: _Float(
                    distance: 7,
                    duration: const Duration(milliseconds: 3600),
                    // The real logo (head only, transparent), faded and
                    // slightly blurred so it sits behind the card as a soft
                    // watermark. The boundary caches the blurred result, so
                    // the bob doesn't re-run the filter.
                    child: RepaintBoundary(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: _logoBlur,
                          sigmaY: _logoBlur,
                        ),
                        child: Image.asset(
                          AssetsName.appLogoTrsm,
                          fit: BoxFit.contain,
                          opacity: const AlwaysStoppedAnimation(_logoOpacity),
                          // Decoded at on-screen size, not the 1198px source.
                          cacheWidth:
                              (width * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Already have an account? Login" style footer line.
class AuthFooterLink extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;
  const AuthFooterLink({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: style.copyWith(color: authMuted(context))),
        Gap(context.sc(6)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: style.copyWith(
              color: authAccentPink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Show/hide eye for a password field.
class AuthObscureToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const AuthObscureToggle({
    required this.obscure,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: authMuted(context),
      ),
    );
  }
}

InputDecoration authFieldDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  String? errorText,
  Widget? suffix,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final idle = Colors.white.withValues(alpha: isDark ? 0.12 : 0.75);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    // Translucent so the fields sit in the glass card, not on top of it.
    fillColor: Colors.white.withValues(alpha: isDark ? 0.07 : 0.55),
    contentPadding: const EdgeInsets.symmetric(vertical: 16),
    prefixIcon: Icon(icon, size: 20, color: authAccentPink),
    suffixIcon: suffix,
    border: border(idle),
    enabledBorder: border(idle),
    focusedBorder: border(authAccentPink, 1.4),
    errorBorder: border(Colors.red),
    focusedErrorBorder: border(Colors.red, 1.4),
  );
}

/// Frosted-glass card. Entrance animation: the glass frosts over as the
/// card rises, then its contents follow one after another, each fading in
/// and sliding up a little.
class AuthCard extends HookWidget {
  final List<Widget> children;
  const AuthCard({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    useEffect(() {
      ctrl.forward();
      return null;
    }, const []);

    // Built once (not per rebuild — typing rebuilds this card), since every
    // CurvedAnimation attaches a listener to the controller.
    final card = useMemoized(
      () => CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
      ),
      [ctrl],
    );
    final itemAnims = useMemoized(
      () => [
        for (var i = 0; i < children.length; i++)
          CurvedAnimation(
            parent: ctrl,
            curve: Interval(
              0.2 + 0.55 * i / children.length,
              (0.5 + 0.55 * i / children.length).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
      ],
      [ctrl, children.length],
    );

    Widget stagger(int i, Widget child) {
      final anim = itemAnims[i];
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) stagger(i, children[i]),
      ],
    );

    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(card),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(card),
        // The glass itself fades by animating its blur and tint, not with
        // an opacity layer: a BackdropFilter under partial opacity can't
        // see the page behind it, so the frost would pop in at the end.
        child: AnimatedBuilder(
          animation: card,
          builder: (context, child) => _glass(context, card.value, child!),
          child: content,
        ),
      ),
    );
  }

  Widget _glass(BuildContext context, double t, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(30));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18 * t, sigmaY: 18 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              // Dark mode keeps a dark pane so the light text stays
              // readable over the pastel background.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.50 * t),
                        Colors.black.withValues(alpha: 0.38 * t),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.50 * t),
                        Colors.white.withValues(alpha: 0.28 * t),
                      ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: (isDark ? 0.16 : 0.70) * t,
                ),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.sc(22),
                context.sc(24),
                context.sc(22),
                context.sc(24),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// App logo in a circle with a thin brand-gradient ring. Pops in with a
/// bounce, floats gently, and every few seconds (or when tapped) the cat
/// "giggles": a squash-and-stretch wiggle, blushing cheeks and little
/// hearts floating up.
class AuthLogo extends HookWidget {
  const AuthLogo({super.key});

  static const _giggleEvery = Duration(milliseconds: 3800);

  @override
  Widget build(BuildContext context) {
    final size = context.sc(76);
    final giggle = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );
    useEffect(() {
      // First giggle once the card's entrance has settled, then on a loop.
      final first = Timer(const Duration(milliseconds: 1300), () {
        giggle.forward(from: 0);
      });
      final loop = Timer.periodic(_giggleEvery, (_) {
        if (!giggle.isAnimating) giggle.forward(from: 0);
      });
      return () {
        first.cancel();
        loop.cancel();
      };
    }, [giggle]);
    final t = useAnimation(giggle);
    // 0 at rest, rises and falls once over the giggle.
    final wave = t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi);
    // Fast shake that dies out.
    final shake = math.sin(t * math.pi * 6) * (1 - t);

    final cat = Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..rotateZ(0.10 * shake)
        ..scaleByDouble(1 + 0.07 * shake, 1 - 0.07 * shake, 1, 1),
      child: _SmilingCat(blush: wave),
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        giggle.forward(from: 0);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: _Float(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _ring(context, size, cat),
              if (t > 0 && t < 1) ..._hearts(size, t),
            ],
          ),
        ),
      ),
    );
  }

  /// Three small hearts that rise from the top of the ring, drifting
  /// sideways and fading out, slightly staggered.
  List<Widget> _hearts(double size, double t) {
    const specs = [
      (dx: -0.30, delay: 0.00, drift: -10.0, scale: 0.9),
      (dx: 0.32, delay: 0.12, drift: 12.0, scale: 0.75),
      (dx: 0.02, delay: 0.24, drift: -4.0, scale: 0.6),
    ];
    return [
      for (final h in specs)
        if (t > h.delay)
          Builder(
            builder: (context) {
              final p = ((t - h.delay) / (1 - h.delay)).clamp(0.0, 1.0);
              final rise = Curves.easeOutCubic.transform(p);
              final opacity = p < 0.2 ? p / 0.2 : 1 - (p - 0.2) / 0.8;
              return Positioned(
                left: size / 2 + h.dx * size - 8 + h.drift * p,
                top: size * 0.05 - 34 * rise,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: h.scale * (0.6 + 0.4 * rise),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: authAccentPink,
                    ),
                  ),
                ),
              );
            },
          ),
    ];
  }

  Widget _ring(BuildContext context, double size, Widget cat) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradientText,
        ),
        boxShadow: [
          BoxShadow(
            color: authAccentPink.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: EdgeInsets.all(context.sc(8)),
        child: Center(child: cat),
      ),
    );
  }
}

/// The logo image with two soft pink blush spots over its cheeks. The
/// spots are placed as fractions of the image (just under each closed eye),
/// so they stay on the cheeks at any size.
class _SmilingCat extends StatelessWidget {
  /// 0 = no blush, 1 = full blush.
  final double blush;
  const _SmilingCat({required this.blush});

  // Pixel size of assets/company/app_logo_small.png.
  static const _aspect = 1198 / 950;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspect,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          Widget cheek(double fx) => Positioned(
            left: w * fx - w * 0.09,
            top: h * 0.58 - h * 0.05,
            child: Container(
              width: w * 0.18,
              height: h * 0.10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xffFF7BAC).withValues(alpha: 0.75 * blush),
                    const Color(0xffFF7BAC).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AssetsName.appLogoTrsm, fit: BoxFit.contain),
              if (blush > 0) ...[cheek(0.26), cheek(0.74)],
            ],
          );
        },
      ),
    );
  }
}

/// Slow up-and-down bob, looping forever.
class _Float extends HookWidget {
  final Widget child;
  final double distance;
  final Duration duration;
  const _Float({
    required this.child,
    this.distance = 4,
    this.duration = const Duration(milliseconds: 2400),
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(duration: duration);
    useEffect(() {
      ctrl.repeat(reverse: true);
      return null;
    }, const []);
    final curve = useMemoized(
      () => CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      [ctrl],
    );
    final dy = useAnimation(curve);
    return Transform.translate(offset: Offset(0, -distance * dy), child: child);
  }
}

/// "Khmer" in the regular text color, "Cat" in the brand gradient.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Khmer', style: style),
        GradientText('Cat', style: style),
      ],
    );
  }
}

class AuthValidTick extends StatelessWidget {
  const AuthValidTick({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: authAccentPink.withValues(alpha: 0.15),
          border: Border.all(color: authAccentPink.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: authAccentPink),
      ),
    );
  }
}

/// Shrinks slightly while pressed; the label and spinner cross-fade.
class AuthGradientButton extends HookWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const AuthGradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final label = Theme.of(context).textTheme.titleMedium!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    return GestureDetector(
      onTapDown: onTap == null ? null : (_) => pressed.value = true,
      onTapUp: (_) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: AnimatedScale(
        scale: pressed.value ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: _body(context, label),
      ),
    );
  }

  Widget _body(BuildContext context, TextStyle label) {
    return Container(
      width: double.infinity,
      height: context.sc(52),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _buttonGradient,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(this.label, style: label),
                    const Gap(8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const AuthBackButton({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.sc(40);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(context.sc(11)),
        child: Image.asset(AssetsName.back),
      ),
    );
  }
}
