// lib/src/profile/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/cover_avatar_header.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/auth/providers/auth_provider.dart';
import 'package:khmer_cat_app/src/profile/domain/edit_profile_data.dart';
import 'package:khmer_cat_app/src/profile/presentation/widgets/profile_image_flow.dart';
import 'package:khmer_cat_app/src/profile/providers/profile_providers.dart';

const _red = Color(0xffE5484D);
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Facebook-style edit-profile screen: a [SliverAppBar] whose expanded state
/// is the avatar photo + "Change photo", pinned so a compact toolbar (back,
/// profile name, Save) is left showing once it's scrolled away, then grows
/// back as the user scrolls up. It's one [CustomScrollView], so a drag
/// started anywhere on the screen — including right over the avatar — moves
/// the whole page.
///
/// [_AvatarHeader] builds both the expanded avatar content *and* the small
/// pinned name that appears once it's collapsed, crossfading between them
/// based on real scroll offset — a [ScrollController] attached to the
/// [CustomScrollView] — rather than through [FlexibleSpaceBar.title] or
/// [FlexibleSpaceBarSettings]. Both of those looked like the built-in way to
/// do this, and both turned out to have sharp, undocumented edges for a
/// plain `pinned: true` bar (`title` in particular: with no `floating: true`,
/// Flutter hard-codes its fade opacity to a constant `1.0`, so it's actually
/// drawn at full opacity from the first frame, positioned near the bottom of
/// the *expanded* space — a second, duplicate title sitting on top of the
/// real header instead of replacing it once collapsed). The expanded avatar
/// content is also scaled via [FittedBox] rather than resized directly, so
/// it can't overflow no matter how little height is left for it.
class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  static const double _expandedHeight = 240;
  static const double _collapseRange = _expandedHeight - kToolbarHeight;

  /// 1 = header fully expanded (scroll offset 0), 0 = fully collapsed to
  /// just the pinned toolbar (scrolled past [_collapseRange]).
  static double _collapseFraction(ScrollController controller) {
    if (!controller.hasClients) return 1;
    final offset = controller.offset.clamp(0.0, _collapseRange);
    return 1 - offset / _collapseRange;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final scrollController = useScrollController();

    // Only reachable from the signed-in user's own profile.
    if (user == null) {
      return const Scaffold(body: SizedBox());
    }

    final bioCtr = useTextEditingController(text: user.bio ?? '');
    final emailCtr = useTextEditingController(text: user.email);
    final phoneCtr = useTextEditingController();
    final facebookCtr = useTextEditingController();
    final tiktokCtr = useTextEditingController();
    final telegramCtr = useTextEditingController();
    useListenable(bioCtr);
    useListenable(emailCtr);

    final submitted = useState(false);
    final saving = useState(false);
    final emailServerError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final facebookError = useState<String?>(null);
    final tiktokError = useState<String?>(null);
    final telegramError = useState<String?>(null);

    final emailFormatError =
        submitted.value && !_emailPattern.hasMatch(emailCtr.text.trim())
        ? 'Enter a valid email address'
        : null;
    final emailError = emailFormatError ?? emailServerError.value;

    // GET /profile/edit's `bio`/`email` are the same values `user` (the
    // cached signed-in account) already carries, but `phone`/`social_links`
    // aren't on that shared entity at all — this is the only source for
    // them, so the phone/social fields start empty and pop in once it lands.
    useEffect(() {
      var cancelled = false;
      ref
          .read(profileRepositoryProvider)
          .getEditProfile()
          .then((data) {
            if (cancelled) return;
            phoneCtr.text = data.phone ?? '';
            facebookCtr.text = data.socialLinks.facebook ?? '';
            tiktokCtr.text = data.socialLinks.tiktok ?? '';
            telegramCtr.text = data.socialLinks.telegram ?? '';
          })
          .catchError((_) {
            // Non-fatal — the form is still usable, just starts with
            // phone/social links blank instead of pre-filled.
          });
      return () => cancelled = true;
      // ignore: exhaustive_keys — intentionally runs once, on first mount.
    }, const []);

    Future<void> handleSave() async {
      submitted.value = true;
      if (emailFormatError != null) {
        AppService.showToast(
          'Please fix the highlighted field.',
          isError: true,
        );
        return;
      }
      if (saving.value) return;

      AppService.dismissKeyboard(context);
      saving.value = true;
      emailServerError.value = null;
      phoneError.value = null;
      facebookError.value = null;
      tiktokError.value = null;
      telegramError.value = null;

      String? orNull(String text) => text.trim().isEmpty ? null : text.trim();

      try {
        await ref
            .read(profileRepositoryProvider)
            .updateProfile(
              name: user.name,
              bio: orNull(bioCtr.text),
              email: emailCtr.text.trim(),
              phone: orNull(phoneCtr.text),
              socialLinks: SocialLinks(
                facebook: orNull(facebookCtr.text),
                tiktok: orNull(tiktokCtr.text),
                telegram: orNull(telegramCtr.text),
              ),
            );

        // Refreshes the shared signed-in User (name/bio/email show up
        // everywhere else in the app that reads it) the same way the
        // avatar/cover upload flow does.
        final fresh = await ref.read(authRepositoryProvider).getCurrentUser();
        ref.read(authControllerProvider.notifier).setAuthenticated(fresh);

        if (!context.mounted) return;
        AppService.showToast('Profile updated');
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      } on ApiException catch (e) {
        if (e.isValidationError) {
          emailServerError.value = e.fieldError('email');
          phoneError.value = e.fieldError('phone');
          facebookError.value = e.fieldError('social_links.facebook');
          tiktokError.value = e.fieldError('social_links.tiktok');
          telegramError.value = e.fieldError('social_links.telegram');
          AppService.showToast(
            'Please fix the highlighted field.',
            isError: true,
          );
        } else {
          AppService.showToast(e.message, isError: true);
        }
      } catch (_) {
        AppService.showToast(
          'Something went wrong. Please try again.',
          isError: true,
        );
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: surface,
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Rebuilds only this sliver (not the whole tree) on every scroll
          // tick, to recompute how collapsed the header is.
          ListenableBuilder(
            listenable: scrollController,
            builder: (context, _) => SliverAppBar(
              pinned: true,
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              expandedHeight: _expandedHeight,
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ProfileCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SaveIconButton(
                    saving: saving.value,
                    onTap: saving.value ? null : handleSave,
                  ),
                ),
              ],
              // No `title:` — see _AvatarHeader's doc for why the pinned
              // name that appears once collapsed is built inside
              // `background` instead, and `collapseMode: none` so that
              // content isn't also shifted by the default parallax effect.
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.none,
                background: _AvatarHeader(
                  t: _collapseFraction(scrollController),
                  avatarUrl: user.profilePicture,
                  name: user.name,
                  onChangePhoto: () =>
                      changeProfileImage(context, ref, ProfileImageKind.avatar),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Field(
                    label: 'Bio',
                    trailing: _Counter(count: bioCtr.text.length, max: 150),
                    child: _InputField(
                      controller: bioCtr,
                      hint: 'Tell people a little about yourself',
                      icon: Icons.notes_rounded,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 150,
                    ),
                  ),
                  const Gap(20),
                  _Field(
                    label: 'Email',
                    child: _InputField(
                      controller: emailCtr,
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      errorText: emailError,
                    ),
                  ),
                  const Gap(20),
                  _Field(
                    label: 'Phone',
                    optional: true,
                    child: _InputField(
                      controller: phoneCtr,
                      hint: 'e.g. 012 345 678',
                      icon: Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: phoneError.value,
                    ),
                  ),
                  const Gap(20),
                  _Field(
                    label: 'Social links',
                    optional: true,
                    child: Column(
                      children: [
                        _InputField(
                          controller: facebookCtr,
                          hint: 'Facebook profile URL',
                          asset: AssetsName.facebook,
                          keyboardType: TextInputType.url,
                          errorText: facebookError.value,
                        ),
                        const Gap(10),
                        _InputField(
                          controller: tiktokCtr,
                          hint: 'TikTok username',
                          asset: AssetsName.tiktok,
                          errorText: tiktokError.value,
                        ),
                        const Gap(10),
                        _InputField(
                          controller: telegramCtr,
                          hint: 'Telegram username',
                          asset: AssetsName.telegram,
                          errorText: telegramError.value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header background — collapses behind the pinned toolbar as the page scrolls
// =============================================================================

class _AvatarHeader extends StatelessWidget {
  /// 1 = expanded, 0 = collapsed. See [EditProfileScreen._collapseFraction].
  final double t;
  final String? avatarUrl;
  final String name;
  final VoidCallback onChangePhoto;
  const _AvatarHeader({
    required this.t,
    required this.avatarUrl,
    required this.name,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    // Both hold their resting value (1, 0) until the last kToolbarHeight
    // worth of the collapse range, then cross over across that final
    // stretch — a brief, deliberate blend right at the swap rather than a
    // hard cut or a long simultaneous overlap.
    final fadeWindow = kToolbarHeight / EditProfileScreen._collapseRange;
    final expandedOpacity = (t / fadeWindow).clamp(0.0, 1.0);
    final pinnedOpacity = 1 - expandedOpacity;

    return Stack(
      children: [
        IgnorePointer(
          ignoring: expandedOpacity < 0.5,
          child: Opacity(
            opacity: expandedOpacity,
            child: Container(
              decoration: const BoxDecoration(
                gradient: ProfileTheme.coverFallback,
              ),
              // Leaves room under where the pinned toolbar sits so the
              // avatar is never drawn behind the back/save buttons.
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: Center(
                // Scales the whole block down to fit whatever height is
                // actually available instead of being cropped by it — this
                // can't overflow, no matter how far the header has
                // collapsed.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileRingAvatar(
                        avatarUrl: avatarUrl,
                        name: name,
                        size: 88,
                        badge: GestureDetector(
                          onTap: onChangePhoto,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: ProfileTheme.pinkPurple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Gap(10),
                      GestureDetector(
                        onTap: onChangePhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Change photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // The pinned replacement: just the name, centered in the toolbar
        // strip between the back button and the Save icon.
        Positioned(
          // AppBar insets its own leading/title/actions by the status bar
          // automatically; `background`'s box (this widget) does not — it
          // runs edge-to-edge under the status bar/notch, same as the cover
          // photo behind it — so this needs the same inset added by hand to
          // land in the same visible row as the menu icon next to it.
          top: MediaQuery.paddingOf(context).top,
          left: 0,
          right: 0,
          height: kToolbarHeight,
          child: IgnorePointer(
            ignoring: pinnedOpacity < 0.5,
            child: Opacity(
              opacity: pinnedOpacity,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 60),
                alignment: Alignment.center,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveIconButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onTap;
  const _SaveIconButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: ProfileTheme.gradient,
            shape: BoxShape.circle,
          ),
          child: saving
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}

// =============================================================================
// Form fields
// =============================================================================

/// A labelled form row: label (+ "Optional", + a trailing widget such as a
/// counter) above its input.
class _Field extends StatelessWidget {
  final String label;
  final bool optional;
  final Widget? trailing;
  final Widget child;
  const _Field({
    required this.label,
    required this.child,
    this.optional = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              if (optional) ...[
                const Gap(6),
                Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ProfileTheme.textSecondary(context),
                  ),
                ),
              ],
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final int count;
  final int max;
  const _Counter({required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final nearLimit = count >= max * 0.9;
    return Text(
      '$count/$max',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: nearLimit ? _red : ProfileTheme.textSecondary(context),
      ),
    );
  }
}

/// The one input style on this screen. Leads with either a Material [icon]
/// or a brand logo [asset].
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? asset;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? errorText;

  const _InputField({
    required this.controller,
    required this.hint,
    this.icon,
    this.asset,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.keyboardType,
    this.errorText,
  }) : assert((icon == null) != (asset == null));

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    final line = ProfileTheme.hairlineColor(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ProfileTheme.textPrimary(context),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: ProfileTheme.textSecondary(context).withValues(alpha: 0.7),
        ),
        counterText: '',
        errorText: errorText,
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _red,
        ),
        // Multi-line fields keep the icon on the first line, not centered.
        prefixIcon: Padding(
          padding: EdgeInsets.fromLTRB(14, multiline ? 14 : 0, 10, 0),
          child: Align(
            alignment: multiline ? Alignment.topCenter : Alignment.center,
            widthFactor: 1,
            heightFactor: multiline ? 1 : null,
            child: asset != null
                ? Image.asset(asset!, width: 20, height: 20)
                : Icon(icon, size: 20, color: ProfileTheme.purple),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: ProfileTheme.purple.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.fromLTRB(0, 15, 14, 15),
        border: _border(line),
        enabledBorder: _border(line),
        focusedBorder: _border(ProfileTheme.purple, 1.5),
        errorBorder: _border(_red.withValues(alpha: 0.7), 1.2),
        focusedErrorBorder: _border(_red, 1.5),
      ),
    );
  }
}
