import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button_gradient.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/extensions/safe_area_extension.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/login_viewmodel.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtr = useTextEditingController();
    final passwordCtr = useTextEditingController();
    final isObscure = ValueNotifier<bool>(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final loginState = ref.watch(loginViewModelProvider);

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      ),
      child: GestureDetector(
        onTap: () => AppService.dismissKeyboard(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          resizeToAvoidBottomInset: true,

          body: Form(
            key: formKey,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.appPrimaryPink, AppColors.appPrimaryBlue],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: context.toolbarHeight),

                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                height: context.sc(40),
                                width: context.sc(40),
                                margin: EdgeInsets.only(left: context.sc(16)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: context.all(10),
                                    child: Image.asset(AssetsName.back),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  height: context.sc(200),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        AssetsName.appLogoTrsm,
                                        width: context.sc(150),
                                      ),
                                      Gap(context.sc(8)),
                                      Text(
                                        "KhmerCat",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: const Color(0xff303030),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(
                                left: context.s(16),
                                right: context.s(16),
                                top: context.s(32),
                                bottom: context.s(
                                  context.safeBottomPadding(32),
                                ),
                              ),

                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(36),
                                  topRight: Radius.circular(36),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Welcome back",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    "Login to your account to continue",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: AppColors.lightGrey),
                                  ),
                                  Gap(context.sc(24)),
                                  TextFormField(
                                    controller: emailCtr,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please input email";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Username or email",
                                      errorText: apiException?.fieldError(
                                        'email',
                                      ),
                                    ),
                                  ),
                                  Gap(context.sc(16)),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: isObscure,
                                    builder: (context, obscure, child) =>
                                        TextFormField(
                                          obscureText: obscure,
                                          controller: passwordCtr,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return "Please input password";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Password",
                                            suffixIconConstraints:
                                                BoxConstraints(
                                                  minWidth:
                                                      10, // Set minimum width
                                                  minHeight:
                                                      10, // Set minimum height
                                                ),
                                            suffixIcon: InkWell(
                                              onTap: () =>
                                                  isObscure.value = !obscure,
                                              child: Padding(
                                                padding: context.sym(h: 8),
                                                child: Image.asset(
                                                  obscure
                                                      ? AssetsName
                                                            .openEyePassword
                                                      : AssetsName
                                                            .closeEyePassword,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  width: context.sc(18),
                                                  height: context.sc(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                  Gap(context.sc(8)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GradientText(
                                        "Forgot password",

                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  Gap(context.sc(32)),
                                  AppTextButtonGradient(
                                    onTap: loginState.isLoading
                                        ? null
                                        : () => handleLogin(),
                                    isLoading: loginState.isLoading,
                                    text: "Login",
                                    height: 45,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  Gap(context.sc(16)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Don't have an account?",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: AppColors.lightGrey
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                      Gap(context.sc(5)),
                                      GestureDetector(
                                        onTap: () => AppRouter.router.pushNamed(
                                          AppRoute.createAccount.name,
                                        ),
                                        child: GradientText(
                                          "Sign up",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
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
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
