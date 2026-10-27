import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_paged.dart';
import 'admin_widgets.dart';

const _statuses = ['pending', 'active', 'deactivated'];

/// Admin → Restaurants: approve or reject new ones, deactivate one that
/// breaks the rules, and bring a deactivated one back.
class AdminRestaurantsScreen extends HookConsumerWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read up front: the actions below use them after awaiting.
    final l10n = context.l10n;
    final tab = useState(0);
    final busy = useState(<String>{});
    final scroll = useScrollController();
    final admin = ref.read(adminRemoteDataSourceProvider);
    final list = useAdminPaged<AdminRestaurant>(
      (page) => admin.restaurants(_statuses[tab.value], page),
      [tab.value],
    );
    useLoadMoreOnScroll(scroll, list.loadMore);

    Future<void> act(
      AdminRestaurant r,
      Future<void> Function() call,
      String done,
    ) async {
      busy.value = {...busy.value, r.id};
      try {
        await call();
        HapticFeedback.lightImpact();
        list.removeWhere((x) => x.id == r.id);
        ref.invalidate(adminSummaryProvider);
        AppService.showToast(done);
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

    Future<void> deactivate(AdminRestaurant r) async {
      final reason = await askAdminReason(
        context,
        title: context.l10n.adminDeactivateTitle(r.name),
        hint: context.l10n.adminDeactivateHint,
        confirm: context.l10n.adminDeactivate,
        required: true,
      );
      if (reason == null) return;
      await act(
        r,
        () => admin.deactivate(r.id, reason),
        l10n.adminTabDeactivated,
      );
    }

    final counts = list.counts;

    final Widget body;
    if (list.isEmptyLoading) {
      body = Center(child: CircularProgressIndicator());
    } else if (list.items.isEmpty && list.failed) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: context.l10n.adminRestaurantsLoadFailed,
        onRetry: list.reload,
      );
    } else if (list.items.isEmpty) {
      body = AdminMessage(
        icon: Icons.storefront_outlined,
        text: switch (tab.value) {
          0 => context.l10n.adminNoPending,
          1 => context.l10n.adminNoActive,
          _ => context.l10n.adminNoDeactivated,
        },
      );
    } else {
      body = ListView.separated(
        controller: scroll,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        itemCount: list.items.length,
        separatorBuilder: (_, _) => Gap(12),
        itemBuilder: (_, i) {
          final r = list.items[i];
          final isBusy = busy.value.contains(r.id);
          return switch (tab.value) {
            0 => PendingRestaurantCard(
              restaurant: r,
              busy: isBusy,
              onReject: () => reject(r),
              onApprove: () =>
                  act(r, () => admin.approve(r.id), context.l10n.adminApproved),
            ),
            1 => _ActiveCard(
              restaurant: r,
              busy: isBusy,
              onDeactivate: () => deactivate(r),
            ),
            _ => _DeactivatedCard(
              restaurant: r,
              busy: isBusy,
              onActivate: () => act(
                r,
                () => admin.activate(r.id),
                context.l10n.adminActivatedAgain,
              ),
            ),
          };
        },
      );
    }

    return Column(
      children: [
        AdminHeader(title: context.l10n.adminNavRestaurants),
        AdminSegments(
          segments: [
            AdminSegment(
              icon: Icons.schedule_rounded,
              label: context.l10n.adminTabPending,
              count: counts['pending'],
            ),
            AdminSegment(
              icon: Icons.check_rounded,
              label: context.l10n.adminTabActive,
              count: counts['active'],
            ),
            AdminSegment(
              icon: Icons.pause_circle_outline_rounded,
              label: context.l10n.adminTabOff,
              count: counts['deactivated'],
            ),
          ],
          selected: tab.value,
          onChanged: (i) => tab.value = i,
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: list.reload, child: body),
        ),
      ],
    );
  }
}

void _openRestaurant(AdminRestaurant r) => AppRouter.router.pushNamed(
  AppRoute.restaurantProfile.name,
  pathParameters: {'id': r.id},
);

/// Logo, name, "Category · address" and a trailing pill.
class _RestaurantHeader extends StatelessWidget {
  final AdminRestaurant restaurant;
  final Widget? pill;
  final List<String> extraLines;

