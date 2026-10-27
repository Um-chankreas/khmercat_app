import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

import '../domain/saved_address.dart';
import 'address_form_screen.dart';
import 'address_widgets.dart';
import 'addresses_controller.dart';

enum _RowAction { edit, delete }

/// Menu → Saved addresses: the user's addresses, each with Edit / Delete,
/// over an "Add new address" button.
/// What the Addresses screen returns in choose mode: a saved address, or
/// a request to search for some other place ([address] null).
class AddressChoice {
  final SavedAddress? address;
  const AddressChoice(this.address);
}

/// The saved addresses. With [choosing], tapping one picks it (the screen
/// pops with an [AddressChoice]) instead of opening it to edit; edit and
/// delete stay in the ⋮ menu. [selectedId] gets a tick.
class AddressesScreen extends ConsumerWidget {
  final bool choosing;
  final String? selectedId;
  const AddressesScreen({this.choosing = false, this.selectedId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesControllerProvider);
    final controller = ref.read(addressesControllerProvider.notifier);
    final muted = ProfileTheme.textSecondary(context);
    final l = AppLocalizations.of(context);

    void openForm([SavedAddress? address]) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AddressFormScreen(initial: address),
        ),
      );
    }

    void confirmDelete(SavedAddress address) {
      AppDialogs.showConfirm(
        context,
        title: l.deleteAddressTitle,
        message: l.deleteAddressMessage(address.label.text(l)),
        confirmText: l.deleteAction,
        cancelText: l.cancelAction,
        isDestructive: true,
        onConfirm: () async {
          if (!await controller.remove(address.id)) {
            AppService.showToast(l.addressDeleteFailed, isError: true);
          }
        },
      );
    }

    // Centered icon, title and line of text: the empty and error states.
    Widget message({
      required IconData icon,
      required String title,
      required String text,
      VoidCallback? onRetry,
    }) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 34, color: muted),
            ),
            const Gap(16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
            const Gap(6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: muted),
            ),
            if (onRetry != null) ...[
              const Gap(8),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  l.tryAgain,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: menuAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // The same cat backdrop as the search tab and Settings.
          const Positioned.fill(child: SearchBackdrop()),
          SafeArea(
            child: Column(
              children: [
                MenuTitleBar(
                  title: choosing ? 'Choose an address' : l.addressesTitle,
                ),
                // Any other place: the search / pin picker.
                if (choosing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: MenuCard(
                      outlined: true,
                      children: [
                        MenuRow.icon(
                          icon: Icons.search_rounded,
                          title: 'Search another place',
                          subtitle: 'Find a street, area or landmark',
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: muted,
                          ),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(const AddressChoice(null)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: addresses.when(
                    skipLoadingOnReload: true,
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: ProfileTheme.purple,
                      ),
                    ),
                    error: (_, _) => message(
                      icon: Icons.cloud_off_rounded,
                      title: l.somethingWentWrong,
                      text: l.addressesLoadFailed,
                      onRetry: controller.refresh,
                    ),
                    data: (list) => list.isEmpty
                        ? message(
                            icon: Icons.location_off_outlined,
                            title: l.noData,
                            text: l.noAddressesMessage,
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            children: [
                              MenuCard(
                                outlined: true,
                                children: [
                                  for (final a in list)
                                    MenuRow.icon(
                                      icon: Icons.place_outlined,
                                      title: a.label.text(l),
                                      subtitle: a.fullAddress,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (choosing && a.id == selectedId)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: menuAccent,
                                              size: 22,
                                            ),
                                          _RowMenu(
                                            onSelected: (action) =>
                                                switch (action) {
                                                  _RowAction.edit => openForm(
                                                    a,
                                                  ),
                                                  _RowAction.delete =>
                                                    confirmDelete(a),
                                                },
                                          ),
                                        ],
                                      ),
                                      onTap: choosing
                                          ? () => Navigator.of(
                                              context,
                                            ).pop(AddressChoice(a))
                                          : () => openForm(a),
                                    ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AddressGradientButton(
                    text: l.addNewAddress,
                    icon: Icons.add_rounded,
                    onTap: openForm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The ⋮ on an address row: Edit, and Delete in the accent color.
class _RowMenu extends StatelessWidget {
  final ValueChanged<_RowAction> onSelected;
  const _RowMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final l = AppLocalizations.of(context);
    PopupMenuItem<_RowAction> item(
      _RowAction value,
      IconData icon,
      String text,
      Color color,
    ) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const Gap(12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

    return PopupMenuButton<_RowAction>(
      onSelected: onSelected,
      tooltip: l.moreActions,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(Icons.more_vert_rounded, color: primary),
      itemBuilder: (_) => [
        item(_RowAction.edit, Icons.edit_outlined, l.editAction, primary),
        item(
          _RowAction.delete,
          Icons.delete_outline_rounded,
          l.deleteAction,
          menuAccent,
        ),
      ],
    );
  }
}
