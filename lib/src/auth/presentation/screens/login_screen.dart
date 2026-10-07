import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/login_viewmodel.dart';
import 'package:khmer_cat_app/src/auth/presentation/widgets/auth_widgets.dart';

/// "Welcome to khmercat", email + password, forgot password, Login button
/// and the sign-up link, on the shared glass auth card over the cat
/// backdrop.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtr = useTextEditingController();
    final passwordCtr = useTextEditingController();
    final isObscure = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final loginState = ref.watch(loginViewModelProvider);
    useListenable(emailCtr);

    final apiException = loginState.hasError && loginState.error is ApiException
        ? loginState.error as ApiException
        : null;
    ref.listen(loginViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) {
          AppService.showToast(
            err is ApiException ? err.message : 'Something went wrong.',
          );
        },
        data: (user) {
          if (user != null) {
            if (user.reactivated) {
              AppService.showToast(
                AppLocalizations.of(context).accountReactivated,
              );
            }
            AppRouter.router.pushReplacementNamed(AppRoute.index.name);
          }
        },
      );
    });

    void handleLogin() {
      if (formKey.currentState?.validate() ?? false) {
        AppService.dismissKeyboard(context);
        ref
            .read(loginViewModelProvider.notifier)
            .login(emailCtr.text, passwordCtr.text);
      }
    }

    final emailLooksValid = authEmailPattern.hasMatch(emailCtr.text.trim());

    return AuthScaffold(
      formKey: formKey,
      title: 'Welcome to khmercat',
      titleWidget: const AuthBrandTitle(),
      showBrand: false,
      // Below center, so the cat's face shows above the card.
      cardAlignment: const Alignment(0, 0.45),
      children: [
        TextFormField(
          controller: emailCtr,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please input email';
            }
            return null;
          },
          decoration: authFieldDecoration(
            context,
            hint: 'Username or email',
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
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) {
            if (!loginState.isLoading) handleLogin();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please input password';
            }
            return null;
          },
          decoration: authFieldDecoration(
            context,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            suffix: AuthObscureToggle(
              obscure: isObscure.value,
              onToggle: () => isObscure.value = !isObscure.value,
            ),
          ),
        ),
        Gap(context.sc(10)),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: authAccentPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Gap(context.sc(24)),
        AuthGradientButton(
          label: 'Login',
          isLoading: loginState.isLoading,
          onTap: loginState.isLoading ? null : handleLogin,
        ),
        Gap(context.sc(20)),
        AuthFooterLink(
          prompt: "Don't have an account?",
          action: 'Sign up',
          onTap: () => AppRouter.router.pushNamed(AppRoute.createAccount.name),
        ),
      ],
    );
  }
}
