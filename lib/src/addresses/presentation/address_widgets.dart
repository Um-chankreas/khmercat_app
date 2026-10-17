import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';

import '../domain/saved_address.dart';

/// The address type's name in the app's language.
extension AddressLabelText on AddressLabel {
  String text(AppLocalizations l) => switch (this) {
    AddressLabel.home => l.addressLabelHome,
    AddressLabel.office => l.addressLabelOffice,
    AddressLabel.other => l.addressLabelOther,
  };
}

/// Pink → periwinkle wash on the address screens' main button and the
/// selected label chip.
const addressGradient = ProfileTheme.brandGradient;

/// Full-width gradient button with dark text: "Save address",
/// "+ Add new address". Shows a spinner and ignores taps while [loading].
class AddressGradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;

  const AddressGradientButton({
    required this.text,
    required this.onTap,
    this.icon,
    this.loading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: addressGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: ProfileTheme.ink,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: ProfileTheme.ink),
                      const Gap(8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ProfileTheme.ink,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
