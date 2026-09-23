// lib/core/extensions/context_extensions.dart
import 'package:flutter/material.dart';

extension SafeAreaExtension on BuildContext {
  /// Bottom padding that respects the device's safe area (gesture bar /
  /// nav bar), but never less than [minPadding].
  double safeBottomPadding([double minPadding = 16.0]) {
    final bottomInset = MediaQuery.paddingOf(this).bottom;
    return bottomInset > minPadding ? bottomInset : minPadding;
  }

  /// Top padding that respects the status bar / notch, with a minimum.
  double safeTopPadding([double minPadding = 0.0]) {
    final topInset = MediaQuery.paddingOf(this).top;
    return topInset > minPadding ? topInset : minPadding;
  }
}

extension AppBarSizeExtension on BuildContext {
  /// Standard toolbar height (same across devices unless customized).
  double get toolbarHeight => kToolbarHeight; // 56.0

  /// Status bar height for this specific device.
  double get statusBarHeight => MediaQuery.paddingOf(this).top;

  /// Total visual space the AppBar + status bar occupies on this device.
  double get totalAppBarHeight => statusBarHeight + toolbarHeight;
}