  /// Added to the "Category · address" line (e.g. "2h ago").
  final String? subSuffix;
  const _RestaurantHeader({
    required this.restaurant,
    this.pill,
    this.extraLines = const [],
    this.subSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final sub = [
      r.category,
      r.address,
      subSuffix,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    return GestureDetector(
      onTap: () => _openRestaurant(r),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAvatar(url: r.picture, name: r.name, size: 46, square: true),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: adminTitleStyle(context),
                      ),
                    ),
                    if (pill != null) ...[Gap(8), pill!],
                  ],
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: adminSubStyle(context),
                  ),
                for (final line in extraLines)
                  Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// A restaurant waiting for approval, with Reject / Approve. Shared with
/// the dashboard.
class PendingRestaurantCard extends StatelessWidget {
  final AdminRestaurant restaurant;
  final bool busy;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  /// Without its own card (inside a dashboard list).
  final bool bare;
  const PendingRestaurantCard({
    required this.restaurant,
    required this.busy,
    required this.onReject,
    required this.onApprove,
    this.bare = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final owner =
        r.ownerName ?? (r.ownerUsername == null ? null : '@${r.ownerUsername}');
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RestaurantHeader(
            restaurant: r,
            pill: bare
                ? null
                : AdminPill(
                    context.l10n.adminTabPending,
                    tone: AdminPillTone.warning,
                  ),
            // The dashboard keeps it to one line, like the design.
            subSuffix: bare ? adminAgo(context, r.createdAt) : null,
            extraLines: bare
                ? []
                : [
                    [
                      if (owner != null) context.l10n.adminOwner(owner),
                      if (r.createdAt != null) adminAgo(context, r.createdAt),
                    ].join(' · '),
                  ],
          ),
          Gap(12),
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  label: context.l10n.adminReject,
                  icon: Icons.close_rounded,
                  busy: busy,
                  onTap: onReject,
                ),
              ),
              Gap(8),
              Expanded(
                child: AdminButton(
                  label: context.l10n.adminApprove,
                  icon: Icons.check_rounded,
                  style: AdminButtonStyle.primary,
                  busy: busy,
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return bare ? content : AdminCard(children: [content]);
  }
}

class _ActiveCard extends StatelessWidget {
  final AdminRestaurant restaurant;
  final bool busy;
  final VoidCallback onDeactivate;
  const _ActiveCard({
    required this.restaurant,
    required this.busy,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return AdminCard(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RestaurantHeader(restaurant: r),
              Gap(10),
              Row(
                children: [
                  AdminPill(
                    context.l10n.adminTabActive,
                    tone: AdminPillTone.success,
                  ),
                  if (r.openReportsCount > 0) ...[
                    Gap(6),
                    AdminPill(
                      context.l10n.adminReportsCount(r.openReportsCount),
                      tone: AdminPillTone.danger,
                    ),
                  ],
                  Spacer(),
                  AdminButton(
                    label: context.l10n.adminDeactivate,
                    style: AdminButtonStyle.dangerSoft,
                    height: 34,
                    busy: busy,
                    onTap: onDeactivate,
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

class _DeactivatedCard extends StatelessWidget {
  final AdminRestaurant restaurant;
  final bool busy;
  final VoidCallback onActivate;
  const _DeactivatedCard({
    required this.restaurant,
    required this.busy,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final when = r.deactivatedAt == null
        ? context.l10n.adminTabDeactivated
        : context.l10n.adminDeactivatedOn(adminDate(context, r.deactivatedAt!));
    return AdminCard(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RestaurantHeader(
                restaurant: r,
                extraLines: [
                  when,
                  if (r.deactivationReason?.isNotEmpty ?? false)
                    context.l10n.adminReasonValue(r.deactivationReason!),
                ],
              ),
              Gap(12),
              Align(
                alignment: Alignment.centerRight,
                child: AdminButton(
                  label: context.l10n.adminActivate,
                  icon: Icons.refresh_rounded,
                  style: AdminButtonStyle.primary,
                  height: 34,
                  busy: busy,
                  onTap: onActivate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
