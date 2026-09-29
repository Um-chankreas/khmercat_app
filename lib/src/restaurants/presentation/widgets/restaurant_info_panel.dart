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
      String? asset,
      Color color = ProfileTheme.purple,
      Widget? trailing,
      IconData? actionIcon,
      VoidCallback? onTap,
    }) {
      if (value == null && !editable) return null;
      return InfoRow(
        icon: icon,
        asset: asset,
        color: color,
        label: label,
        value: value,
        trailing: trailing,
        actionIcon: actionIcon,
        onTap: onTap,
        addText: addText,
        onAdd: onEdit,
      );
    }

    /// Heading + group, or nothing when every row is empty.
    List<Widget> section(String title, List<Widget?> rows) {
      final shown = rows.whereType<Widget>().toList();
      if (shown.isEmpty) return const [];
      return [InfoLabel(title), InfoGroup(children: shown)];
    }

    final pages = r.menuPagesCount;
    final children = [
      if (onOpenMenu != null)
        ...section('Menu', [
          if (pages > 0 || editable)
            InfoRow(
              icon: Icons.menu_book_rounded,
              color: ProfileTheme.deepPurple,
              label: 'Menu',
              value: pages == 0
                  ? null
                  : '$pages page${pages == 1 ? '' : 's'} · QR code',
              actionIcon: Icons.qr_code_2_rounded,
              onTap: onOpenMenu,
              addText: 'Add your menu',
              onAdd: onOpenMenu,
            ),
        ]),
      ...section('Details', [
        row(
          icon: Icons.restaurant_menu_rounded,
          label: 'Category',
          value: r.category?.name,
          addText: 'Add category',
        ),
        row(
          icon: Icons.schedule_rounded,
          color: ProfileTheme.blue,
          label: 'Opening hours',
          value: opens != null && closes != null ? '$opens – $closes' : null,
          trailing: r.isOpen == null ? null : OpenStatusPill(open: r.isOpen!),
          addText: 'Add opening hours',
        ),
        row(
          icon: Icons.delivery_dining_rounded,
          color: ProfileTheme.pink,
          label: 'Service',
          value: r.serviceTypeLabel,
          addText: 'Add service type',
        ),
      ]),
      ...section('Contact', [
        row(
          icon: Icons.phone_rounded,
          color: _green,
          label: 'Phone',
          value: phone,
          actionIcon: Icons.call_rounded,
          onTap: phone == null
              ? null
              : () => SocialLinks.open(
                  Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
                ),
          addText: 'Add phone number',
        ),
        row(
          icon: Icons.location_on_rounded,
          color: _red,
          label: 'Address',
          value: address,
          actionIcon: Icons.directions_rounded,
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
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: ProfileTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Flat rounded card: surface color, hairline border, no shadow, thin
/// dividers between rows. 16px below it before the next heading.
class InfoGroup extends StatelessWidget {
  final List<Widget> children;
  const InfoGroup({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final line = ProfileTheme.hairlineColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, indent: 62, color: line),
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
  final String? asset;
  final Color color;
  final String label;
  final String? value;
  final Widget? trailing;
  final IconData? actionIcon;
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
    this.asset,
    this.color = ProfileTheme.purple,
    this.trailing,
    this.actionIcon,
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
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: asset != null
                    ? muted.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: asset != null
                  ? Image.asset(asset!, width: 20, height: 20)
                  : Icon(icon, size: 19, color: color),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: muted)),
                  const Gap(2),
                  Text(
                    value ?? addText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
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
            if (isSet && actionIcon != null && onTap != null) ...[
              const Gap(8),
              Icon(actionIcon, size: 18, color: muted),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        [open ? 'Open now' : 'Closed', ?detail].join(' · '),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
