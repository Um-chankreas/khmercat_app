import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/app_log.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/register_viewmodel.dart';
import 'package:khmer_cat_app/src/auth/presentation/widgets/auth_widgets.dart';

/// "Join khmercat", name, email and password, the Get Started button and the
/// login link, on the same glass auth card as the login screen.
class RegisterScreen extends HookConsumerWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtr = useTextEditingController();
    final userNameCtr = useTextEditingController();
    final passwordCtr = useTextEditingController();
    final isObscure = useState(true);
    final acceptedTerms = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final registerState = ref.watch(registerViewModelProvider);
    useListenable(emailCtr);

    final apiException =
        registerState.hasError && registerState.error is ApiException
        ? registerState.error as ApiException
        : null;
    ref.listen(registerViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) {
          AppService.showToast(
            err is ApiException ? err.message : 'Something went wrong.',
          );
        },
        data: (auth) {
          if (auth != null) {
            AppLog.success("registered => ${auth.user.email}");
            final target = userType == 'restaurant_user'
                ? AppRoute.onboadingRestaurant.name
                : AppRoute.onboadingNormalUser.name;
            AppRouter.router.pushReplacementNamed(target);
          }
        },
      );
    });

    /// Opens the Terms with Decline / Accept; accepting ticks the box.
    Future<void> openTerms() async {
      final accepted = await AppRouter.router.pushNamed<bool>(
        AppRoute.termsOfService.name,
        extra: true,
      );
      if (accepted != null) acceptedTerms.value = accepted;
    }

    void handleRegister() {
      if (!acceptedTerms.value) {
        AppService.showToast('Please accept the Terms of Service to sign up.');
        return;
      }
      if (formKey.currentState?.validate() ?? false) {
        AppService.dismissKeyboard(context);
        ref
            .read(registerViewModelProvider.notifier)
            .register(
              name: userNameCtr.text,
              email: emailCtr.text,
              password: passwordCtr.text,
            );
      }
    }

    final emailLooksValid = authEmailPattern.hasMatch(emailCtr.text.trim());

    return AuthScaffold(
      formKey: formKey,
      title: 'Join khmercat',
      titleWidget: const AuthBrandTitle(lead: 'Join'),
      showBrand: false,
      // Below center, so the cat's face shows above the card.
      cardAlignment: const Alignment(0, 0.45),
      children: [
        TextFormField(
          controller: userNameCtr,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please input your name';
            }
            return null;
          },
          decoration: authFieldDecoration(
            context,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
            errorText: apiException?.fieldError('name'),
          ),
        ),
        Gap(context.sc(14)),
        TextFormField(
          controller: emailCtr,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please input email';
            }
            if (!value.contains('@')) {
              return 'Please input a valid email';
            }
            return null;
          },
          decoration: authFieldDecoration(
            context,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            errorText: apiException?.fieldError('email'),
            suffix: emailLooksValid ? const AuthValidTick() : null,
          ),
        ),
        Gap(context.sc(14)),
        TextFormField(
          controller: passwordCtr,
          obscureText: isObscure.value,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) {
            if (!registerState.isLoading) handleRegister();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please input password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: authFieldDecoration(
            context,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            errorText: apiException?.fieldError('password'),
            suffix: AuthObscureToggle(
              obscure: isObscure.value,
              onToggle: () => isObscure.value = !isObscure.value,
            ),
          ),
        ),
        Gap(context.sc(16)),
        _TermsCheckbox(
          accepted: acceptedTerms.value,
          // Ticking means reading them first; unticking is direct.
          onToggle: () =>
              acceptedTerms.value ? acceptedTerms.value = false : openTerms(),
          onOpenTerms: openTerms,
        ),
        Gap(context.sc(20)),
        AuthGradientButton(
          label: 'Get Started',
          isLoading: registerState.isLoading,
          onTap: registerState.isLoading || !acceptedTerms.value
              ? null
              : handleRegister,
        ),
        Gap(context.sc(20)),
        AuthFooterLink(
          prompt: 'Already have an account?',
          action: 'Login',
          onTap: () => AppRouter.router.pushNamed(AppRoute.login.name),
        ),
      ],
    );
  }
}

/// "☐ I agree to the Terms of Service" — the link opens them.
class _TermsCheckbox extends StatelessWidget {
  final bool accepted;
  final VoidCallback onToggle;
  final VoidCallback onOpenTerms;
  const _TermsCheckbox({
    required this.accepted,
    required this.onToggle,
    required this.onOpenTerms,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall!;
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: accepted,
            onChanged: (_) => onToggle(),
            activeColor: authAccentPink,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(color: authMuted(context), width: 1.5),
          ),
        ),
        Gap(context.sc(10)),
        Expanded(
          child: GestureDetector(
            onTap: onToggle,
            child: Text.rich(
              TextSpan(
                style: style.copyWith(color: authMuted(context)),
                children: [
                  const TextSpan(text: 'I have read and agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: onOpenTerms,
                      child: Text(
                        'Terms of Service',
                        style: style.copyWith(
                          color: authAccentPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
