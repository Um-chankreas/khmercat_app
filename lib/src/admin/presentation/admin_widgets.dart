import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';

/// The admin area's palette (from the Admin designs). Text, surfaces and
/// tints follow light / dark mode; brand colors stay the same in both.
abstract final class AdminColors {
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color ink(BuildContext c) =>
      _dark(c) ? Color(0xffF2F1F7) : Color(0xff16181D);
  static Color sub(BuildContext c) =>
      _dark(c) ? Color(0xffC9C7D9) : Color(0xff4E535E);
  static Color muted(BuildContext c) =>
      _dark(c) ? Color(0xffA9A6C4) : Color(0xff8A8F9B);
  static Color fill(BuildContext c) =>
      _dark(c) ? Color(0xff2C2942) : Color(0xffF2F3F5);

  /// Cards, sheets, the search field.
  static Color card(BuildContext c) =>
      _dark(c) ? Color(0xff1F1C30) : Colors.white;
  static Color dangerSoft(BuildContext c) =>
      _dark(c) ? Color(0xff3E2027) : Color(0xffFDECEC);
  static Color greenSoft(BuildContext c) =>
      _dark(c) ? Color(0xff17331F) : Color(0xffE6F6EC);
  static Color warningSoft(BuildContext c) =>
      _dark(c) ? Color(0xff3A3020) : Color(0xffFFF4DD);
  static Color warning(BuildContext c) =>
      _dark(c) ? Color(0xffF2C46B) : Color(0xff8A5A00);
  static Color green(BuildContext c) =>
      _dark(c) ? Color(0xff6FD39A) : Color(0xff1E7B45);

  /// The soft pink → blue tint (highlighted tiles, the selected tab).
  static LinearGradient softWash(BuildContext c) => _dark(c)
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3A2438), Color(0xff22304A)],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffFDE8F1), Color(0xffE6F1FD)],
        );

  static List<BoxShadow> shadow(BuildContext c) => [
    BoxShadow(
      color: _dark(c)
          ? Colors.black.withValues(alpha: 0.25)
          : Color(0xffA32356).withValues(alpha: 0.08),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
  ];

  // Brand colors: the same in light and dark.
  static const accent = Color(0xffA32356);
  static const danger = Color(0xffB3261E);

  /// Text on the pastel [wash], which stays light in dark mode too.
  static const onWash = Color(0xff16181D);
  static const wash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffF5A9CC), Color(0xffA9D1F7)],
  );
}

/// The admin screens' strings: `context.l10n.adminReject` …
extension AdminL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// What a report reason reads as.
String reportReasonLabel(BuildContext context, String reason) {
  final l = context.l10n;
  return switch (reason) {
    'sexual' => l.adminBanReasonSexual,
    'hate_harassment' || 'harassment' => l.adminBanReasonHate,
    'violence' => l.adminReasonViolence,
    'child_safety' => l.adminReasonChildSafety,
    'misleading' => l.adminReasonMisleading,
    'ai_content' => l.adminReasonAi,
    'self_harm' => l.adminReasonSelfHarm,
    'branded' => l.adminReasonBranded,
    'spam' => l.adminBanReasonSpam,
    'copyright' => l.adminReasonCopyright,
    'inappropriate' => l.adminReasonInappropriate,
    _ => l.adminReasonOther,
  };
}

/// Short form for chips: "Nudity ×6".
String reportReasonShort(BuildContext context, String reason) {
  final l = context.l10n;
  return switch (reason) {
    'sexual' => l.adminShortNudity,
    'hate_harassment' || 'harassment' => l.adminShortHarassment,
    'violence' => l.adminShortViolence,
    'child_safety' => l.adminShortChildSafety,
    'misleading' => l.adminShortMisleading,
    'ai_content' => l.adminShortAi,
    'self_harm' => l.adminShortSelfHarm,
    'branded' => l.adminShortBranded,
    'spam' => l.adminShortSpam,
    'copyright' => l.adminShortCopyright,
    'inappropriate' => l.adminReasonInappropriate,
    _ => l.adminShortOther,
  };
}

