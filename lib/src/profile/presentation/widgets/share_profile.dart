import 'package:share_plus/share_plus.dart';

import '../../../auth/domain/entities/user.dart';

/// Opens the platform share sheet with the user's name and handle. There's
/// no public profile web page / deep link yet, so this shares plain text
/// rather than a link, mirroring `shareVideo`.
Future<void> shareProfile(User user) {
  return SharePlus.instance.share(
    ShareParams(
      text: '${user.name} (@${user.username}) on Khmer Cat',
      subject: 'Khmer Cat',
    ),
  );
}
