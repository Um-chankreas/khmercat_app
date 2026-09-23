import 'package:share_plus/share_plus.dart';

import '../../domain/video_feed_item.dart';

/// Opens the platform share sheet with the video's caption and a direct link
/// to the stream. There's no web landing page / deep link yet, so the shared
/// link opens (or downloads) the raw video file rather than an app screen.
Future<void> shareVideo(VideoFeedItem item) {
  final caption = item.caption.trim();
  final text = caption.isEmpty ? item.videoUrl : '$caption\n\n${item.videoUrl}';

  return SharePlus.instance.share(
    ShareParams(text: text, subject: 'Khmer Cat'),
  );
}