/// A ban reason ([banReasons] key) as it reads.
String banReasonLabel(BuildContext context, String key) {
  final l = context.l10n;
  return switch (key) {
    'sexual' => l.adminBanReasonSexual,
    'spam' => l.adminBanReasonSpam,
    'hate_harassment' => l.adminBanReasonHate,
    'fake_account' => l.adminBanReasonFake,
    _ => key,
  };
}

/// A date as "17 Oct" in the app's language.
String adminDate(BuildContext context, DateTime t) =>
    DateFormat('d MMM', context.l10n.localeName).format(t);

/// "2h ago", "Yesterday", "3d ago", "17 Oct".
String adminAgo(BuildContext context, DateTime? t) {
  if (t == null) return '';
  final l = context.l10n;
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.adminNow;
  if (d.inHours < 1) return l.adminMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l.adminHoursAgo(d.inHours);
  if (d.inDays == 1) return l.adminYesterday;
  if (d.inDays < 7) return l.adminDaysAgo(d.inDays);
  return adminDate(context, t);
}

String adminCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
  return NumberFormat.decimalPattern().format(n);
}

/// Big screen title ("Restaurants") with an optional line above it and
/// something on the right.
class AdminHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final Widget? trailing;

  /// Shows a back arrow before the title (a pushed admin page).
  final VoidCallback? onBack;
  const AdminHeader({
    required this.title,
    this.overline,
    this.trailing,
    this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminColors.card(context),
                  shape: BoxShape.circle,
                  boxShadow: AdminColors.shadow(context),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AdminColors.ink(context),
                ),
              ),
            ),
            Gap(12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(
                    overline!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AdminColors.muted(context),
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink(context),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A white rounded card whose rows are split by thin lines.
class AdminCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const AdminCard({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminColors.card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdminColors.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AdminColors.fill(context),
              ),
            c,
          ],
        ],
      ),
    );
  }
}

