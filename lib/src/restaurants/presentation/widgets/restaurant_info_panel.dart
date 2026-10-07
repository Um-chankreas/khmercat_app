import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

const _green = Color(0xff22A45D);
const _red = Color(0xffE5484D);

/// The restaurant's Info tab: flat, grouped and easy to scan.
///
///  DETAILS — category, opening hours (with Open/Closed), service
///  CONTACT — phone (tap to call), address (tap for maps)
///  ABOUT   — the description as a plain paragraph
///  SOCIAL  — Facebook / TikTok / Telegram with their logos and handles
///
/// With [onEdit] (the owner) anything not set yet shows a purple "Add …"
/// that opens it. Without it (visitors) unset rows are simply left out, and
/// a group with nothing to show is skipped. [showSocial] is false where the
/// social buttons are already shown elsewhere on the page.
class RestaurantInfoPanel extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onEdit;
  final bool showSocial;

  /// Opens the menu screen; adds a "Menu" row at the top when given.
  final VoidCallback? onOpenMenu;

  /// Space above the first heading (0 where the page already adds a gap
  /// under the tab bar).
  final double topPadding;
  const RestaurantInfoPanel({
    required this.restaurant,
    this.onEdit,
    this.showSocial = true,
    this.onOpenMenu,
    this.topPadding = 16,
    super.key,
  });

  static String? hm(String? t) =>
      t == null || t.length < 5 ? null : t.substring(0, 5);

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// "facebook.com/share/1DtfCRRSX3" — no scheme, no "www.", no trailing
  /// slash, so long links read as a handle.
  static String shortUrl(String v) {
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    if (uri == null || uri.host.isEmpty) return v;
    final host = uri.host.replaceFirst('www.', '');
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return '$host$path';
  }

  static String handle(String v) =>
      v.startsWith('http') ? shortUrl(v) : (v.startsWith('@') ? v : '@$v');

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final opens = hm(r.openingTime), closes = hm(r.closingTime);
    final phone = _clean(r.phone);
    final address = _clean(r.address);
    final about = _clean(r.description);
    final facebook = _clean(r.facebookUrl);
    final tiktok = _clean(r.tiktokUrl);
    final telegram = _clean(r.telegramUsername);
    final editable = onEdit != null;

    // Exact pin when we have coordinates, otherwise search the address.
    final mapQuery = r.latitude != null && r.longitude != null
        ? '${r.latitude},${r.longitude}'
        : address;

    /// A row, or null when there's nothing to show (unset, read-only).
    InfoRow? row({
      required String label,
      required String? value,
      required String addText,
      IconData? icon,
      String? iconAsset,
      String? asset,
      Color color = ProfileTheme.purple,
      Widget? trailing,
      IconData? actionIcon,
      String? actionAsset,
      VoidCallback? onTap,
    }) {
      if (value == null && !editable) return null;
      return InfoRow(
        icon: icon,
        iconAsset: iconAsset,
        asset: asset,
        color: color,
        label: label,
        value: value,
        trailing: trailing,
        actionIcon: actionIcon,
        actionAsset: actionAsset,
        onTap: onTap,
        addText: addText,
        onAdd: onEdit,
      );
    }

    /// Heading + group, or nothing when every row is empty. Each section
    /// slides in a beat after the one above it.
    var shownSections = 0;
    List<Widget> section(String title, List<Widget?> rows) {
      final shown = rows.whereType<Widget>().toList();
      if (shown.isEmpty) return const [];
      return [
        _StaggerIn(
          index: shownSections++,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoLabel(title),
              InfoGroup(children: shown),
            ],
          ),
        ),
      ];
    }

    final pages = r.menuPagesCount;
    final children = [
      if (onOpenMenu != null)
        ...section('Menu', [
          if (pages > 0 || editable)
            InfoRow(
              iconAsset: AssetsName.lcMenu,
              color: ProfileTheme.deepPurple,
              label: 'Menu',
              value: pages == 0
                  ? null
                  : '$pages page${pages == 1 ? '' : 's'} · QR code',
              actionAsset: AssetsName.lcQr,
              onTap: onOpenMenu,
              addText: 'Add your menu',
              onAdd: onOpenMenu,
            ),
        ]),
      ...section('Details', [
        row(
          iconAsset: AssetsName.lcCategory,
          label: 'Category',
          value: r.category?.name,
          addText: 'Add category',
        ),
        row(
          iconAsset: AssetsName.lcClock,
          color: ProfileTheme.blue,
          label: 'Opening hours',
          value: opens != null && closes != null ? '$opens – $closes' : null,
          trailing: r.isOpen == null ? null : OpenStatusPill(open: r.isOpen!),
          addText: 'Add opening hours',
        ),
        row(
          iconAsset: AssetsName.lcService,
          color: ProfileTheme.pink,
          label: 'Service',
          value: r.serviceTypeLabel,
          addText: 'Add service type',
        ),
      ]),
      ...section('Contact', [
        row(
          iconAsset: AssetsName.lcPhone,
          color: _green,
          label: 'Phone',
          value: phone,
          actionAsset: AssetsName.lcPhone,
          onTap: phone == null
              ? null
              : () => SocialLinks.open(
                  Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
                ),
          addText: 'Add phone number',
        ),
        row(
          iconAsset: AssetsName.lcPin,
          color: _red,
          label: 'Address',
          value: address,
          actionAsset: AssetsName.lcNavigate,
          onTap: mapQuery == null
              ? null
              : () => SocialLinks.open(
                  Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': mapQuery,
                  }),
                ),
          addText: 'Add address',
        ),
      ]),
      ...section('About', [
        if (about != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              about,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
          )
        else if (editable)
          _AddRow(text: 'Add a description', onTap: onEdit!),
      ]),
      if (showSocial)
        ...section('Social', [
          row(
            asset: AssetsName.facebook,
            label: 'Facebook',
            value: facebook == null ? null : shortUrl(facebook),
            actionIcon: Icons.open_in_new_rounded,
            onTap: _opener(SocialLinks.facebook(facebook)),
            addText: 'Add Facebook',
          ),
          row(
            asset: AssetsName.tiktok,
            label: 'TikTok',
            value: tiktok == null ? null : handle(tiktok),
            actionIcon: Icons.open_in_new_rounded,
            onTap: _opener(SocialLinks.tiktok(tiktok)),
            addText: 'Add TikTok',
          ),
          row(
            asset: AssetsName.telegram,
            label: 'Telegram',
            value: telegram == null ? null : handle(telegram),
            actionIcon: Icons.open_in_new_rounded,
            onTap: _opener(SocialLinks.telegram(telegram)),
            addText: 'Add Telegram',
          ),
        ]),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: children.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No details yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
    );
  }

  static VoidCallback? _opener(Uri? uri) =>
      uri == null ? null : () => SocialLinks.open(uri);
}

