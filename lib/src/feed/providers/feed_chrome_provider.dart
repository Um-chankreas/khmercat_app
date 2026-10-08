import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the user is swiping through the video feed (and for a moment
/// after). The bottom nav bar slides away while it is, so the video gets the
/// whole screen; it returns once the swiping stops.
final feedChromeHiddenProvider = StateProvider<bool>((ref) => false);
