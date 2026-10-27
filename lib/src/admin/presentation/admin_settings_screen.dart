import 'package:flutter/material.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/profile_switching_screen.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/settings/app_settings_controller.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_paged.dart';
import 'admin_users_screen.dart';
import 'admin_widgets.dart';

/// Admin → Settings: who's signed in, the activity log, and the way out.
class AdminSettingsScreen extends ConsumerWidget {
  /// "Back to KhmerCat" — only when the admin area was opened from the app.
  final bool showBackToApp;
  const AdminSettingsScreen({this.showBackToApp = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageLabel = switch (locale?.languageCode) {
      'en' => l.languageEnglish,
      'km' => l.languageKhmer,
      _ => l.themeSystem,
    };
    void setDark(bool dark) => ref
        .read(themeModeControllerProvider.notifier)
        .set(dark ? ThemeMode.dark : ThemeMode.light);

    Widget row({
      IconData? icon,
      String? asset,
      Widget? trailing,
      required String title,
      String? subtitle,
      Color? color,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AdminColors.softWash(context),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: asset != null
                    ? Image.asset(
                        asset,
                        width: 19,
                        height: 19,
                        color: color ?? AdminColors.ink(context),
                      )
                    : Icon(
                        icon,
                        size: 19,
                        color: color ?? AdminColors.ink(context),
                      ),
              ),
            ),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: adminTitleStyle(
                      context,
                    ).copyWith(color: color ?? AdminColors.ink(context)),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: adminSubStyle(context)),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (color == null)
              Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.muted(context),
              ),
          ],
        ),
      ),
    );

    Widget section(String title) => Padding(
      padding: EdgeInsets.fromLTRB(4, 22, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AdminColors.muted(context),
        ),
      ),
    );

    return Column(
      children: [
        AdminHeader(title: context.l10n.adminNavSettings),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.paddingOf(context).bottom + 110,
            ),
            children: [
              AdminCard(
                padding: EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      // The KhmerCat logo stands for the admin account.
                      Container(
                        width: 52,
                        height: 52,
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AdminColors.softWash(context),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(AssetsName.appLogoTrsm),
                      ),
                      Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me?.name ?? '',
                              style: adminTitleStyle(context),
                            ),
                            Text(
                              me?.email ?? '',
                              style: adminSubStyle(context),
                            ),
                          ],
                        ),
                      ),
                      AdminPill(
                        context.l10n.adminRoleAdmin,
                        tone: AdminPillTone.success,
                      ),
                    ],
                  ),
                ],
              ),
              section(context.l10n.adminPeople),
              AdminCard(
                children: [
                  row(
                    asset: AssetsName.friends,
                    title: context.l10n.adminUsers,
                    subtitle: context.l10n.adminUsersRowSub,
                    onTap: () => openAdminUsers(context),
                  ),
                ],
              ),
              section(context.l10n.adminActivity),
              AdminCard(
                children: [
                  row(
                    icon: Icons.history_rounded,
                    title: context.l10n.adminActivityLog,
                    subtitle: context.l10n.adminActivityLogSub,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminActivityScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              section(l.preferences),
              AdminCard(
                children: [
                  row(
                    icon: Icons.language_rounded,
                    title: l.language,
                    subtitle: languageLabel,
                    onTap: () => _pickLanguage(context, ref, l, locale),
                  ),
                  row(
                    icon: isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: l.darkMode,
                    subtitle: switch (themeMode) {
                      ThemeMode.light => l.themeLight,
                      ThemeMode.dark => l.themeDark,
                      ThemeMode.system => l.themeSystem,
                    },
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AdminColors.accent,
                      onChanged: setDark,
                    ),
                    onTap: () => setDark(!isDark),
                  ),
                ],
              ),
              section(context.l10n.adminAccount),
              AdminCard(
                children: [
                  if (showBackToApp)
                    row(
                      icon: Icons.arrow_back_rounded,
                      title: context.l10n.adminBackToApp,
                      subtitle: context.l10n.adminBackToAppSub,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  row(
                    icon: Icons.logout_rounded,
                    title: l.logOut,
                    color: AdminColors.danger,
                    onTap: () => AppDialogs.showConfirm(
                      context,
                      title: l.logOutConfirmTitle,
                      message: l.logOutConfirmMessage,
                      confirmText: l.logOut,
                      cancelText: l.cancelAction,
                      isDestructive: true,
                      onConfirm: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        showLoggingOut(context, ref);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// System / English / ខ្មែរ, as in the app's Settings.
Future<void> _pickLanguage(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l,
  Locale? current,
) {
  final controller = ref.read(localeControllerProvider.notifier);
  final options = <(String?, String)>[
    (null, l.themeSystem),
    ('en', l.languageEnglish),
    ('km', l.languageKhmer),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AdminColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label) in options)
            ListTile(
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AdminColors.ink(sheet),
                ),
              ),
              trailing: current?.languageCode == code
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AdminColors.accent,
                    )
                  : null,
              onTap: () {
                controller.set(code == null ? null : Locale(code));
                Navigator.pop(sheet);
              },
            ),
          const Gap(8),
        ],
      ),
    ),
  );
}

