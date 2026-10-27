import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

import '../data/admin_remote_datasource.dart';
import 'admin_dashboard_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_restaurants_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_widgets.dart';

/// Opens the admin area (from the app's Settings).
Future<void> openAdmin(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const AdminShell()));

/// The admin area: Home · Restaurants · Reports · Settings on a
/// floating bar, each tab kept alive once opened.
class AdminShell extends HookConsumerWidget {
  /// The whole app for an admin account (nothing to go back to).
  final bool isRoot;
  const AdminShell({this.isRoot = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(AdminTab.home);
    final opened = useState<Set<int>>({AdminTab.home});
    final openReports = ref
        .watch(adminSummaryProvider)
        .valueOrNull
        ?.openReports;

    void open(int i) {
      tab.value = i;
      if (!opened.value.contains(i)) opened.value = {...opened.value, i};
    }

    final screens = <Widget>[
      AdminDashboardScreen(onOpenTab: open),
      AdminRestaurantsScreen(),
      AdminReportsScreen(),
      AdminSettingsScreen(showBackToApp: !isRoot),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // The same cat backdrop as the search tab, on every tab.
            const Positioned.fill(child: SearchBackdrop()),
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: tab.value,
                children: [
                  for (final (i, screen) in screens.indexed)
                    opened.value.contains(i) ? screen : SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14 + MediaQuery.paddingOf(context).bottom,
              child: _AdminNavBar(
                selected: tab.value,
                reportsBadge: openReports,
                onTap: open,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavBar extends StatelessWidget {
  final int selected;
  final int? reportsBadge;
  final ValueChanged<int> onTap;
  const _AdminNavBar({
    required this.selected,
    required this.reportsBadge,
    required this.onTap,
  });

  // The app's own icons, as on its bottom bar.
  static final _icons = <Object>[
    AssetsName.navHome,
    AssetsName.shop,
    AssetsName.redFlag,
    AssetsName.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AdminColors.card(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            // A purple hairline and a firmer shadow: the page behind is
            // near-white too, so a white rim alone disappears into it.
            border: Border.all(
              color: const Color(0xff5B3FA8).withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff3B1C7A).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xff3B1C7A).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final (i, (icon, label)) in [
                for (final (j, l) in [
                  context.l10n.adminNavHome,
                  context.l10n.adminNavRestaurants,
                  context.l10n.adminNavReports,
                  context.l10n.adminNavSettings,
                ].indexed)
                  (_icons[j], l),
              ].indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == selected) return;
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: i == selected
                            ? AdminColors.softWash(context)
                            : null,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              switch (icon) {
                                final String asset => Image.asset(
                                  asset,
                                  width: 20,
                                  height: 20,
                                  color: i == selected
                                      ? AdminColors.ink(context)
                                      : AdminColors.muted(context),
                                ),
                                _ => Icon(
                                  icon as IconData,
                                  size: 20,
                                  color: i == selected
                                      ? AdminColors.ink(context)
                                      : AdminColors.muted(context),
                                ),
                              },
                              const Gap(2),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: i == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: i == selected
                                      ? AdminColors.ink(context)
                                      : AdminColors.muted(context),
                                ),
                              ),
                            ],
                          ),
                          if (i == AdminTab.reports && (reportsBadge ?? 0) > 0)
                            Positioned(
                              top: 4,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Transform.translate(
                                  offset: Offset(14, 0),
                                  child: Container(
                                    constraints: BoxConstraints(minWidth: 18),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminColors.accent,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: AdminColors.card(context),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      reportsBadge! > 99
                                          ? '99+'
                                          : '$reportsBadge',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
