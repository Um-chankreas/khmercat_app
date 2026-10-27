import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_ban_sheet.dart';
import 'admin_paged.dart';
import 'admin_widgets.dart';

const _statuses = ['open', 'resolved'];

/// A report reason → the ban reason it suggests.
String? _banReasonFor(String reportReason) => switch (reportReason) {
  'sexual' => 'sexual',
  'spam' || 'misleading' => 'spam',
  'hate_harassment' || 'harassment' => 'hate_harassment',
  _ => null,
};

void _play(BuildContext context, ReportedVideo v) {
  final video = v.video;
  if (video == null || v.removed) {
    AppService.showToast(context.l10n.adminVideoTakenDown);
    return;
  }
  AppRouter.router.pushNamed(
    AppRoute.videoViewer.name,
    pathParameters: {'id': video.id},
    extra: video,
  );
}

/// Admin → Reports: reported videos, most reported first. Delete takes the
/// video down, Dismiss keeps it, Ban user bans its author. Resolved shows
/// what was done and by whom.
class AdminReportsScreen extends HookConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read up front: the actions below use them after awaiting.
    final l10n = context.l10n;
    final tab = useState(0);
    final busy = useState(<String>{});
    final scroll = useScrollController();
    final admin = ref.read(adminRemoteDataSourceProvider);
    final me = ref.watch(currentUserProvider)?.id;
    final list = useAdminPaged<ReportedVideo>(
      (page) => admin.reports(_statuses[tab.value], page),
      [tab.value],
    );
    useLoadMoreOnScroll(scroll, list.loadMore);

    Future<void> act(
      ReportedVideo v,
      Future<void> Function() call,
      String done,
    ) async {
      busy.value = {...busy.value, v.videoId};
      try {
        await call();
        HapticFeedback.lightImpact();
        list.removeWhere((x) => x.videoId == v.videoId);
        ref.invalidate(adminSummaryProvider);
        AppService.showToast(done);
      } catch (_) {
        AppService.showToast(l10n.adminSomethingWrong, isError: true);
      } finally {
        if (context.mounted) {
          busy.value = {...busy.value}..remove(v.videoId);
        }
      }
    }

    void delete(ReportedVideo v) => AppDialogs.showConfirm(
      context,
      title: context.l10n.adminDeleteVideoTitle,
      message: context.l10n.adminDeleteVideoMessage(
        v.authorUsername == null
            ? context.l10n.adminTheAuthor
            : '@${v.authorUsername}',
      ),
      confirmText: context.l10n.adminDelete,
      cancelText: context.l10n.cancelAction,
      isDestructive: true,
      onConfirm: () => act(
        v,
        () => admin.removeVideo(v.videoId),
        context.l10n.adminVideoDeleted,
      ),
    );

    Future<void> banAuthor(ReportedVideo v) async {
      if (v.authorId == null) return;
      final banned = await showBanSheet(
        context,
        BanTarget(
          id: v.authorId!,
          name: v.authorName ?? v.authorUsername ?? '',
          username: v.authorUsername ?? '',
          picture: v.authorPicture,
          reportsCount: v.reportsCount,
        ),
        suggestedReason: _banReasonFor(v.topReason),
      );
      if (banned) list.reload();
    }

    final open = list.counts['open'];
    final Widget body;
    if (list.isEmptyLoading) {
      body = Center(child: CircularProgressIndicator());
    } else if (list.items.isEmpty && list.failed) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: context.l10n.adminReportsLoadFailed,
        onRetry: list.reload,
      );
    } else if (list.items.isEmpty) {
      body = AdminMessage(
        icon: Icons.outlined_flag_rounded,
        text: tab.value == 0
            ? context.l10n.adminAllClear
            : context.l10n.adminNothingResolved,
      );
    } else if (tab.value == 0) {
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
          final v = list.items[i];
          return _OpenReportCard(
            report: v,
            busy: busy.value.contains(v.videoId),
            onDismiss: () => act(
              v,
              () => admin.dismissReports(v.videoId),
              context.l10n.adminReportsDismissed,
            ),
            onBan: v.authorId == null || v.authorBanned
                ? null
                : () => banAuthor(v),
            onDelete: () => delete(v),
          );
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
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: [
          AdminCard(
            children: [
              for (final v in list.items) _ResolvedRow(report: v, myId: me),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        AdminHeader(title: context.l10n.adminNavReports),
        AdminSegments(
          segments: [
            AdminSegment(
              icon: Icons.outlined_flag_rounded,
              label: context.l10n.adminTabOpen,
              count: open,
            ),
            AdminSegment(
              icon: Icons.check_rounded,
              label: context.l10n.adminTabResolved,
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

/// The video's frame, blurred until tapped (it may be the offending
/// content). Tapping plays it.
class ReportThumb extends StatelessWidget {
  final ReportedVideo report;
  final double width;
  final double height;
  final bool label;
  const ReportThumb({
    required this.report,
    this.width = 74,
    this.height = 98,
    this.label = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final url = report.thumbnailUrl;
    return GestureDetector(
      onTap: () => _play(context, report),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url == null)
                ColoredBox(color: AdminColors.fill(context))
              else
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                ),
              if (label)
                Center(
                  child: Text(
                    context.l10n.adminTapToView,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenReportCard extends StatelessWidget {
  final ReportedVideo report;
  final bool busy;
  final VoidCallback onDismiss;
  final VoidCallback? onBan;
  final VoidCallback onDelete;
  const _OpenReportCard({
    required this.report,
    required this.busy,
    required this.onDismiss,
    required this.onBan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final v = report;
    final reasons = v.reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return AdminCard(
      padding: EdgeInsets.all(14),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportThumb(report: v),
                Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportReasonLabel(context, v.topReason),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: adminTitleStyle(context),
                      ),
                      Gap(4),
                      AdminPill(
                        context.l10n.adminReportsCount(v.reportsCount),
                        tone: AdminPillTone.danger,
                      ),
                      Gap(8),
                      Row(
                        children: [
                          AdminAvatar(
                            url: v.authorPicture,
                            name: v.authorName ?? v.authorUsername ?? '',
                            size: 20,
                          ),
                          Gap(6),
                          Expanded(
                            child: Text(
                              [
                                if (v.authorUsername != null)
                                  '@${v.authorUsername}',
                                adminAgo(context, v.createdAt),
                              ].where((s) => s.isNotEmpty).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: adminSubStyle(context),
                            ),
                          ),
                        ],
                      ),
                      if (v.caption.isNotEmpty) ...[
                        Gap(6),
                        Text(
                          '“${v.caption}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AdminColors.sub(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (reasons.isNotEmpty) ...[
              Gap(10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in reasons)
                    AdminPill(
                      '${reportReasonShort(context, e.key)} ×${e.value}',
                    ),
                  if (v.authorBanned)
                    AdminPill(
                      context.l10n.adminAuthorBanned,
                      tone: AdminPillTone.danger,
                    ),
                ],
              ),
            ],
            Gap(12),
            Row(
              children: [
                Expanded(
                  child: AdminButton(
                    label: context.l10n.adminDismiss,
                    busy: busy,
                    onTap: onDismiss,
                  ),
                ),
                Gap(8),
                Expanded(
                  child: AdminButton(
                    label: context.l10n.adminBan,
                    icon: Icons.block_rounded,
                    style: AdminButtonStyle.dangerSoft,
                    onTap: onBan,
                  ),
                ),
                Gap(8),
                Expanded(
                  child: AdminButton(
                    label: context.l10n.adminDelete,
                    icon: Icons.delete_outline_rounded,
                    style: AdminButtonStyle.danger,
                    busy: busy,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// "Video by @kimly.food · Spam · 17 Oct · by you   [Deleted]".
class _ResolvedRow extends StatelessWidget {
  final ReportedVideo report;
  final String? myId;
  const _ResolvedRow({required this.report, required this.myId});

  @override
  Widget build(BuildContext context) {
    final v = report;
    final res = v.resolution;
    final by = res?.resolvedById != null && res!.resolvedById == myId
        ? context.l10n.adminByYou
        : (res?.resolvedByName == null
              ? null
              : context.l10n.adminByName(res!.resolvedByName!));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ReportThumb(report: v, width: 40, height: 52, label: false),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.adminVideoBy(v.authorUsername ?? 'unknown'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: adminTitleStyle(context).copyWith(fontSize: 14.5),
                ),
                Text(
                  [
                    reportReasonShort(context, v.topReason),
                    if (res?.resolvedAt != null)
                      adminDate(context, res!.resolvedAt!),
                    ?by,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: adminSubStyle(context),
                ),
              ],
            ),
          ),
          Gap(8),
          if (v.authorBanned)
            AdminPill(context.l10n.adminUserBanned, tone: AdminPillTone.danger)
          else if (res?.removed ?? v.removed)
            AdminPill(context.l10n.adminDeleted, tone: AdminPillTone.danger)
          else
            AdminPill(context.l10n.adminDismissed),
        ],
      ),
    );
  }
}
