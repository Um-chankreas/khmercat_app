import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/settings/app_settings_controller.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/domain/entities/user.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/switch_password_sheet.dart';

const _danger = Color(0xffE5484D);

/// The "Menu" / settings screen reached from the profile header. Holds the
/// owner's pages (restaurants), the language picker and the theme switch.
class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final myRestaurants = ref.watch(myRestaurantsControllerProvider);
    final user = ref.watch(currentUserProvider);
    final activeRestaurant = ref.watch(activeRestaurantProvider);
    // Which restaurant card is mid-switch, if any.
    final switching = useState<String?>(null);

    /// Switches to [restaurant] (null = personal), confirms with a toast and
    /// returns to the Profile tab, which animates to the new profile.
    Future<void> switchTo(Restaurant? restaurant, String name) async {
      if (switching.value != null) return;
      final isCurrent = restaurant?.id == activeRestaurant?.id;
      if (isCurrent) {
        Navigator.of(context).maybePop();
        return;
      }
      final bool ok;
      if (restaurant == null) {
        // Back to personal needs the password; the sheet shows its own
        // loading and wrong-password errors, and false means cancelled.
        if (!await confirmSwitchToPersonal(context)) return;
        ok = true;
      } else {
        switching.value = restaurant.id;
        ok = await ref
            .read(myRestaurantsControllerProvider.notifier)
            .switchTo(restaurant.id);
      }
      if (!context.mounted) return;
      switching.value = null;
      if (ok) {
        HapticFeedback.lightImpact();
        AppService.showToast(l.switchedTo(name));
        Navigator.of(context).maybePop();
      } else {
        AppService.showToast(l.switchFailed, isError: true);
      }
    }

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
          // ---- Current profile ----------------------------------------
          const Gap(4),
          _CurrentProfileHeader(
            label: l.currentlyViewing,
            name: activeRestaurant?.name ?? user?.name ?? '',
            imageUrl: activeRestaurant?.profilePicture ?? user?.profilePicture,
            isRestaurant: activeRestaurant != null,
            typeLabel: activeRestaurant != null
                ? l.profileTypeRestaurant
                : l.profileTypePersonal,
          ),
          const Gap(20),

          // ---- Switch account -----------------------------------------
          Builder(
            builder: (context) {
              final restaurants =
                  myRestaurants.valueOrNull?.restaurants ??
                  const <Restaurant>[];
              final muted = ProfileTheme.textSecondary(context);
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      l.switchAccount.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: muted,
                      ),
                    ),
                  ),
                  if (!myRestaurants.isLoading)
                    Text(
                      l.profilesCount(1 + restaurants.length),
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                ],
              );
            },
          ),
          const Gap(10),
          myRestaurants.when(
            loading: () => const SizedBox(
              height: _ProfileCarousel.height,
              child: Center(
                child: CircularProgressIndicator(color: ProfileTheme.purple),
              ),
            ),
            error: (_, _) => _ProfileCarousel(
              cards: [
                _personalCard(
                  context,
                  l,
                  user,
                  activeRestaurant,
                  switching.value,
                  switchTo,
                ),
              ],
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileCarousel(
                  cards: [
                    _personalCard(
                      context,
                      l,
                      user,
                      activeRestaurant,
                      switching.value,
                      switchTo,
                    ),
                    for (final r in data.restaurants)
                      _ProfileSwitchCard(
                        name: r.name,
                        imageUrl: r.profilePicture,
                        coverUrl: r.coverPicture,
                        isRestaurant: true,
                        typeLabel: l.profileTypeRestaurant,
                        detail: r.isPublished
                            ? '${_compact(r.followersCount ?? 0)} ${l.statFollowers}'
                            : 'Hidden · ${_compact(r.followersCount ?? 0)} ${l.statFollowers}',
                        isActive: r.id == activeRestaurant?.id,
                        isSwitching: switching.value == r.id,
                        activeLabel: l.profileStatusActive,
                        inactiveLabel: l.profileStatusInactive,
                        onTap: () => switchTo(r, r.name),
                      ),
                  ],
                ),
                if (data.restaurants.isEmpty) ...[
                  const Gap(10),
                  Text(
                    l.noRestaurantsYet,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ProfileTheme.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(12),
          _CreateRestaurantButton(
            text: l.createRestaurant,
            onTap: () =>
                AppRouter.router.pushNamed(AppRoute.createRestaurant.name),
          ),

          // ---- Preferences -------------------------------------------
          const Gap(28),
          _SectionLabel(l.preferences),
          const Gap(10),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.language_rounded,
                color: ProfileTheme.blue,
                title: l.language,
                subtitle: _localeLabel(l, locale),
                onTap: () => _pickLanguage(context, ref, l, locale),
              ),
              _SettingsRow(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: ProfileTheme.purple,
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

          // ---- Terms of Policy --------------------------------------
          const Gap(28),
          _SectionLabel(l.termsOfPolicy),
          const Gap(10),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.description_rounded,
                color: ProfileTheme.pink,
                title: l.termsOfService,
                // TODO: point at the real Terms of Service page/URL once it exists.
                onTap: () => AppService.showToast(l.comingSoon),
              ),
              _SettingsRow(
                icon: Icons.shield_rounded,
                color: ProfileTheme.blue,
                title: l.termsOfPrivacy,
                // TODO: point at the real Privacy Policy page/URL once it exists.
                onTap: () => AppService.showToast(l.comingSoon),
              ),
            ],
          ),

          // ---- Log out -----------------------------------------------
          const Gap(28),
          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: Icons.logout_rounded,
                color: _danger,
                title: l.logOut,
                titleColor: _danger,
                showChevron: false,
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
          const Gap(12),
        ],
      ),
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static Widget _personalCard(
    BuildContext context,
    AppLocalizations l,
    User? user,
    Restaurant? activeRestaurant,
    String? switching,
    Future<void> Function(Restaurant?, String) switchTo,
  ) {
    final name = user?.name ?? '';
    return _ProfileSwitchCard(
      name: name,
      imageUrl: user?.profilePicture,
      coverUrl: user?.coverPicture,
      isRestaurant: false,
      typeLabel: l.profileTypePersonal,
      detail: user == null ? '' : '@${user.username}',
      isActive: activeRestaurant == null,
      // The password sheet shows its own loading state.
      isSwitching: false,
      activeLabel: l.profileStatusActive,
      inactiveLabel: l.profileStatusInactive,
      onTap: () => switchTo(null, name),
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

/// Small grey uppercase section title (matches "SWITCH ACCOUNT").
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: ProfileTheme.textSecondary(context),
      ),
    );
  }
}

