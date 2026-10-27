import 'package:flutter/widgets.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';

extension RestaurantLabels on Restaurant {
  /// "Dine-in Only", "Takeaway", … in the app's language; null when unset.
  String? serviceTypeText(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (serviceType) {
      'dine_in' => l.serviceDineIn,
      'delivery' => l.serviceDelivery,
      'dine_in_delivery' => l.serviceDineInDelivery,
      'takeaway' => l.serviceTakeaway,
      _ => null,
    };
  }
}
