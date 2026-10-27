import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_widgets.dart';

/// Who's being banned, as the sheet shows them.
class BanTarget {
  final String id;
  final String name;
  final String username;
  final String? picture;
  final int? videosCount;
  final int reportsCount;
  const BanTarget({
    required this.id,
    required this.name,
    required this.username,
    this.picture,
    this.videosCount,
    this.reportsCount = 0,
  });
}

/// "Ban Sokha Meas?": how long, why, and whether to delete their reported
/// videos too. True once banned.
Future<bool> showBanSheet(
  BuildContext context,
  BanTarget target, {
  String? suggestedReason,
}) async {
  final banned = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BanSheet(target: target, suggestedReason: suggestedReason),
  );
  return banned ?? false;
}

class _BanSheet extends HookConsumerWidget {
  final BanTarget target;
  final String? suggestedReason;
  const _BanSheet({required this.target, this.suggestedReason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read up front: the actions below use them after awaiting.
    final l10n = context.l10n;
    final days = useState<int?>(7);
    final reason = useState(
      banReasons.contains(suggestedReason)
          ? suggestedReason!
          : banReasons.first,
    );
    final deleteVideos = useState(target.reportsCount > 0);
    final busy = useState(false);

    Future<void> ban() async {
      busy.value = true;
      try {
        final deleted = await ref
            .read(adminRemoteDataSourceProvider)
            .ban(
              target.id,
              days: days.value,
              reason: reason.value,
              deleteReportedVideos: deleteVideos.value,
            );
        HapticFeedback.mediumImpact();
        ref.invalidate(adminSummaryProvider);
        AppService.showToast(
          deleted > 0
              ? l10n.adminBannedWithVideos(target.username, deleted)
              : l10n.adminBannedToast(target.username),
        );
        if (context.mounted) Navigator.pop(context, true);
      } on ApiException catch (e) {
        AppService.showToast(e.message, isError: true);
      } catch (_) {
        AppService.showToast(l10n.adminBanFailed, isError: true);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final stats = [
      '@${target.username}',
      if (target.videosCount != null)
        context.l10n.adminVideosCount(target.videosCount!),
      if (target.reportsCount > 0)
        context.l10n.adminReportsCount(target.reportsCount),
    ].join(' · ');

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AdminColors.card(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AdminColors.muted(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Gap(14),
          Row(
            children: [
              AdminAvatar(url: target.picture, name: target.name, size: 48),
              Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.adminBanTitle(target.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.ink(context),
                      ),
                    ),
                    Text(stats, style: adminSubStyle(context)),
                  ],
                ),
              ),
            ],
          ),
          Gap(18),
          Text(context.l10n.adminHowLong, style: _label(context)),
          Gap(8),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AdminColors.fill(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (value, text) in [
                  (7, context.l10n.adminDays(7)),
                  (30, context.l10n.adminDays(30)),
                  (null, context.l10n.adminForever),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => days.value = value,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: days.value == value
                              ? AdminColors.card(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: days.value == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AdminColors.ink(context),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Gap(18),
          Text(context.l10n.adminReason, style: _label(context)),
          Gap(4),
          for (final (i, value) in banReasons.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AdminColors.fill(context),
              ),
            InkWell(
              onTap: () => reason.value = value,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        banReasonLabel(context, value),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AdminColors.ink(context),
                        ),
                      ),
                    ),
                    _Radio(on: reason.value == value),
                  ],
                ),
              ),
            ),
          ],
          Gap(10),
          GestureDetector(
            onTap: () => deleteVideos.value = !deleteVideos.value,
            child: Container(
              padding: EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: AdminColors.fill(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.adminAlsoDeleteVideos,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.ink(context),
                          ),
                        ),
                        Text(
                          context.l10n.adminAlsoDeleteVideosSub,
                          style: adminSubStyle(context).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _Switch(on: deleteVideos.value),
                ],
              ),
            ),
          ),
          Gap(10),
          Text(
            context.l10n.adminBanNote,
            style: adminSubStyle(context).copyWith(fontSize: 12, height: 1.4),
          ),
          Gap(16),
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  label: context.l10n.cancelAction,
                  height: 50,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
              Gap(10),
              Expanded(
                child: AdminButton(
                  label: context.l10n.adminBanUser,
                  icon: Icons.block_rounded,
                  style: AdminButtonStyle.danger,
                  height: 50,
                  busy: busy.value,
                  onTap: ban,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _label(BuildContext context) => TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AdminColors.ink(context),
);

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Duration(milliseconds: 150),
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: on ? AdminColors.wash : null,
      border: on
          ? null
          : Border.all(
              color: AdminColors.muted(context).withValues(alpha: 0.4),
              width: 2,
            ),
    ),
    child: on
        ? Icon(Icons.check_rounded, size: 14, color: AdminColors.onWash)
        : null,
  );
}

class _Switch extends StatelessWidget {
  final bool on;
  const _Switch({required this.on});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Duration(milliseconds: 160),
    width: 46,
    height: 28,
    padding: EdgeInsets.all(3),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(
      gradient: on ? AdminColors.wash : null,
      color: on ? null : AdminColors.muted(context).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
    ),
  );
}