/// "Waiting for approval   See all 6".
class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const AdminSectionTitle({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdminColors.ink(context),
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum AdminPillTone { danger, neutral, success, warning }

/// Small status tag: "8 reports", "Banned", "Active", "Pending".
class AdminPill extends StatelessWidget {
  final String label;
  final AdminPillTone tone;
  const AdminPill(this.label, {this.tone = AdminPillTone.neutral, super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AdminPillTone.danger => (
        AdminColors.dangerSoft(context),
        AdminColors.danger,
      ),
      AdminPillTone.success => (
        AdminColors.greenSoft(context),
        AdminColors.green(context),
      ),
      AdminPillTone.warning => (
        AdminColors.warningSoft(context),
        AdminColors.warning(context),
      ),
      AdminPillTone.neutral => (
        AdminColors.fill(context),
        AdminColors.sub(context),
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

enum AdminButtonStyle { primary, plain, danger, dangerSoft }

/// Pill action: Approve (wash), Reject (grey), Ban user (red), Delete
/// (red text on pink).
class AdminButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AdminButtonStyle style;
  final bool busy;
  final double height;
  final VoidCallback? onTap;
  const AdminButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.style = AdminButtonStyle.plain,
    this.busy = false,
    this.height = 38,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (Color? bg, Gradient? gradient, Color fg) = switch (style) {
      AdminButtonStyle.primary => (null, AdminColors.wash, AdminColors.onWash),
      AdminButtonStyle.plain => (
        AdminColors.fill(context),
        null,
        AdminColors.ink(context),
      ),
      AdminButtonStyle.danger => (AdminColors.danger, null, Colors.white),
      AdminButtonStyle.dangerSoft => (
        AdminColors.dangerSoft(context),
        null,
        AdminColors.danger,
      ),
    };
    return GestureDetector(
      onTap: busy || onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    Gap(6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Underlined tabs ("Open · 12   Resolved").
class AdminTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const AdminTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i == selected) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: i == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == selected
                                ? AdminColors.ink(context)
                                : AdminColors.muted(context),
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: Duration(milliseconds: 180),
                      opacity: i == selected ? 1 : 0,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: AdminColors.wash,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One option of [AdminSegments].
class AdminSegment {
  final IconData icon;
  final String label;

  /// Shown in a small badge; null for none.
  final int? count;
  const AdminSegment({required this.icon, required this.label, this.count});
}

/// The list filters ("Pending 6 · Active 1.2K · Off 1"): a white rounded
/// bar of icon + label + count options, the selected one on the soft tint
/// with its count in the accent color.
class AdminSegments extends StatelessWidget {
  final List<AdminSegment> segments;
  final int selected;
  final ValueChanged<int> onChanged;
  const AdminSegments({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact(locale: context.l10n.localeName);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AdminColors.card(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AdminColors.shadow(context),
      ),
      child: Row(
        children: [
          for (final (i, seg) in segments.indexed)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i == selected) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: i == selected
                        ? AdminColors.softWash(context)
                        : null,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          seg.icon,
                          size: 18,
                          color: i == selected
                              ? AdminColors.ink(context)
                              : AdminColors.muted(context),
                        ),
                        const Gap(6),
                        Text(
                          seg.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: i == selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: i == selected
                                ? AdminColors.ink(context)
                                : AdminColors.muted(context),
                          ),
                        ),
                        if (seg.count != null && seg.count! > 0) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: i == selected
                                  ? AdminColors.card(context)
                                  : AdminColors.fill(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              compact.format(seg.count),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: i == selected
                                    ? AdminColors.accent
                                    : AdminColors.muted(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill filters ("All", "Reported · 9", "Banned · 14").
class AdminChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const AdminChips({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
        itemCount: labels.length,
        separatorBuilder: (_, _) => Gap(8),
        itemBuilder: (_, i) {
          final on = i == selected;
          return GestureDetector(
            onTap: () {
              if (on) return;
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: on ? AdminColors.wash : null,
                color: on ? null : AdminColors.card(context),
                borderRadius: BorderRadius.circular(17),
                boxShadow: on ? null : AdminColors.shadow(context),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? AdminColors.onWash : AdminColors.ink(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A photo, or the name's first letter on grey.
class AdminAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  /// Rounded square (restaurants) instead of a circle (people).
  final bool square;
  const AdminAvatar({
    required this.url,
    required this.name,
    this.size = 44,
    this.square = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? size * 0.3 : size / 2);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: AdminColors.fill(context),
        alignment: Alignment.center,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.sub(context),
                ),
              ),
      ),
    );
  }
}

/// Centered icon + message (empty / error states), scrollable so
/// pull-to-refresh still works.
class AdminMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  /// False when it already sits inside a scrolling list (a list in a list
  /// gets no height and fails to lay out, blanking the whole screen).
  final bool scrollable;
  const AdminMessage({
    required this.icon,
    required this.text,
    this.onRetry,
    this.scrollable = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final message = SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AdminColors.muted(context)),
            Gap(10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: AdminColors.muted(context),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  context.l10n.tryAgain,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!scrollable) return message;
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [message],
    );
  }
}

/// Asks for a short reason (reject / deactivate). Null when cancelled.
Future<String?> askAdminReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirm,
  bool required = false,
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(context.l10n.cancelAction),
          ),
          TextButton(
            onPressed: required && ctrl.text.trim().isEmpty
                ? null
                : () => Navigator.pop(dialog, ctrl.text.trim()),
            child: Text(confirm, style: TextStyle(color: AdminColors.danger)),
          ),
        ],
      ),
    ),
  );
}

/// Row title and subtitle styles used across admin lists.
TextStyle adminTitleStyle(BuildContext context) => TextStyle(
  fontSize: 15,
  height: 1.4,
  fontWeight: FontWeight.w700,
  color: AdminColors.ink(context),
);

TextStyle adminSubStyle(BuildContext context) =>
    TextStyle(fontSize: 13, height: 1.4, color: AdminColors.muted(context));
