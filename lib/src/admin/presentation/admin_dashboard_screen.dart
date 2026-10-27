import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_reports_screen.dart';
import 'admin_restaurants_screen.dart';
import 'admin_users_screen.dart';
import 'admin_widgets.dart';

/// Which admin tab a dashboard tile or "See all" opens.
abstract final class AdminTab {
  static const home = 0;
  static const restaurants = 1;
  static const reports = 2;
  static const settings = 3;
}

/// Admin → Home: what needs doing (restaurants to approve, open reports),
/// how big the app is, and the newest of each to act on right here.
class AdminDashboardScreen extends HookConsumerWidget {
  final ValueChanged<int> onOpenTab;
  const AdminDashboardScreen({required this.onOpenTab, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read up front: the actions below use them after awaiting.
    final l10n = context.l10n;
    final admin = ref.read(adminRemoteDataSourceProvider);
    final summary = ref.watch(adminSummaryProvider);
    final me = ref.watch(currentUserProvider);

    // The two newest of each, reloaded with the summary.
    final previewKey = useState(0);
    final pending = useFuture(
      useMemoized(
        () => admin
            .restaurants('pending', 1)
            .then((p) => p.items.take(2).toList()),
        [previewKey.value],
      ),
    );
    final reports = useFuture(
      useMemoized(
        () => admin.reports('open', 1).then((p) => p.items.take(2).toList()),
        [previewKey.value],
      ),
    );
    final busy = useState(<String>{});

    Future<void> refresh() async {
      previewKey.value++;
      ref.invalidate(adminSummaryProvider);
      await ref
          .read(adminSummaryProvider.future)
          .catchError(
            (_) => AdminSummary(
              pendingRestaurants: 0,
              openReports: 0,
              users: 0,
              usersThisWeek: 0,
              activeRestaurants: 0,
              bannedUsers: 0,
            ),
          );
    }

    Future<void> act(
      AdminRestaurant r,
      Future<void> Function() call,
      String done,
    ) async {
      busy.value = {...busy.value, r.id};
      try {
        await call();
        AppService.showToast(done);
        await refresh();
      } catch (_) {
        AppService.showToast(l10n.adminSomethingWrong, isError: true);
      } finally {
        if (context.mounted) busy.value = {...busy.value}..remove(r.id);
      }
    }

    Future<void> reject(AdminRestaurant r) async {
      final reason = await askAdminReason(
        context,
        title: context.l10n.adminRejectTitle(r.name),
        hint: context.l10n.adminReasonForOwner,
        confirm: context.l10n.adminReject,
      );
      if (reason == null) return;
      await act(
        r,
        () => admin.reject(r.id, reason: reason.isEmpty ? null : reason),
        l10n.adminRejected,
      );
    }

    final s = summary.valueOrNull;
    final firstName = (me?.name ?? 'Admin').split(' ').first;

    return Column(
      children: [
        AdminHeader(
          title: 'KhmerCat',
          overline: context.l10n.adminHi(firstName),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.paddingOf(context).bottom + 110,
              ),
              children: [
                if (summary.hasError && s == null)
                  AdminMessage(
                    icon: Icons.cloud_off_rounded,
                    text: context.l10n.adminDashboardLoadFailed,
                    onRetry: refresh,
                    // Already inside this ListView.
                    scrollable: false,
                  )
                else ...[
                  _TileGrid(
                    children: [
                      _Tile(
                        icon: Icons.storefront_outlined,
                        value: s == null ? '–' : '${s.pendingRestaurants}',
                        label: context.l10n.adminTileToApprove,
                        highlight: true,
                        onTap: () => onOpenTab(AdminTab.restaurants),
                      ),
                      _Tile(
                        icon: Icons.outlined_flag_rounded,
                        value: s == null ? '–' : '${s.openReports}',
                        label: context.l10n.adminTileOpenReports,
                        highlight: true,
                        onTap: () => onOpenTab(AdminTab.reports),
                      ),
                      _Tile(
                        icon: Icons.people_outline_rounded,
                        value: s == null ? '–' : adminCount(s.users),
                        label: s == null
                            ? context.l10n.adminUsers
                            : context.l10n.adminTileUsersWeek(s.usersThisWeek),
                        onTap: () => openAdminUsers(context),
                      ),
                      _Tile(
                        icon: Icons.verified_user_outlined,
                        value: s == null
                            ? '–'
                            : adminCount(s.activeRestaurants),
                        label: context.l10n.adminTileActiveRestaurants,
                        onTap: () => onOpenTab(AdminTab.restaurants),
                      ),
                    ],
                  ),
                  Gap(24),
                  AdminSectionTitle(
                    title: context.l10n.adminWaitingApproval,
                    action: (s?.pendingRestaurants ?? 0) > 0
                        ? context.l10n.adminSeeAll(s!.pendingRestaurants)
                        : null,
                    onAction: () => onOpenTab(AdminTab.restaurants),
                  ),
                  _Preview(
                    loading: pending.connectionState != ConnectionState.done,
                    empty: context.l10n.adminNoRestaurantsWaiting,
                    children: [
                      for (final r in pending.data ?? <AdminRestaurant>[])
                        PendingRestaurantCard(
                          restaurant: r,
                          bare: true,
                          busy: busy.value.contains(r.id),
                          onReject: () => reject(r),
                          onApprove: () => act(
                            r,
                            () => admin.approve(r.id),
                            context.l10n.adminApproved,
                          ),
                        ),
                    ],
                  ),
                  Gap(24),
                  AdminSectionTitle(
                    title: context.l10n.adminLatestReports,
                    action: (s?.openReports ?? 0) > 0
                        ? context.l10n.adminSeeAll(s!.openReports)
                        : null,
                    onAction: () => onOpenTab(AdminTab.reports),
                  ),
                  _Preview(
                    loading: reports.connectionState != ConnectionState.done,
                    empty: context.l10n.adminNoOpenReports,
                    children: [
                      for (final v in reports.data ?? <ReportedVideo>[])
                        _ReportRow(
                          report: v,
                          onTap: () => onOpenTab(AdminTab.reports),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiles two by two, each pair as tall as its taller tile.
class _TileGrid extends StatelessWidget {
  final List<Widget> children;
  const _TileGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) Gap(10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                Gap(10),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          gradient: highlight ? AdminColors.softWash(context) : null,
          color: highlight ? null : AdminColors.card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: AdminColors.shadow(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AdminColors.card(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: AdminColors.ink(context)),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AdminColors.muted(context),
                ),
              ],
            ),
            Gap(10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: AdminColors.ink(context),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AdminColors.sub(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card of preview rows, or a spinner / empty line.
class _Preview extends StatelessWidget {
  final bool loading;
  final String empty;
  final List<Widget> children;
  const _Preview({
    required this.loading,
    required this.empty,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return AdminCard(
        padding: EdgeInsets.all(18),
        children: [
          Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(empty, style: adminSubStyle(context)),
          ),
        ],
      );
    }
    return AdminCard(children: children);
  }
}

class _ReportRow extends StatelessWidget {
  final ReportedVideo report;
  final VoidCallback onTap;
  const _ReportRow({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = report;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ReportThumb(report: v, width: 46, height: 60, label: false),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportReasonLabel(context, v.topReason),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: adminTitleStyle(context),
                  ),
                  Text(
                    context.l10n.adminVideoBy(v.authorUsername ?? 'unknown'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: adminSubStyle(context),
                  ),
                ],
              ),
            ),
            Gap(8),
            AdminPill(
              context.l10n.adminReportsCount(v.reportsCount),
              tone: AdminPillTone.danger,
            ),
          ],
        ),
      ),
    );
  }
}
