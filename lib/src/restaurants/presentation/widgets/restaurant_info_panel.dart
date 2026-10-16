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
    final pages = r.menuPagesCount;

    // Exact pin when we have coordinates, otherwise search the address.
    final mapQuery = r.latitude != null && r.longitude != null
        ? '${r.latitude},${r.longitude}'
        : address;

    // Every field, in display order: set ones become rows below, unset ones
    // become "+ chip"s in the owner's "Finish your profile" card.
    final items = <_InfoItem>[
      if (onOpenMenu != null)
        _InfoItem(
          label: 'Menu',
          iconAsset: AssetsName.lcMenu,
          value: pages > 0
              ? '$pages page${pages == 1 ? '' : 's'} · QR code'
              : null,
          actionAsset: AssetsName.lcQr,
          onTap: onOpenMenu,
          onAdd: onOpenMenu,
        ),
      _InfoItem(
        label: 'Category',
        iconAsset: AssetsName.lcCategory,
        value: r.category?.name,
      ),
      _InfoItem(
        label: 'Opening hours',
        iconAsset: AssetsName.lcClock,
        value: opens != null && closes != null ? '$opens – $closes' : null,
        trailing: r.isOpen == null ? null : OpenStatusPill(open: r.isOpen!),
      ),
      _InfoItem(
        label: 'Service',
        iconAsset: AssetsName.lcService,
        value: r.serviceTypeLabel,
      ),
      _InfoItem(
        label: 'Phone',
        iconAsset: AssetsName.lcPhone,
        value: phone,
        actionAsset: AssetsName.lcPhone,
        onTap: phone == null
            ? null
            : () => SocialLinks.open(
                Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
              ),
      ),
      _InfoItem(
        label: 'Address',
        iconAsset: AssetsName.lcPin,
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
      ),
      _InfoItem(label: 'About', iconAsset: AssetsName.lcInfo, value: about),
      if (showSocial) ...[
        _InfoItem(
          label: 'Facebook',
          asset: AssetsName.facebook,
          value: facebook == null ? null : shortUrl(facebook),
          actionAsset: AssetsName.lcExternal,
          onTap: _opener(SocialLinks.facebook(facebook)),
        ),
        _InfoItem(
          label: 'TikTok',
          asset: AssetsName.tiktok,
          value: tiktok == null ? null : handle(tiktok),
          actionAsset: AssetsName.lcExternal,
          onTap: _opener(SocialLinks.tiktok(tiktok)),
        ),
        _InfoItem(
          label: 'Telegram',
          asset: AssetsName.telegram,
          value: telegram == null ? null : handle(telegram),
          actionAsset: AssetsName.lcExternal,
          onTap: _opener(SocialLinks.telegram(telegram)),
        ),
      ],
    ];
    final filled = items.where((i) => i.value != null).toList();
    final missing = items.where((i) => i.value == null).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editable && missing.isNotEmpty) ...[
            _CompletionCard(
              done: filled.length,
              total: items.length,
              missing: missing,
              onEdit: onEdit!,
            ),
            const Gap(24),
          ],
          if (filled.isEmpty && !editable)
            Padding(
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
          else if (filled.isNotEmpty) ...[
            const _SectionLabel('Details'),
            for (final (i, item) in filled.indexed) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: ProfileTheme.hairlineColor(context),
                ),
              _InfoRowTile(item: item),
            ],
          ],
        ],
      ),
    );
  }

  static VoidCallback? _opener(Uri? uri) =>
      uri == null ? null : () => SocialLinks.open(uri);
}

class _InfoItem {
  final String label;
  final String? value;
  final String? iconAsset;

  /// Brand logo, drawn as-is.
  final String? asset;
  final Widget? trailing;
  final String? actionAsset;
  final VoidCallback? onTap;

  /// What the "+ chip" opens; the owner's edit screen when null.
  final VoidCallback? onAdd;
  const _InfoItem({
    required this.label,
    required this.value,
    this.iconAsset,
    this.asset,
    this.trailing,
    this.actionAsset,
    this.onTap,
    this.onAdd,
  });
}

/// Small grey heading above the list.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ProfileTheme.textSecondary(context),
        ),
      ),
    );
  }
}

/// Flat row: line icon, small label over the value, optional action button.
class _InfoRowTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoRowTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    final primary = ProfileTheme.textPrimary(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: item.asset != null
                  ? Image.asset(
                      item.asset!,
                      width: 20,
                      height: 20,
                      cacheWidth: (20 * dpr).round(),
                    )
                  : Image.asset(
                      item.iconAsset!,
                      width: 20,
                      height: 20,
                      color: primary,
                    ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                  const Gap(2),
                  Text(
                    item.value!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.trailing != null) ...[const Gap(8), item.trailing!],
            if (item.actionAsset != null && item.onTap != null) ...[
              const Gap(10),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProfileTheme.pink.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  item.actionAsset!,
                  width: 17,
                  height: 17,
                  color: const Color(0xffC2185B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Finish your profile  3 of 10 done" with a progress bar and a "+ chip"
/// for everything still empty.
class _CompletionCard extends StatelessWidget {
  final int done;
  final int total;
  final List<_InfoItem> missing;
  final VoidCallback onEdit;
  const _CompletionCard({
    required this.done,
    required this.total,
    required this.missing,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffF0A6CE).withValues(alpha: 0.28),
            const Color(0xffA9C1F5).withValues(alpha: 0.28),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Finish your profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              Text(
                '$done of $total done',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              color: ProfileTheme.ink,
              backgroundColor: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const Gap(12),
          Text(
            'Complete profiles get approved faster and show up more in '
            'search.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: ProfileTheme.textSecondary(context),
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in missing)
                GestureDetector(
                  onTap: m.onAdd ?? onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '+  ${m.label}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ProfileTheme.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