/// Every admin action, latest first.
class AdminActivityScreen extends HookConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.read(adminRemoteDataSourceProvider);
    final me = ref.watch(currentUserProvider)?.id;
    final scroll = useScrollController();
    final list = useAdminPaged<AdminActivity>((page) async {
      final r = await admin.activity(page);
      return (items: r.items, hasMore: r.hasMore, counts: <String, int>{});
    }, []);
    useLoadMoreOnScroll(scroll, list.loadMore);

    final Widget body;
    if (list.isEmptyLoading) {
      body = Center(child: CircularProgressIndicator());
    } else if (list.items.isEmpty && list.failed) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: context.l10n.adminLogLoadFailed,
        onRetry: list.reload,
      );
    } else if (list.items.isEmpty) {
      body = AdminMessage(
        icon: Icons.history_rounded,
        text: context.l10n.adminNothingDone,
      );
    } else {
      body = ListView(
        controller: scroll,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          AdminCard(
            children: [
              for (final a in list.items) _ActivityRow(activity: a, myId: me),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SoftCirclesBackdrop()),
          SafeArea(
            child: Column(
              children: [
                MenuTitleBar(title: context.l10n.adminActivityTitle),
                Expanded(
                  child: RefreshIndicator(onRefresh: list.reload, child: body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final AdminActivity activity;
  final String? myId;
  const _ActivityRow({required this.activity, required this.myId});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final l = context.l10n;
    final t = a.summary;
    final (IconData icon, String text, Color color) = switch (a.action) {
      'approve' => (
        Icons.check_circle_outline_rounded,
        l.adminActApprove(t),
        AdminColors.green(context),
      ),
      'reject' => (
        Icons.cancel_outlined,
        l.adminActReject(t),
        AdminColors.danger,
      ),
      'deactivate' => (
        Icons.pause_circle_outline_rounded,
        l.adminActDeactivate(t),
        AdminColors.danger,
      ),
      'activate' => (
        Icons.play_circle_outline_rounded,
        l.adminActActivate(t),
        AdminColors.green(context),
      ),
      'remove_video' => (
        Icons.delete_outline_rounded,
        l.adminActRemoveVideo(t),
        AdminColors.danger,
      ),
      'dismiss_reports' => (
        Icons.outlined_flag_rounded,
        l.adminActDismiss(t),
        AdminColors.sub(context),
      ),
      'ban' => (Icons.block_rounded, l.adminActBan(t), AdminColors.danger),
      'unban' => (
        Icons.lock_open_rounded,
        l.adminActUnban(t),
        AdminColors.green(context),
      ),
      _ => (Icons.circle_outlined, '${a.action} $t', AdminColors.sub(context)),
    };
    final who = a.adminId != null && a.adminId == myId
        ? l.adminYou
        : (a.adminName ?? l.adminAnAdmin);
    final when = a.createdAt == null
        ? ''
        : DateFormat('d MMM, HH:mm', l.localeName).format(a.createdAt!);
    final reason = a.reason == null
        ? null
        : (banReasons.contains(a.reason)
              ? banReasonLabel(context, a.reason!)
              : a.reason);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: adminTitleStyle(context).copyWith(fontSize: 14.5),
                ),
                Text(
                  [who, when, ?reason].where((s) => s.isNotEmpty).join(' · '),
                  style: adminSubStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
