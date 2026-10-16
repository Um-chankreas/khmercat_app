import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/feed/presentation/widgets/report_screens.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_widgets.dart';

const _statuses = ['open', 'removed', 'dismissed'];
const _labels = ['Open', 'Removed', 'Dismissed'];

final _reasonLabels = <String, String>{
  for (final (value, label) in reportReasons) value: label,
  // From the first version of the list.
  'inappropriate': 'Inappropriate',
  'harassment': 'Harassment',
};

/// Admin → Reported content: videos users reported, most reported first.
/// Remove takes the video down (to its owner's trash); Dismiss keeps it up.
class AdminReportsScreen extends HookConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final items = useState(const <ReportedVideo>[]);
    final page = useRef(0);
    final hasMore = useState(true);
    final loading = useState(false);
    final failed = useState(false);
    final busy = useState(const <String>{});
    final scroll = useScrollController();
    final seq = useRef(0);
    final admin = ref.read(adminRemoteDataSourceProvider);

    Future<void> load({bool reset = false}) async {
      if (!reset && (loading.value || !hasMore.value)) return;
      final mySeq = reset ? ++seq.value : seq.value;
      loading.value = true;
      failed.value = false;
      final next = reset ? 1 : page.value + 1;
      try {
        final result = await admin.reports(_statuses[tab.value], next);
        if (!context.mounted || mySeq != seq.value) return;
        page.value = next;
        items.value = reset ? result.items : [...items.value, ...result.items];
        hasMore.value = result.hasMore;
      } catch (_) {
        if (context.mounted && mySeq == seq.value) failed.value = true;
      } finally {
        if (context.mounted && mySeq == seq.value) loading.value = false;
      }
    }

    useEffect(() {
      items.value = const [];
      hasMore.value = true;
      load(reset: true);
      return null;
    }, [tab.value]);
    useEffect(() {
      void onScroll() {
        if (scroll.hasClients && scroll.position.extentAfter < 400) load();
      }

      scroll.addListener(onScroll);
      return () => scroll.removeListener(onScroll);
    }, const []);

    Future<void> act(
      ReportedVideo v,
      Future<void> Function() call,
      String done,
    ) async {
      busy.value = {...busy.value, v.videoId};
      try {
        await call();
        HapticFeedback.lightImpact();
        if (!context.mounted) return;
        items.value = [
          for (final x in items.value)
            if (x.videoId != v.videoId) x,
        ];
        ref.invalidate(adminCountsProvider);
        AppService.showToast(done);
      } catch (_) {
        AppService.showToast('Something went wrong', isError: true);
      } finally {
        if (context.mounted) {
          busy.value = {...busy.value}..remove(v.videoId);
        }
      }
    }

    final Widget body;
    if (items.value.isEmpty && loading.value) {
      body = const Center(
        child: CircularProgressIndicator(color: ProfileTheme.purple),
      );
    } else if (items.value.isEmpty && failed.value) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: 'Couldn\'t load reports.',
        onRetry: () => load(reset: true),
      );
    } else if (items.value.isEmpty) {
      body = AdminMessage(
        icon: Icons.flag_outlined,
        text: switch (tab.value) {
          0 => 'No open reports.',
          1 => 'No videos removed yet.',
          _ => 'No dismissed reports.',
        },
      );
    } else {
      body = ListView.separated(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        itemCount: items.value.length,
        separatorBuilder: (_, _) => const Gap(12),
        itemBuilder: (context, i) {
          final v = items.value[i];
          final isBusy = busy.value.contains(v.videoId);
          return _ReportCard(
            item: v,
            onOpen: v.video == null || v.removed
                ? null
                : () => AppRouter.router.pushNamed(
                    AppRoute.videoViewer.name,
                    pathParameters: {'id': v.videoId},
                    extra: v.video,
                  ),
            actions: tab.value != 0
                ? const []
                : [
                    AdminActionButton(
                      label: 'Remove video',
                      danger: true,
                      busy: isBusy,
                      onTap: () => AppDialogs.showConfirm(
                        context,
                        title: 'Remove this video?',
                        message:
                            'It\'s taken down for everyone and moves to its '
                            'owner\'s trash. All its open reports are closed.',
                        confirmText: 'Remove',
                        isDestructive: true,
                        onConfirm: () => act(
                          v,
                          () => admin.removeVideo(v.videoId),
                          'Video removed',
                        ),
                      ),
                    ),
                    AdminActionButton(
                      label: 'Dismiss',
                      busy: isBusy,
                      onTap: () => act(
                        v,
                        () => admin.dismissReports(v.videoId),
                        'Reports dismissed',
                      ),
                    ),
                  ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const MenuTitleBar(title: 'Reported content'),
            AdminTabs(
              labels: _labels,
              selected: tab.value,
              onChanged: (i) => tab.value = i,
            ),
            Expanded(
              child: RefreshIndicator(
                color: ProfileTheme.purple,
                onRefresh: () async {
                  ref.invalidate(adminCountsProvider);
                  await load(reset: true);
                },
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumbnail, caption, who posted it and where, how many reports, the
/// latest reasons, and the actions.
class _ReportCard extends StatelessWidget {
  final ReportedVideo item;
  final VoidCallback? onOpen;
  final List<Widget> actions;
  const _ReportCard({
    required this.item,
    required this.onOpen,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final v = item;
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    final byline = [
      if (v.authorUsername != null) '@${v.authorUsername}',
      ?v.restaurantName,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onOpen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 66,
                    height: 88,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetImage(
                          url: v.thumbnailUrl,
                          fallback: Icons.videocam_outlined,
                          cacheWidth: 66,
                        ),
                        if (onOpen != null)
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: adminDanger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v.reportsCount == 1
                                ? '1 report'
                                : '${v.reportsCount} reports',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: adminDanger,
                            ),
                          ),
                        ),
                        if (v.removed) ...[
                          const Gap(6),
                          Text(
                            'Removed',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ],
                    ),
                    const Gap(6),
                    Text(
                      v.caption.isEmpty ? '(no caption)' : v.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    if (byline.isNotEmpty) ...[
                      const Gap(2),
                      Text(
                        byline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),
          for (final r in v.reports)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _reasonLabels[r.reason] ?? r.reason,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    if (r.note != null) TextSpan(text: ' — ${r.note}'),
                    TextSpan(
                      text: [
                        if (r.reporterUsername != null)
                          '  @${r.reporterUsername}',
                        if (r.createdAt != null) timeAgo(r.createdAt!),
                      ].join(' · '),
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13, color: primary),
              ),
            ),
          if (actions.isNotEmpty) ...[
            const Gap(6),
            Row(
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const Gap(8),
                  a,
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
