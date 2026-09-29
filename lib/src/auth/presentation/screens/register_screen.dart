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

/// Name, email and password, the Get Started button and the login link, on
/// the same animated auth card as the login screen.
class RegisterScreen extends HookConsumerWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtr = useTextEditingController();
    final userNameCtr = useTextEditingController();
    final passwordCtr = useTextEditingController();
    final isObscure = useState(true);
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

    void handleRegister() {
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
      title: 'Create account',
      subtitle: "Let's create your account together",
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
        Gap(context.sc(28)),
        AuthGradientButton(
          label: 'Get Started',
          isLoading: registerState.isLoading,
          onTap: registerState.isLoading ? null : handleRegister,
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
