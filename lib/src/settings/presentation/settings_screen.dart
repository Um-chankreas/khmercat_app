import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/settings/app_settings_controller.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';

const _blueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [ProfileTheme.blue, ProfileTheme.purple],
);
const _pinkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [ProfileTheme.pink, ProfileTheme.purple],
);
const _purpleGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [ProfileTheme.purple, ProfileTheme.blue],
);

/// The "Menu" / settings screen reached from the profile header. Holds the
/// owner's pages (restaurants), the language picker and the theme switch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final myRestaurants = ref.watch(myRestaurantsControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.menuTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // ---- Your restaurants ---------------------------------------
          _SectionHeader(
            icon: Icons.storefront_rounded,
            gradient: _pinkGradient,
            title: l.yourRestaurants,
          ),
          const Gap(8),
          myRestaurants.when(
            loading: () => const SizedBox(
              height: 90,
              child: Center(
                child: CircularProgressIndicator(color: ProfileTheme.purple),
              ),
            ),
            error: (_, _) => _EmptyRestaurants(message: l.noRestaurantsYet),
            data: (data) {
              if (data.restaurants.isEmpty) {
                return _EmptyRestaurants(message: l.noRestaurantsYet);
              }
              return SizedBox(
                height: 172,
                // Bleed to the screen edges so cards scroll under the gutter.
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: data.restaurants.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (context, i) => _RestaurantCard(
                    restaurant: data.restaurants[i],
                    isActive: data.restaurants[i].id == data.activeRestaurantId,
                  ),
                ),
              );
            },
          ),
          const Gap(10),
          _GradientButton(
            text: l.createRestaurant,
            icon: Icons.add_rounded,
            onTap: () =>
                AppRouter.router.pushNamed(AppRoute.createRestaurant.name),
          ),

          const _SectionDivider(),

          // ---- Preferences -------------------------------------------
          _SectionHeader(
            icon: Icons.tune_rounded,
            gradient: _purpleGradient,
            title: l.preferences,
          ),
          const Gap(8),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.language_rounded,
                gradient: _blueGradient,
                title: l.language,
                subtitle: _localeLabel(l, locale),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: ProfileTheme.muted,
                ),
                onTap: () => _pickLanguage(context, ref, l, locale),
              ),
              _SettingsRow(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                gradient: _purpleGradient,
                title: l.darkMode,
                subtitle: _themeLabel(l, themeMode),
                trailing: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isDark,
                    activeThumbColor: Colors.white,
                    activeTrackColor: ProfileTheme.purple,
                    onChanged: (v) => ref
                        .read(themeModeControllerProvider.notifier)
                        .set(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
                onTap: () => ref
                    .read(themeModeControllerProvider.notifier)
                    .set(isDark ? ThemeMode.light : ThemeMode.dark),
              ),
            ],
          ),

          const _SectionDivider(),

          // ---- Terms of Policy --------------------------------------
          _SectionHeader(
            icon: Icons.gavel_rounded,
            gradient: _blueGradient,
            title: l.termsOfPolicy,
          ),
          const Gap(8),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.description_rounded,
                gradient: _pinkGradient,
                title: l.termsOfService,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: ProfileTheme.muted,
                ),
                // TODO: point at the real Terms of Service page/URL once it exists.
                onTap: () => AppService.showToast(l.comingSoon),
              ),
              _SettingsRow(
                icon: Icons.shield_rounded,
                gradient: _blueGradient,
                title: l.termsOfPrivacy,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: ProfileTheme.muted,
                ),
                // TODO: point at the real Privacy Policy page/URL once it exists.
                onTap: () => AppService.showToast(l.comingSoon),
              ),
            ],
          ),

          const _SectionDivider(),

          _LogoutButton(
            text: l.logOut,
            onTap: () => AppDialogs.showConfirm(
              context,
              title: l.logOutConfirmTitle,
              message: l.logOutConfirmMessage,
              confirmText: l.logOut,
              isDestructive: true,
              onConfirm: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
        ],
      ),
    );
  }

  static String _localeLabel(AppLocalizations l, Locale? locale) {
    return switch (locale?.languageCode) {
      'en' => l.languageEnglish,
      'km' => l.languageKhmer,
      _ => l.themeSystem,
    };
  }

  static String _themeLabel(AppLocalizations l, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
      ThemeMode.system => l.themeSystem,
    };
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    Locale? current,
  ) async {
    final controller = ref.read(localeControllerProvider.notifier);
    final options = <(String?, String)>[
      (null, l.themeSystem),
      ('en', l.languageEnglish),
      ('km', l.languageKhmer),
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, label) in options)
              ListTile(
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: current?.languageCode == code
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ProfileTheme.purple,
                      )
                    : null,
                onTap: () {
                  controller.set(code == null ? null : Locale(code));
                  Navigator.pop(sheetContext);
                },
              ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Layout pieces
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  const _SectionHeader({
    required this.icon,
    required this.gradient,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Faint line with generous space around it, separating the sections.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: ProfileTheme.purple.withValues(alpha: 0.14),
      ),
    );
  }
}

