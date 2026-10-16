import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/components/rating/rating_badge.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/settings/app_settings_controller.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/addresses/presentation/addresses_controller.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/switch_password_sheet.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/account_action_sheet.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:khmer_cat_app/src/admin/data/admin_remote_datasource.dart';
import 'package:khmer_cat_app/src/admin/presentation/admin_reports_screen.dart';
import 'package:khmer_cat_app/src/admin/presentation/admin_restaurants_screen.dart';

const _danger = Color(0xffE5484D);

// Restaurants listed before "See all".
const _restaurantsShown = 5;

/// The "Menu" / settings screen reached from the profile header: the
/// profile in use, the personal account and the owner's restaurants to
/// switch between, then address, preferences, terms and account rows.
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
    // How many addresses are saved; null until that's known.
    final savedAddresses = ref
        .watch(addressesControllerProvider)
        .valueOrNull
        ?.length;
    // "See all" on the restaurants card.
    final showAll = useState(false);
    final followers =
        '${_compact(activeRestaurant?.followersCount ?? 0)} ${l.statFollowers.toLowerCase()}';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MenuBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                MenuTitleBar(title: l.menuTitle),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      MediaQuery.paddingOf(context).bottom + 20,
                    ),
                    children: [
                      // ---- Current profile ----------------------------
                      _CurrentProfileHeader(
                        label: l.currentlyViewing,
                        name: activeRestaurant?.name ?? user?.name ?? '',
                        imageUrl:
                            activeRestaurant?.profilePicture ??
                            user?.profilePicture,
                        isRestaurant: activeRestaurant != null,
                        detail: activeRestaurant != null
                            ? '${l.profileTypeRestaurant} · $followers'
                            : [
                                l.profileTypePersonal,
                                if (user != null) '@${user.username}',
                              ].join(' · '),
                      ),
                      const Gap(16),

                      // ---- Admin (admins only) -------------------------
                      if (user?.isAdmin ?? false) ...[
                        const _AdminCard(),
                        const Gap(12),
                      ],

                      // ---- Your account --------------------------------
                      MenuCard(
                        title: l.yourAccount,
                        children: [
                          MenuRow(
                            leading: _ProfileAvatar(
                              imageUrl: user?.profilePicture,
                              name: user?.name ?? '',
                              isRestaurant: false,
                              size: MenuRow.leadingSize,
                            ),
                            title: user?.name ?? '',
                            subtitle: Text(
                              [
                                l.profileTypePersonal,
                                if (user != null) '@${user.username}',
                              ].join(' · '),
                            ),
                            trailing: activeRestaurant == null
                                ? _ActivePill(label: l.profileStatusActive)
                                : const SizedBox.shrink(),
                            onTap: () => switchTo(null, user?.name ?? ''),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // ---- Your restaurants ----------------------------
                      Builder(
                        builder: (context) {
                          final all =
                              myRestaurants.valueOrNull?.restaurants ??
                              const <Restaurant>[];
                          final shown = showAll.value
                              ? all
                              : all.take(_restaurantsShown).toList();
                          return MenuCard(
                            title: l.yourRestaurants,
                            action: all.length > _restaurantsShown
                                ? (
                                    showAll.value ? l.showLess : l.seeAll,
                                    () => showAll.value = !showAll.value,
                                  )
                                : null,
                            children: [
                              if (myRestaurants.isLoading && all.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 22),
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
                                )
                              else if (all.isEmpty && !myRestaurants.hasError)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    14,
                                  ),
                                  child: Text(
                                    l.noRestaurantsYet,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: ProfileTheme.textSecondary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              for (final r in shown)
                                MenuRow(
                                  leading: _ProfileAvatar(
                                    imageUrl: r.profilePicture,
                                    name: r.name,
                                    isRestaurant: true,
                                    size: MenuRow.leadingSize,
                                  ),
                                  title: r.name,
                                  subtitle: _RestaurantMeta(
                                    restaurant: r,
                                    hiddenLabel: l.restaurantHidden,
                                    reviews: l.reviewsCount(r.reviewsCount),
                                    followers:
                                        '${_compact(r.followersCount ?? 0)} ${l.statFollowers.toLowerCase()}',
                                  ),
                                  trailing: switching.value == r.id
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: ProfileTheme.purple,
                                          ),
                                        )
                                      : r.id == activeRestaurant?.id
                                      ? _ActivePill(
                                          label: l.profileStatusActive,
                                        )
                                      : const SizedBox.shrink(),
                                  onTap: () => switchTo(r, r.name),
                                ),
                              MenuRow(
                                leading: Container(
                                  width: MenuRow.leadingSize,
                                  height: MenuRow.leadingSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.backgroundGradientLR,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 22,
                                    color: ProfileTheme.ink,
                                  ),
                                ),
                                title: l.createRestaurant,
                                trailing: const SizedBox.shrink(),
                                onTap: () => AppRouter.router.pushNamed(
                                  AppRoute.createRestaurant.name,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Gap(12),

                      // ---- Address -------------------------------------
                      MenuCard(
                        title: l.addressSection,
                        children: [
                          MenuRow.icon(
                            icon: Icons.place_outlined,
                            title: l.savedAddresses,
                            subtitle: switch (savedAddresses) {
                              null || 0 => null,
                              final n => l.savedCount(n),
                            },
                            onTap: () => AppRouter.router.pushNamed(
                              AppRoute.addresses.name,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // ---- Preferences ---------------------------------
                      MenuCard(
                        title: l.preferences,
                        children: [
                          MenuRow.icon(
                            icon: Icons.language_rounded,
                            title: l.language,
                            subtitle: _localeLabel(l, locale),
                            onTap: () => _pickLanguage(context, ref, l, locale),
                          ),
                          MenuRow.icon(
                            icon: isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            title: l.darkMode,
                            subtitle: _themeLabel(l, themeMode),
                            trailing: Switch(
                              value: isDark,
                              activeThumbColor: Colors.white,
                              activeTrackColor: ProfileTheme.purple,
                              onChanged: (v) => ref
                                  .read(themeModeControllerProvider.notifier)
                                  .set(v ? ThemeMode.dark : ThemeMode.light),
                            ),
                            onTap: () => ref
                                .read(themeModeControllerProvider.notifier)
                                .set(isDark ? ThemeMode.light : ThemeMode.dark),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // ---- Terms of Policy -----------------------------
                      MenuCard(
                        title: l.termsOfPolicy,
                        children: [
                          MenuRow.icon(
                            icon: Icons.description_outlined,
                            title: l.termsOfService,
                            // TODO: point at the real Terms of Service page/URL once it exists.
                            onTap: () => AppService.showToast(l.comingSoon),
                          ),
                          MenuRow.icon(
                            icon: Icons.shield_outlined,
                            title: l.termsOfPrivacy,
                            // TODO: point at the real Privacy Policy page/URL once it exists.
                            onTap: () => AppService.showToast(l.comingSoon),
                          ),
                        ],
                      ),

                      // ---- Account (personal profile only) -------------
                      // Hidden while switched into a restaurant, so these
                      // can't be mistaken for actions on the restaurant.
                      if (user != null && activeRestaurant == null) ...[
                        const Gap(12),
                        MenuCard(
                          title: l.accountSection,
                          children: [
                            MenuRow.icon(
                              icon: Icons.visibility_off_outlined,
                              title: l.deactivateAccount,
                              subtitle: l.deactivateAccountSubtitle,
                              onTap: () async {
                                if (!await confirmDeactivateAccount(context)) {
                                  return;
                                }
                                if (!context.mounted) return;
                                AppService.showToast(l.accountDeactivated);
                                Navigator.of(context).maybePop();
                              },
                            ),
                            MenuRow.icon(
                              icon: Icons.delete_outline_rounded,
                              color: _danger,
                              title: l.deleteAccount,
                              subtitle: l.deleteAccountSubtitle,
                              onTap: () async {
                                if (!await confirmDeleteAccount(context)) {
                                  return;
                                }
                                if (!context.mounted) return;
                                AppService.showToast(l.accountDeleted);
                                Navigator.of(context).maybePop();
                              },
                            ),
                          ],
                        ),
                      ],

                      // ---- Log out -------------------------------------
                      const Gap(12),
                      MenuCard(
                        children: [
                          MenuRow.icon(
                            icon: Icons.logout_rounded,
                            color: _danger,
                            title: l.logOut,
                            trailing: const SizedBox.shrink(),
                            onTap: () => AppDialogs.showConfirm(
                              context,
                              title: l.logOutConfirmTitle,
                              message: l.logOutConfirmMessage,
                              confirmText: l.logOut,
                              isDestructive: true,
                              onConfirm: () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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

/// "✓ Active" on the brand pink → blue wash.
class _ActivePill extends StatelessWidget {
  final String label;
  const _ActivePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientLR,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 15, color: ProfileTheme.ink),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ProfileTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A restaurant row's subtitle: category · ★ rating (reviews), falling back
/// to the review count, then the follower count, for whatever it's missing.
class _RestaurantMeta extends StatelessWidget {
  final Restaurant restaurant;
  final String hiddenLabel;
  final String reviews;
  final String followers;
  const _RestaurantMeta({
    required this.restaurant,
    required this.hiddenLabel,
    required this.reviews,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final lead = [
      if (!r.isPublished) hiddenLabel,
      ?r.category?.name,
    ].join(' · ');
    final sep = lead.isEmpty ? '' : ' · ';
    if (r.avgRating == null) {
      return Text('$lead$sep${r.reviewsCount > 0 ? reviews : followers}');
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$lead$sep'),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: RatingBadge(rating: r.avgRating!, iconSize: 14),
          ),
          if (r.reviewsCount > 0) TextSpan(text: ' ($reviews)'),
        ],
      ),
    );
  }
}

/// "Currently viewing": the active profile's avatar in a gradient ring,
/// beside its name and a type · detail line.
class _CurrentProfileHeader extends StatelessWidget {
  final String label;
  final String name;
  final String? imageUrl;
  final bool isRestaurant;
  final String detail;
  const _CurrentProfileHeader({
    required this.label,
    required this.name,
    required this.imageUrl,
    required this.isRestaurant,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey('$name|$isRestaurant'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                gradient: ProfileTheme.gradient,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: _ProfileAvatar(
                  imageUrl: imageUrl,
                  name: name,
                  isRestaurant: isRestaurant,
                  size: 60,
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12.5, color: primary)),
                  const Gap(1),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: primary,
                    ),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Icon(
                        isRestaurant
                            ? Icons.storefront_outlined
                            : Icons.person_outline_rounded,
                        size: 16,
                        color: primary,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: primary),
                        ),
                      ),
                    ],
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

/// Menu → Admin: the approval queue and reported content, each with how
/// many are waiting.
class _AdminCard extends ConsumerWidget {
  const _AdminCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(adminCountsProvider).valueOrNull;
    String? waiting(int? n, String noun) =>
        n == null || n == 0 ? null : '$n $noun';
    return MenuCard(
      title: 'Admin',
      children: [
        MenuRow.icon(
          icon: Icons.storefront_outlined,
          title: 'Restaurant approvals',
          subtitle: waiting(counts?.pendingRestaurants, 'waiting'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminRestaurantsScreen(),
            ),
          ),
        ),
        MenuRow.icon(
          icon: Icons.flag_outlined,
          title: 'Reported content',
          subtitle: waiting(counts?.openReports, 'open'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AdminReportsScreen()),
          ),
        ),
      ],
    );
  }
}
