import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_ban_sheet.dart';
import 'admin_paged.dart';
import 'admin_widgets.dart';

const _filters = ['all', 'reported', 'banned'];

/// Opens Users as its own page, over the admin area.
Future<void> openAdminUsers(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SoftCirclesBackdrop()),
          SafeArea(child: AdminUsersScreen(pushed: true)),
        ],
      ),
    ),
  ),
);

/// Admin → Users: find anyone by name, @username, email or phone; see who's
/// reported or banned; ban or unban.
class AdminUsersScreen extends HookConsumerWidget {
  /// Opened as its own page (from Settings or the dashboard): a back arrow.
  final bool pushed;
  const AdminUsersScreen({this.pushed = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read up front: the actions below use them after awaiting.
    final l10n = context.l10n;
    final filter = useState(0);
    final search = useTextEditingController();
    final query = useState('');
    final scroll = useScrollController();
    final admin = ref.read(adminRemoteDataSourceProvider);

    // Search as they type, once they pause.
    final debounce = useRef<Timer?>(null);
    useEffect(
      () =>
          () => debounce.value?.cancel(),
      [],
    );

    final list = useAdminPaged<AdminUser>(
      (page) => admin.users(_filters[filter.value], page, query: query.value),
      [filter.value, query.value],
    );
    useLoadMoreOnScroll(scroll, list.loadMore);

    Future<void> ban(AdminUser u) async {
      final banned = await showBanSheet(
        context,
        BanTarget(
          id: u.id,
          name: u.name,
          username: u.username,
          picture: u.picture,
          videosCount: u.videosCount,
          reportsCount: u.openReportsCount,
        ),
      );
      if (banned) list.reload();
    }

    void unban(AdminUser u) => AppDialogs.showConfirm(
      context,
      title: context.l10n.adminUnbanTitle(u.username),
      message: context.l10n.adminUnbanMessage,
      confirmText: context.l10n.adminUnban,
      cancelText: context.l10n.cancelAction,
      onConfirm: () async {
        try {
          await admin.unban(u.id);
          ref.invalidate(adminSummaryProvider);
          AppService.showToast(l10n.adminUnbannedToast(u.username));
          list.reload();
        } catch (_) {
          AppService.showToast(l10n.adminUnbanFailed, isError: true);
        }
      },
    );

    String chip(String name, String key) {
      final n = list.counts[key];
      return n == null || n == 0 ? name : '$name · $n';
    }

    final Widget body;
    if (list.isEmptyLoading) {
      body = Center(child: CircularProgressIndicator());
    } else if (list.items.isEmpty && list.failed) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: context.l10n.adminUsersLoadFailed,
        onRetry: list.reload,
      );
    } else if (list.items.isEmpty) {
      body = AdminMessage(
        icon: Icons.people_outline_rounded,
        text: query.value.isNotEmpty
            ? context.l10n.adminNoMatch(query.value)
            : switch (filter.value) {
                1 => context.l10n.adminNoReported,
                2 => context.l10n.adminNoBanned,
                _ => context.l10n.adminNoUsers,
              },
      );
    } else {
      body = ListView(
        controller: scroll,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + (pushed ? 24 : 110),
        ),
        children: [
          AdminCard(
            children: [
              for (final u in list.items)
                _UserRow(
                  user: u,
                  onBan: u.isAdmin || u.isBanned ? null : () => ban(u),
                  onUnban: u.isBanned ? () => unban(u) : null,
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        AdminHeader(
          title: context.l10n.adminUsers,
          onBack: pushed ? () => Navigator.of(context).maybePop() : null,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AdminColors.card(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AdminColors.shadow(context),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AdminColors.sub(context),
                ),
                Gap(10),
                Expanded(
                  child: TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) {
                      debounce.value?.cancel();
                      debounce.value = Timer(
                        Duration(milliseconds: 350),
                        () => query.value = v.trim(),
                      );
                    },
                    onSubmitted: (v) => query.value = v.trim(),
                    style: TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: context.l10n.adminSearchUsers,
                      hintStyle: TextStyle(color: AdminColors.muted(context)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AdminChips(
          labels: [
            context.l10n.adminFilterAll,
            chip(context.l10n.adminFilterReported, 'reported'),
            chip(context.l10n.adminFilterBanned, 'banned'),
          ],
          selected: filter.value,
          onChanged: (i) => filter.value = i,
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: list.reload, child: body),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;
  const _UserRow({required this.user, this.onBan, this.onUnban});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final String sub;
    if (u.isBanned) {
      sub = u.bannedUntil == null
          ? '@${u.username} · ${context.l10n.adminBannedForGood}'
          : '@${u.username} · '
                '${context.l10n.adminBannedUntil(adminDate(context, u.bannedUntil!))}';
    } else {
      sub = '@${u.username} · ${context.l10n.adminVideosCount(u.videosCount)}';
    }
    return InkWell(
      onTap: () => AppRouter.router.pushNamed(
        AppRoute.userProfile.name,
        pathParameters: {'username': u.username},
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AdminAvatar(url: u.picture, name: u.name),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: adminTitleStyle(context),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: adminSubStyle(context),
                  ),
                ],
              ),
            ),
            if (u.isAdmin)
              AdminPill(context.l10n.adminRoleAdmin)
            else if (u.isBanned)
              AdminPill(context.l10n.adminFilterBanned)
            else if (u.openReportsCount > 0)
              AdminPill(
                context.l10n.adminReportsCount(u.openReportsCount),
                tone: AdminPillTone.danger,
              ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AdminColors.muted(context),
              ),
              onSelected: (v) => switch (v) {
                'ban' => onBan?.call(),
                'unban' => onUnban?.call(),
                _ => AppRouter.router.pushNamed(
                  AppRoute.userProfile.name,
                  pathParameters: {'username': u.username},
                ),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'view',
                  child: Text(context.l10n.adminViewProfile),
                ),
                if (onBan != null)
                  PopupMenuItem(
                    value: 'ban',
                    child: Text(
                      context.l10n.adminBanUser,
                      style: TextStyle(color: AdminColors.danger),
                    ),
                  ),
                if (onUnban != null)
                  PopupMenuItem(
                    value: 'unban',
                    child: Text(context.l10n.adminUnban),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
