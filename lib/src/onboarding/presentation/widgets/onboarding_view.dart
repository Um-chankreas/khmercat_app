import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/extensions/safe_area_extension.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';

import '../../domain/onboarding_page_data.dart';

/// Each page's background: three colors for a diagonal gradient. Swiping
/// blends from one page's palette to the next.
const _palettes = [
  [Color(0xffFF54AB), Color(0xffB44CFF), Color(0xff6B4EFF)],
  [Color(0xff6B4EFF), Color(0xff4F8BFF), Color(0xff22D3EE)],
  [Color(0xffFF8A3D), Color(0xffFF4D8D), Color(0xff9B4DFF)],
];

/// Swipeable onboarding shared by the user and restaurant flows.
///
/// Everything tied to swiping follows the finger (it reads the live page
/// position, not the settled page):
/// - the full-screen gradient blends between each page's palette;
/// - phones slide, tilt and shrink as their page leaves; the back phone and
///   the floating badges move at different speeds for depth;
/// - title and description slide and fade just behind the phones.
///
/// On a repeating loop: phones and badges float, a rainbow ring spins behind
/// the phones, glowing blobs drift and sparkles rise. The first page rises
/// in once on open.
class OnboardingView extends HookWidget {
  final List<OnboardingPageData> pages;
  final VoidCallback onFinish;
  const OnboardingView({
    required this.pages,
    required this.onFinish,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final loop = useAnimationController(duration: const Duration(seconds: 12));
    final intro = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );

    useEffect(() {
      // Decode every page's images up front so swiping never shows a blank
      // frame while a screenshot loads. After the first frame, because
      // precacheImage reads inherited widgets (MediaQuery) from `context`,
      // which hooks forbid while the effect first runs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        for (final page in pages) {
          for (final path in [?page.imagePath, ...page.screenshots]) {
            precacheImage(AssetImage(path), context);
          }
        }
      });
      intro.forward();
      loop.repeat();
      return null;
      // ignore: exhaustive_keys — once, on open.
    }, const []);

    final isLastPage = currentPage.value == pages.length - 1;

    void goToNext() {
      HapticFeedback.lightImpact();
      if (isLastPage) {
        onFinish();
        return;
      }
      pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }

    /// Live, fractional page position (1.5 = halfway from page 1 to 2).
    double position() =>
        pageController.hasClients && pageController.position.haveDimensions
        ? pageController.page ?? 0
        : currentPage.value.toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([pageController, loop]),
          builder: (context, child) {
            final colors = _paletteAt(position());
            return Stack(
              children: [
                Positioned.fill(
                  child: _Background(colors: colors, t: loop.value),
                ),
                child!,
              ],
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: context.sym(h: 16, v: 8),
                    // Fades out on the last page, where it'd do the same
                    // thing as the main button.
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isLastPage ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: isLastPage,
                        child: _GlassPill(
                          onTap: onFinish,
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: intro,
                    builder: (context, child) {
                      final t = Curves.easeOutBack.transform(intro.value);
                      return Opacity(
                        opacity: intro.value,
                        child: Transform.translate(
                          offset: Offset(0, 60 * (1 - t)),
                          child: Transform.scale(
                            scale: 0.9 + 0.1 * t,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) => currentPage.value = index,
                      itemBuilder: (context, index) => _OnboardingPage(
                        page: pages[index],
                        index: index,
                        controller: pageController,
                        loop: loop,
                      ),
                    ),
                  ),
                ),
                Gap(context.sc(12)),
                _Dots(count: pages.length, current: currentPage.value),
                Gap(context.sc(22)),
                Padding(
                  padding: context.sym(h: 20),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([pageController, loop]),
                    builder: (context, _) => _GlowButton(
                      text: isLastPage ? 'Get Started' : 'Next',
                      icon: isLastPage
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      accent: _paletteAt(position())[1],
                      pulse: loop.value,
                      onTap: goToNext,
                    ),
                  ),
                ),
                Gap(context.safeBottomPadding()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The palette at a fractional page position, blending neighbours.
  static List<Color> _paletteAt(double position) {
    final clamped = position.clamp(0.0, _palettes.length - 1.0);
    final from = clamped.floor();
    final to = math.min(from + 1, _palettes.length - 1);
    final f = clamped - from;
    return [
      for (var i = 0; i < 3; i++)
        Color.lerp(_palettes[from][i], _palettes[to][i], f)!,
    ];
  }
}

// =============================================================================
// Background
// =============================================================================

/// Slowly turning gradient, two drifting glow blobs and rising sparkles.
class _Background extends StatelessWidget {
  final List<Color> colors;

  /// Loop progress, 0 → 1.
  final double t;
  const _Background({required this.colors, required this.t});

  @override
  Widget build(BuildContext context) {
    final a = t * 2 * math.pi;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.cos(a) * 0.6 - 0.6, -1),
                end: Alignment(0.6 - math.cos(a) * 0.6, 1),
                colors: colors,
              ),
            ),
          ),
          _glow(
            Colors.white.withValues(alpha: 0.28),
            Alignment(-0.8 + math.cos(a) * 0.35, -0.6 + math.sin(a) * 0.25),
            360,
          ),
          _glow(
            colors.first.withValues(alpha: 0.55),
            Alignment(0.9 + math.sin(a) * 0.3, 0.4 + math.cos(a) * 0.3),
            420,
          ),
          CustomPaint(painter: _SparklePainter(t)),
        ],
      ),
    );
  }

  Widget _glow(Color color, Alignment alignment, double size) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Small white sparkles drifting upward and twinkling. Positions come from a