/// Small grey uppercase heading above each group.
class InfoLabel extends StatelessWidget {
  final String text;
  const InfoLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: ProfileTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Soft rounded card: surface color, hairline border, a barely-there
/// shadow, thin inset dividers between rows. 20px below it before the next
/// heading.
class InfoGroup extends StatelessWidget {
  final List<Widget> children;
  const InfoGroup({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final line = ProfileTheme.hairlineColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3B1C7A).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 70,
                  endIndent: 16,
                  color: line,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon (tinted circle, or a brand logo), small label over the value, and
/// an optional action icon. Unset values become a purple "Add …" link.
class InfoRow extends StatelessWidget {
  final IconData? icon;

  /// Tinted line icon (PNG, black glyph recolored with [color]).
  final String? iconAsset;

  /// Brand logo, drawn as-is.
  final String? asset;
  final Color color;
  final String label;
  final String? value;
  final Widget? trailing;
  final IconData? actionIcon;
  final String? actionAsset;
  final VoidCallback? onTap;

  /// Shown (as a purple link to [onAdd]) when [value] is null. Read-only
  /// screens just don't build the row for unset values.
  final String addText;
  final VoidCallback? onAdd;

  const InfoRow({
    required this.label,
    required this.value,
    this.addText = '',
    this.onAdd,
    super.key,
    this.icon,
    this.iconAsset,
    this.asset,
    this.color = ProfileTheme.purple,
    this.trailing,
    this.actionIcon,
    this.actionAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final isSet = value != null;
    return InkWell(
      onTap: isSet ? onTap : onAdd,
      splashColor: color.withValues(alpha: 0.10),
      highlightColor: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: asset != null
                    ? muted.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: asset != null
                  ? Image.asset(
                      asset!,
                      width: 20,
                      height: 20,
                      cacheWidth: (20 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                    )
                  : iconAsset != null
                  ? Image.asset(iconAsset!, width: 19, height: 19, color: color)
                  : Icon(icon, size: 19, color: color),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    value ?? addText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      letterSpacing: -0.1,
                      fontWeight: isSet ? FontWeight.w600 : FontWeight.w700,
                      color: isSet
                          ? ProfileTheme.textPrimary(context)
                          : ProfileTheme.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            if (isSet && trailing != null) ...[const Gap(8), trailing!],
            if (isSet &&
                (actionIcon != null || actionAsset != null) &&
                onTap != null) ...[
              const Gap(10),
              // Reads as a button: what tapping the row does.
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: actionAsset != null
                    ? Image.asset(
                        actionAsset!,
                        width: 16,
                        height: 16,
                        color: color,
                      )
                    : Icon(actionIcon, size: 16, color: color),
              ),
            ],
            if (!isSet)
              const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: ProfileTheme.deepPurple,
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width "Add …" row for an empty group (e.g. no description yet).
class _AddRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _AddRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 20,
              color: ProfileTheme.deepPurple,
            ),
            const Gap(10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProfileTheme.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenStatusPill extends StatelessWidget {
  final bool open;

  /// e.g. "until 21:00" / "opens 09:00", shown after Open now / Closed.
  final String? detail;
  const OpenStatusPill({required this.open, this.detail, super.key});

  @override
  Widget build(BuildContext context) {
    final color = open ? _green : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const Gap(6),
          Text(
            [open ? 'Open now' : 'Closed', ?detail].join(' · '),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + short rise, delayed by [index] so sections cascade in.
class _StaggerIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _StaggerIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = index * 60;
    final total = 360 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
