import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_widgets.dart';

const _statuses = ['pending', 'approved', 'rejected'];
const _labels = ['Pending', 'Approved', 'Rejected'];

/// Admin → Restaurant approvals. New restaurants wait here, hidden from
/// customers, until approved. Approved ones can be rejected later, and
/// rejected ones approved.
class AdminRestaurantsScreen extends HookConsumerWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final items = useState(const <AdminRestaurant>[]);
    final page = useRef(0);
    final hasMore = useState(true);
    final loading = useState(false);
    final failed = useState(false);
    final busy = useState(const <String>{});
    final scroll = useScrollController();
    // Drops answers that arrive after the tab changed.
    final seq = useRef(0);
    final admin = ref.read(adminRemoteDataSourceProvider);

    Future<void> load({bool reset = false}) async {
      if (!reset && (loading.value || !hasMore.value)) return;
      final mySeq = reset ? ++seq.value : seq.value;
      loading.value = true;
      failed.value = false;
      final next = reset ? 1 : page.value + 1;
      try {
        final result = await admin.restaurants(_statuses[tab.value], next);
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
      AdminRestaurant r,
      Future<void> Function() call,
      String done,
    ) async {
      busy.value = {...busy.value, r.id};
      try {
        await call();
        HapticFeedback.lightImpact();
        if (!context.mounted) return;
        // It's moved to another tab.
        items.value = [
          for (final x in items.value)
            if (x.id != r.id) x,
        ];
        ref.invalidate(adminCountsProvider);
        AppService.showToast(done);
      } catch (_) {
        AppService.showToast('Something went wrong', isError: true);
      } finally {
        if (context.mounted) busy.value = {...busy.value}..remove(r.id);
      }
    }

    Future<void> reject(AdminRestaurant r) async {
      final reason = await _askReason(context, r.name);
      if (reason == null) return; // cancelled
      await act(
        r,
        () => admin.reject(r.id, reason: reason.isEmpty ? null : reason),
        '${r.name} rejected',
      );
    }

    final Widget body;
    if (items.value.isEmpty && loading.value) {
      body = const Center(
        child: CircularProgressIndicator(color: ProfileTheme.purple),
      );
    } else if (items.value.isEmpty && failed.value) {
      body = AdminMessage(
        icon: Icons.cloud_off_rounded,
        text: 'Couldn\'t load restaurants.',
        onRetry: () => load(reset: true),
      );
    } else if (items.value.isEmpty) {
      body = AdminMessage(
        icon: Icons.storefront_outlined,
        text: switch (tab.value) {
          0 => 'Nothing waiting for approval.',
          1 => 'No approved restaurants.',
          _ => 'No rejected restaurants.',
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
          final r = items.value[i];
          final isBusy = busy.value.contains(r.id);
          return _RestaurantCard(
            restaurant: r,
            onOpen: () => openRestaurant(r.id),
            actions: [
              if (tab.value != 1)
                AdminActionButton(
                  label: 'Approve',
                  primary: true,
                  busy: isBusy,
                  onTap: () =>
                      act(r, () => admin.approve(r.id), '${r.name} approved'),
                ),
              if (tab.value != 2)
                AdminActionButton(
                  label: 'Reject',
                  danger: true,
                  busy: isBusy,
                  onTap: () => reject(r),
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
            const MenuTitleBar(title: 'Restaurant approvals'),
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

/// Asks why (optional). Null = cancelled; empty = rejected with no reason.
Future<String?> _askReason(BuildContext context, String name) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reject $name?'),
      content: TextField(
        controller: controller,
        maxLength: 500,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(
          hintText: 'Reason for the owner (optional)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: ProfileTheme.textSecondary(context)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text(
            'Reject',
            style: TextStyle(fontWeight: FontWeight.w800, color: adminDanger),
          ),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Logo, name, category · owner · when, the rejection reason if any, and
/// the actions.
class _RestaurantCard extends StatelessWidget {
  final AdminRestaurant restaurant;
  final VoidCallback onOpen;
  final List<Widget> actions;
  const _RestaurantCard({
    required this.restaurant,
    required this.onOpen,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    final meta = [
      ?r.category,
      if (r.ownerUsername != null) 'by @${r.ownerUsername}',
      if (r.createdAt != null) timeAgo(r.createdAt!),
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: NetImage(url: r.picture, cacheWidth: 52),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                      if (r.address != null && r.address!.trim().isNotEmpty)
                        Text(
                          r.address!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: muted),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted),
              ],
            ),
          ),
          if (r.rejectionReason != null) ...[
            const Gap(8),
            Text(
              'Reason: ${r.rejectionReason}',
              style: const TextStyle(fontSize: 12.5, color: adminDanger),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const Gap(12),
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