/// fixed seed, so the field is the same every frame and just moves.
class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter(this.t);

  static final _seeds = List.generate(28, (i) {
    final r = math.Random(i * 7919);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 1.2 + r.nextDouble() * 2.6,
      speed: 0.4 + r.nextDouble() * 0.9,
      phase: r.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _seeds) {
      final y = (s.y - t * s.speed) % 1.0;
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin((t * 4 + s.phase) * 2 * math.pi));
      final center = Offset(
        s.x * size.width + math.sin((t + s.phase) * 2 * math.pi) * 10,
        y * size.height,
      );
      paint
        ..color = Colors.white.withValues(alpha: 0.75 * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(center, s.size, paint);
      // Every fourth one is a little four-point star.
      if (s.phase > 0.75) _star(canvas, center, s.size * 2.6, twinkle);
    }
  }

  void _star(Canvas canvas, Offset c, double r, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(c.translate(-r, 0), c.translate(r, 0), paint)
      ..drawLine(c.translate(0, -r), c.translate(0, r), paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

// =============================================================================
// One page
// =============================================================================

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData page;
  final int index;
  final PageController controller;
  final Animation<double> loop;
  const _OnboardingPage({
    required this.page,
    required this.index,
    required this.controller,
    required this.loop,
  });

  /// How far this page is from the settled one: 0 when it's centered,
  /// -1 / 1 once it's a full page off to the left / right.
  double _delta() {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return (index - controller.initialPage).toDouble();
    }
    return (index - (controller.page ?? 0)).clamp(-1.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, loop]),
      builder: (context, _) {
        final delta = _delta();
        final away = delta.abs();
        final width = MediaQuery.sizeOf(context).width;
        final a = loop.value * 2 * math.pi;
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: context.sym(h: 20),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Spinning rainbow ring + halo behind the phones.
                      Transform.scale(
                        scale: (1 - away * 0.5) * (1 + math.sin(a * 3) * 0.03),
                        child: Transform.rotate(
                          angle: a,
                          child: _GlowRing(size: box.maxHeight * 0.78),
                        ),
                      ),
                      Transform.translate(
                        // Lags behind its page, so it drifts in from the side.
                        offset: Offset(
                          delta * width * 0.3,
                          math.sin(a * 2) * 7,
                        ),
                        child: Transform.rotate(
                          angle: delta * 0.14,
                          child: Transform.scale(
                            scale: 1 - away * 0.15,
                            child: page.screenshots.isNotEmpty
                                ? _PhoneStack(
                                    screenshots: page.screenshots,
                                    delta: delta,
                                  )
                                : Image.asset(
                                    page.imagePath!,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                      // Badges move faster than the phones for depth, and
                      // bob out of step with them.
                      for (var i = 0; i < math.min(page.badges.length, 2); i++)
                        Align(
                          alignment: i == 0
                              ? const Alignment(-1.02, -0.62)
                              : const Alignment(1.02, 0.5),
                          child: Opacity(
                            opacity: (1 - away * 1.6).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(
                                delta * width * 0.6,
                                math.sin(a * 2 + i * math.pi) * 9,
                              ),
                              child: _Badge(badge: page.badges[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Gap(context.sc(26)),
              Opacity(
                opacity: (1 - away * 1.4).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(delta * width * 0.45, 0),
                  child: Column(
                    children: [
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          shadows: const [
                            Shadow(color: Color(0x40000000), blurRadius: 12),
                          ],
                        ),
                      ),
                      Gap(context.sc(10)),
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A soft white halo with a thin rainbow sweep ring around it.
class _GlowRing extends StatelessWidget {
  final double size;
  const _GlowRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: const CustomPaint(painter: _RingPainter()),
          ),
        ],
      ),
    );
  }
}

/// A circle outline painted with a rainbow sweep gradient, fading to clear
/// on one side so its rotation reads.
class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0xffFFE066),
          Color(0xffFF54AB),
          Color(0xff74BFFF),
          Color(0xffFFFFFF),
        ],
      ).createShader(rect);
    canvas.drawCircle(rect.center, size.shortestSide / 2 - 1.5, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// The front phone, plus an optional second one tilted behind it that moves
/// less during a swipe (parallax) and sits off to the side.
class _PhoneStack extends StatelessWidget {
  final List<String> screenshots;
  final double delta;
  const _PhoneStack({required this.screenshots, required this.delta});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final hasBack = screenshots.length > 1;
        // Tallest phone that fits, leaving side room for the back phone.
        final height = box.maxHeight;
        final width = math.min(
          height * _Phone.aspectRatio,
          box.maxWidth * (hasBack ? 0.6 : 0.7),
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            if (hasBack)
              Transform.translate(
                offset: Offset(width * 0.44 - delta * 40, -height * 0.035),
                child: Transform.rotate(
                  angle: 0.16 + delta * 0.06,
                  child: _Phone(image: screenshots[1], width: width * 0.86),
                ),
              ),
            Transform.translate(
              offset: Offset(hasBack ? -width * 0.14 : 0, 0),
              child: _Phone(image: screenshots.first, width: width),
            ),
          ],
        );
      },
    );
  }
}

