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
const _accent = Color(0xffB0125A);

/// Pastel pink → blue wash behind Save.
const _wash = ProfileTheme.brandGradient;
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Edit profile: back · "Edit profile" · Save along the top, the photo with
/// "Change photo" under it, then Bio, Email, Phone and Social links.
class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Only reachable from the signed-in user's own profile.
    if (user == null) {
      return const Scaffold(body: SizedBox());
    }

    final bioCtr = useTextEditingController(text: user.bio ?? '');
    final emailCtr = useTextEditingController(text: user.email);
    final phoneCtr = useTextEditingController();
    final facebookCtr = useTextEditingController();
    final telegramCtr = useTextEditingController();
    useListenable(bioCtr);
    useListenable(emailCtr);

    final submitted = useState(false);
    final saving = useState(false);
    final emailServerError = useState<String?>(null);
    final phoneError = useState<String?>(null);
    final facebookError = useState<String?>(null);
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              saving: saving.value,
              onBack: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              onSave: handleSave,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.paddingOf(context).bottom + 32,
                ),
                // Dragging the list puts the keyboard away.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Center(
                    child: _PhotoPicker(
                      avatarUrl: user.profilePicture,
                      name: user.name,
                      onTap: () => changeProfileImage(
                        context,
                        ref,
                        ProfileImageKind.avatar,
                      ),
                    ),
                  ),
                  const Gap(24),
                  _Field(
                    label: 'Bio',
                    trailing: _Counter(count: bioCtr.text.length, max: 150),
                    child: _InputField(
                      controller: bioCtr,
                      hint: 'Tell people a little about yourself',
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
                      hint: 'name@gmail.com',
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
                      hint: '012 345 678',
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
                          hint: 'facebook.com/yourname',
                          asset: AssetsName.facebook,
                          keyboardType: TextInputType.url,
                          errorText: facebookError.value,
                        ),
                        const Gap(10),
                        _InputField(
                          controller: telegramCtr,
                          hint: 'Telegram @username',
                          asset: AssetsName.telegram,
                          errorText: telegramError.value,
                        ),
                      ],
                    ),
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

/// Back, the centered title, and the Save pill.
class _TopBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;
  const _TopBar({
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: primary,
              ),
              onPressed: onBack,
            ),
          ),
          Text(
            'Edit profile',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: primary,
            ),
          ),
          Positioned(
            right: 12,
            child: GestureDetector(
              onTap: saving ? null : onSave,
              child: Container(
                height: 38,
                constraints: const BoxConstraints(minWidth: 74),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _wash,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: ProfileTheme.ink,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ProfileTheme.ink,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The photo in its gradient ring with a small camera badge, over
/// "Change photo". Tapping either changes it.
class _PhotoPicker extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final VoidCallback onTap;
  const _PhotoPicker({
    required this.avatarUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileRingAvatar(
            avatarUrl: avatarUrl,
            name: name,
            size: 92,
            badge: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: ProfileTheme.ink,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(10),
          const Text(
            'Change photo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
        ],
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
      '$count / $max',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: nearLimit ? _red : ProfileTheme.textSecondary(context),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// The one input style on this screen: a soft grey fill, no outline until
/// focused. Leads with a line [icon], a brand logo [asset] in a small grey
/// circle, or nothing.
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
  }) : assert(icon == null || asset == null);

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines > 1;
    final primary = ProfileTheme.textPrimary(context);
    final hasLead = icon != null || asset != null;
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
        prefixIcon: !hasLead
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                child: asset != null
                    ? Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.08),
                        ),
                        child: Image.asset(asset!, width: 15, height: 15),
                      )
                    : Icon(icon, size: 20, color: primary),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: primary.withValues(alpha: 0.045),
        contentPadding: EdgeInsets.fromLTRB(
          hasLead ? 0 : 16,
          multiline ? 14 : 15,
          14,
          15,
        ),
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(_accent.withValues(alpha: 0.6), 1.2),
        errorBorder: _border(_red.withValues(alpha: 0.7), 1.2),
        focusedErrorBorder: _border(_red, 1.5),
      ),
    );
  }
}