/// Rounded surface card with a hairline border and a light shadow; theme-aware
/// so it reads correctly in dark mode too.
BoxDecoration _cardDecoration(BuildContext context, {double radius = 22}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: ProfileTheme.purple.withValues(alpha: 0.12)),
    boxShadow: ProfileTheme.cardShadow(),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 54,
                endIndent: 16,
                color: ProfileTheme.purple.withValues(alpha: 0.10),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      splashColor: ProfileTheme.purple.withValues(alpha: 0.10),
      highlightColor: ProfileTheme.purple.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Restaurants
// =============================================================================

class _EmptyRestaurants extends StatelessWidget {
  final String message;
  const _EmptyRestaurants({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ProfileTheme.purple.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 24,
              color: ProfileTheme.purple,
            ),
          ),
          const Gap(8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isActive;
  const _RestaurantCard({required this.restaurant, required this.isActive});

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final image = restaurant.coverPicture ?? restaurant.profilePicture;
    final followers = restaurant.followersCount ?? 0;

    void open() => AppRouter.router.pushNamed(
      AppRoute.restaurantProfile.name,
      pathParameters: {'id': restaurant.id},
    );

    return Container(
      width: 168,
      // The active restaurant gets a gradient outline.
      padding: EdgeInsets.all(isActive ? 1.5 : 0),
      decoration: BoxDecoration(
        gradient: isActive ? ProfileTheme.gradient : null,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ProfileTheme.cardShadow(),
      ),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isActive ? 20.5 : 22),
          side: isActive
              ? BorderSide.none
              : BorderSide(color: ProfileTheme.purple.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          splashColor: ProfileTheme.purple.withValues(alpha: 0.10),
          highlightColor: ProfileTheme.purple.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 84,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image != null && image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)
                        : const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: ProfileTheme.coverFallback,
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                    // Bottom fade so the follower chip stays legible.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: ProfileTheme.pinkPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const Gap(4),
                            Text(
                              '${_compact(followers)} ${l.statFollowers}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Color(0xff22A45D),
                              ),
                              Gap(3),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff22A45D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _ManageButton(onTap: open),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small outlined "Manage" button on each restaurant card — opens the
/// restaurant page, which holds the owner tools (post video, switch, menu).
class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTheme.purple.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ProfileTheme.purple.withValues(alpha: 0.18),
        child: const SizedBox(
          height: 28,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 15,
                color: ProfileTheme.deepPurple,
              ),
              Gap(4),
              Text(
                'Manage',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ProfileTheme.deepPurple,
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
// Buttons
// =============================================================================

/// Pink → purple → blue call-to-action with a press-scale and hover lift.
class _GradientButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.015 : 1),
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: ProfileTheme.gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: ProfileTheme.purple.withValues(
                    alpha: _hovered ? 0.30 : 0.20,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18, color: Colors.white),
                const Gap(6),
                Flexible(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

/// Danger-styled log out button; the confirmation dialog is opened by the
/// caller.
class _LogoutButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _LogoutButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xffE5484D);
    return Material(
      color: red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: red.withValues(alpha: 0.16),
        highlightColor: red.withValues(alpha: 0.08),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: red.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: red),
              const Gap(8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
