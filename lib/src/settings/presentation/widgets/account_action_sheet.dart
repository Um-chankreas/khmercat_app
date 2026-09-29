import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

const _red = Color(0xffE5484D);
const _amber = Color(0xffF59E0B);

/// Personal account only: confirms with the password, then deactivates the
/// account (hidden until the next login). Returns true once it's done and
/// the session has ended; false if cancelled.
Future<bool> confirmDeactivateAccount(BuildContext context) {
  final l = AppLocalizations.of(context);
  return _show(
    context,
    _AccountActionSheet(
      color: _amber,
      icon: Icons.visibility_off_rounded,
      title: l.deactivateAccountTitle,
      points: [
        l.deactivateAccountPoint1,
        l.deactivateAccountPoint2,
        l.deactivateAccountPoint3,
      ],
      confirmText: l.deactivateAction,
      run: (ref, password) =>
          ref.read(authControllerProvider.notifier).deactivateAccount(password),
    ),
  );
}

/// Personal account only: confirms with the password, then permanently
/// deletes the account. Returns true once it's gone; false if cancelled.
Future<bool> confirmDeleteAccount(BuildContext context) {
  final l = AppLocalizations.of(context);
  return _show(
    context,
    _AccountActionSheet(
      color: _red,
      icon: Icons.delete_forever_rounded,
      title: l.deleteAccountTitle,
      points: [
        l.deleteAccountPoint1,
        l.deleteAccountPoint2,
        l.deleteAccountPoint3,
      ],
      footnote: l.deleteAccountAlternative,
      confirmText: l.deleteAction,
      run: (ref, password) =>
          ref.read(authControllerProvider.notifier).deleteAccount(password),
    ),
  );
}

Future<bool> _show(BuildContext context, Widget sheet) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: sheet,
    ),
  );
  return done ?? false;
}

/// Icon, title, what happens (bullets), password field and Cancel/confirm.
/// Wrong passwords are shown inline under the field.
class _AccountActionSheet extends HookConsumerWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> points;
  final String? footnote;
  final String confirmText;
  final Future<void> Function(WidgetRef ref, String password) run;
  const _AccountActionSheet({
    required this.color,
    required this.icon,
    required this.title,
    required this.points,
    required this.confirmText,
    required this.run,
    this.footnote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ctr = useTextEditingController();
    final obscure = useState(true);
    final loading = useState(false);
    final error = useState<String?>(null);
    final canSubmit = useListenableSelector(ctr, () => ctr.text.isNotEmpty);
    final muted = ProfileTheme.textSecondary(context);

    Future<void> submit() async {
      if (ctr.text.isEmpty || loading.value) return;
      loading.value = true;
      error.value = null;
      try {
        await run(ref, ctr.text);
        if (context.mounted) Navigator.of(context).pop(true);
      } on ApiException catch (e) {
        HapticFeedback.heavyImpact();
        error.value = e.fieldError('password') ?? e.message;
      } catch (_) {
        error.value = l.accountActionFailed;
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(18),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
              ),
              const Gap(12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in points)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 14,
                                color: color,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: ProfileTheme.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (footnote != null) ...[
                const Gap(8),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ],
              const Gap(14),
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
                  hintText: l.confirmPasswordHint,
                  errorText: error.value,
                  filled: true,
                  fillColor: color.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: color,
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
                  focusedBorder: border(color, 1.4),
                  errorBorder: border(_red),
                  focusedErrorBorder: border(_red, 1.4),
                ),
              ),
              const Gap(16),
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
                      ),
                      child: Text(
                        l.cancelAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSubmit && !loading.value ? submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor: color.withValues(alpha: 0.35),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                              confirmText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