/// A screenshot in a phone frame: dark bezel with a thin light rim, rounded
/// screen and a deep shadow so it pops off the colorful background.
class _Phone extends StatelessWidget {
  /// Width / height of the cleaned screenshots (status bar cropped).
  static const aspectRatio = 720 / 1517;

  final String image;
  final double width;
  const _Phone({required this.image, required this.width});

  @override
  Widget build(BuildContext context) {
    final radius = width * 0.12;
    final bezel = width * 0.03;
    return Container(
      width: width,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xff15132A),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Image.asset(image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Frosted white chip with an icon bubble and a short label.
class _Badge extends StatelessWidget {
  final OnboardingBadge badge;
  const _Badge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xffFF54AB), Color(0xff9B6BFF)],
              ),
            ),
            child: Icon(badge.icon, size: 16, color: Colors.white),
          ),
          const Gap(8),
          Text(
            badge.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xff1F1B3A),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Chrome
// =============================================================================

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          // Not an overshooting curve (e.g. easeOutBack): it would push the
          // glow shadow past its end value, and a negative blur radius
          // crashes the painter.
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: current == i ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: current == i ? 1 : 0.4),
              boxShadow: current == i
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Frosted-glass pill for secondary actions on the colorful background.
class _GlassPill extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassPill({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// White primary button with a softly pulsing glow; text and icon take the
/// current page's color. The label crossfades between Next / Get Started.
class _GlowButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color accent;

  /// Loop progress, 0 → 1 — drives the glow pulse.
  final double pulse;
  final VoidCallback onTap;
  const _GlowButton({
    required this.text,
    required this.icon,
    required this.accent,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.35 + 0.25 * math.sin(pulse * 6 * math.pi);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: glow),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.15),
          child: SizedBox(
            height: context.sc(54),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Row(
                key: ValueKey(text),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  const Gap(8),
                  Icon(icon, size: 20, color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
