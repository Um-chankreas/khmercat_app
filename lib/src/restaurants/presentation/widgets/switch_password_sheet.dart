import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/image_user_circle_profile.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';

/// Asks for the account password and switches back to the personal
/// profile (like Facebook when leaving a Page). Returns true once switched;
/// false if the user cancelled. Wrong passwords are shown inline.
Future<bool> confirmSwitchToPersonal(BuildContext context) async {
  final switched = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      // Keep the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: const _SwitchPasswordSheet(),
    ),
  );
  return switched ?? false;
}

class _SwitchPasswordSheet extends HookConsumerWidget {
  const _SwitchPasswordSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final ctr = useTextEditingController();
    final obscure = useState(true);
    final loading = useState(false);
    final error = useState<String?>(null);
    final canSubmit = useListenableSelector(ctr, () => ctr.text.isNotEmpty);
    final muted = ProfileTheme.textSecondary(context);
    final name = user?.name ?? '';

    Future<void> submit() async {
      if (ctr.text.isEmpty || loading.value) return;
      loading.value = true;
      error.value = null;
      final failure = await ref
          .read(myRestaurantsControllerProvider.notifier)
          .switchToPersonal(ctr.text);
      if (!context.mounted) return;
      loading.value = false;
      if (failure == null) {
        Navigator.of(context).pop(true);
      } else {
        HapticFeedback.heavyImpact();
        error.value = failure;
        ctr.selection = TextSelection(
          baseOffset: 0,
          extentOffset: ctr.text.length,
        );
      }
    }

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        // Scrolls when the keyboard leaves too little room for the whole sheet.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(18),
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ProfileTheme.gradient,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: ImageUserCircleProfile(
                    imageUrl: user?.profilePicture,
                    name: name,
                    size: 64,
                  ),
                ),
              ),
              const Gap(12),
              Text(
                l.confirmSwitchTitle(name),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(4),
              Text(
                l.confirmSwitchMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: muted),
              ),
              const Gap(18),
              TextField(
                controller: ctr,
                autofocus: true,
                obscureText: obscure.value,
                enabled: !loading.value,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                onChanged: (_) {
                  if (error.value != null) error.value = null;
                },
                decoration: InputDecoration(
                  hintText: l.passwordHint,
                  errorText: error.value,
                  filled: true,
                  fillColor: ProfileTheme.purple.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: ProfileTheme.pink,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => obscure.value = !obscure.value,
                    icon: Icon(
                      obscure.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: muted,
                    ),
                  ),
                  border: border(ProfileTheme.hairlineColor(context)),
                  enabledBorder: border(ProfileTheme.hairlineColor(context)),
                  focusedBorder: border(ProfileTheme.pink, 1.4),
                  errorBorder: border(const Color(0xffEF4444)),
                  focusedErrorBorder: border(const Color(0xffEF4444), 1.4),
                ),
              ),
              const Gap(18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: loading.value
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.cancelAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: GestureDetector(
                      onTap: canSubmit && !loading.value ? submit : null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: canSubmit ? 1 : 0.5,
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: ProfileTheme.pinkPurple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: loading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l.continueAction,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