/// Flat rounded group of rows: surface color, hairline border, no shadow,
/// thin dividers between rows.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final line = ProfileTheme.hairlineColor(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 62, color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Icon (colored, on a soft round tint), title, optional subtitle, and a
/// trailing widget — a chevron by default.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return InkWell(
      onTap: onTap,
      splashColor: color.withValues(alpha: 0.10),
      highlightColor: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? ProfileTheme.textPrimary(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(1),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

/// "Currently viewing" banner: avatar/logo, name and a Personal/Restaurant
/// badge on a light, flat background.
class _CurrentProfileHeader extends StatelessWidget {
  final String label;
  final String name;
  final String? imageUrl;
  final bool isRestaurant;
  final String typeLabel;
  const _CurrentProfileHeader({
    required this.label,
    required this.name,
    required this.imageUrl,
    required this.isRestaurant,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$name|$isRestaurant'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Brand pink → purple → blue, same as the app's main buttons.
          gradient: ProfileTheme.gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // White ring so the avatar stands out on the gradient.
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _ProfileAvatar(
                imageUrl: imageUrl,
                name: name,
                isRestaurant: isRestaurant,
                size: 52,
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(6),
                  _TypeBadge(
                    label: typeLabel,
                    isRestaurant: isRestaurant,
                    onDark: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of profile cards. It bleeds past the page's
/// 16px side padding so cards scroll edge to edge, while the first and last
/// card still sit 16px in. A subtle scrollbar hints there's more.
class _ProfileCarousel extends StatefulWidget {
  final List<Widget> cards;
  const _ProfileCarousel({required this.cards});

  /// Card height plus room for the scrollbar underneath.
  static const double height = 200;

  @override
  State<_ProfileCarousel> createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<_ProfileCarousel> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tablets get wider cards (160 vs 140).
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final cardWidth = isTablet ? 160.0 : 140.0;
    const pagePadding = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: _ProfileCarousel.height,
        child: OverflowBox(
          maxWidth: constraints.maxWidth + pagePadding * 2,
          minWidth: constraints.maxWidth + pagePadding * 2,
          child: Scrollbar(
            controller: _controller,
            thickness: 3,
            radius: const Radius.circular(2),
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              // Momentum scrolling with only a subtle edge bounce.
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              padding: const EdgeInsets.fromLTRB(
                pagePadding,
                4,
                pagePadding,
                14,
              ),
              itemCount: widget.cards.length,
              separatorBuilder: (_, _) => const Gap(12),
              itemBuilder: (_, i) =>
                  SizedBox(width: cardWidth, child: widget.cards[i]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One profile you can switch to. The cover photo fills the card (with a
/// dark fade so the text stays readable), or the default brand gradient when
/// there's no cover. At the bottom: a small circular avatar/logo inline with
/// the name, then the type badge and followers; status in the corners. Scales
/// up slightly while pressed and shows a spinner while switching; the
/// active one gets a gradient outline.
class _ProfileSwitchCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String? coverUrl;
  final bool isRestaurant;
  final String typeLabel;
  final String detail;
  final bool isActive;
  final bool isSwitching;
  final String activeLabel;
  final String inactiveLabel;
  final VoidCallback onTap;
  const _ProfileSwitchCard({
    required this.name,
    required this.imageUrl,
    required this.coverUrl,
    required this.isRestaurant,
    required this.typeLabel,
    required this.detail,
    required this.isActive,
    required this.isSwitching,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.onTap,
  });

  @override
  State<_ProfileSwitchCard> createState() => _ProfileSwitchCardState();
}

class _ProfileSwitchCardState extends State<_ProfileSwitchCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    const green = Color(0xff22C55E);
    const avatarSize = 30.0;
    final cover = w.coverUrl;
    final hasCover = cover != null && cover.isNotEmpty;

    const shadow = [Shadow(color: Color(0x66000000), blurRadius: 6)];

    return AnimatedScale(
      scale: _pressed ? 1.04 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(w.isActive ? 2 : 0),
        decoration: BoxDecoration(
          gradient: w.isActive ? ProfileTheme.gradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(w.isActive ? 10 : 12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---- Background: cover photo, or the default gradient.
              if (hasCover)
                CachedNetworkImage(
                  imageUrl: cover,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ProfileTheme.coverFallback,
                    ),
                  ),
                  errorWidget: (_, _, _) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ProfileTheme.coverFallback,
                    ),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ProfileTheme.coverFallback,
                  ),
                ),
              // Dark fade toward the bottom so white text stays legible on
              // any photo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: hasCover ? 0.15 : 0.0),
                      Colors.black.withValues(alpha: hasCover ? 0.65 : 0.25),
                    ],
                  ),
                ),
              ),

              // ---- Content + ripple.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: w.isSwitching ? null : w.onTap,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    // Cover shows through at the top; details sit at the
                    // bottom with a small avatar inline with the name.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _ProfileAvatar(
                                imageUrl: w.imageUrl,
                                name: w.name,
                                isRestaurant: w.isRestaurant,
                                size: avatarSize,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                w.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: shadow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        _TypeBadge(
                          label: w.typeLabel,
                          isRestaurant: w.isRestaurant,
                          onDark: true,
                        ),
                        const Gap(6),
                        Text(
                          w.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            shadows: shadow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Switching: spinner over the whole card (the avatar is too
              // small to carry it now).
              if (w.isSwitching)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // ---- Status: "Active" pill top-left, dot top-right.
              if (w.isActive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w.activeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: green,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 9,
                right: 9,
                child: Tooltip(
                  message: w.isActive ? w.activeLabel : w.inactiveLabel,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: w.isActive
                          ? green
                          : Colors.white.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white, width: 1.5),
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final bool isRestaurant;

  /// White-on-glass style for use over a photo or gradient.
  final bool onDark;
  const _TypeBadge({
    required this.label,
    required this.isRestaurant,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white
        : (isRestaurant ? ProfileTheme.pink : ProfileTheme.purple);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRestaurant ? Icons.storefront_rounded : Icons.person_rounded,
            size: 11,
            color: color,
          ),
          const Gap(3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar for a person or restaurant logo; a restaurant without a
/// logo gets the brand gradient with a storefront icon.
class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isRestaurant;
  final double size;
  const _ProfileAvatar({
    required this.imageUrl,
    required this.name,
    required this.isRestaurant,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return isRestaurant && !hasImage
        ? Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: ProfileTheme.coverFallback,
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: size * 0.45,
            ),
          )
        : ImageUserCircleProfile(imageUrl: url, name: name, size: size);
  }
}

// =============================================================================
// Buttons
// =============================================================================

/// Light, flat "Create a restaurant" button: soft purple tint, thin
/// border, gradient + icon. Scales down slightly while pressed.
class _CreateRestaurantButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _CreateRestaurantButton({required this.text, required this.onTap});

  @override
  State<_CreateRestaurantButton> createState() =>
      _CreateRestaurantButtonState();
}

class _CreateRestaurantButtonState extends State<_CreateRestaurantButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: ProfileTheme.purple.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: ProfileTheme.purple.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          splashColor: ProfileTheme.purple.withValues(alpha: 0.12),
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    gradient: ProfileTheme.pinkPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const Gap(8),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.deepPurple,
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
