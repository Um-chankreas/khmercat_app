import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/core/utils/social_links.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shows the restaurant's menu QR code. Diners scan it with any phone
/// camera to open the menu web page — no app needed. The owner can share
/// or save the QR card as an image (to print for tables), copy the link,
/// or open the page to check it.
Future<void> showMenuQrSheet(
  BuildContext context, {
  required String restaurantName,
  required String menuUrl,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _MenuQrSheet(restaurantName: restaurantName, menuUrl: menuUrl),
  );
}

class _MenuQrSheet extends StatefulWidget {
  final String restaurantName;
  final String menuUrl;
  const _MenuQrSheet({required this.restaurantName, required this.menuUrl});

  @override
  State<_MenuQrSheet> createState() => _MenuQrSheetState();
}

class _MenuQrSheetState extends State<_MenuQrSheet> {
  /// Wraps the printable card, so exactly that is captured as the image.
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // 3x so it stays sharp when printed.
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no image');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'menu-qr.png',
            ),
          ],
          fileNameOverrides: ['menu-qr.png'],
          text: '${widget.restaurantName} menu: ${widget.menuUrl}',
          subject: '${widget.restaurantName} menu',
        ),
      );
    } catch (_) {
      AppService.showToast('Couldn\'t share the QR code.', isError: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),

            // ---- The printable card (always white, so it prints well).
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 280,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ProfileTheme.purple.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          ProfileTheme.pinkPurple.createShader(r),
                      child: const Text(
                        'SCAN FOR MENU',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      widget.restaurantName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ProfileTheme.ink,
                      ),
                    ),
                    const Gap(14),
                    QrImageView(
                      data: widget.menuUrl,
                      size: 220,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      // High error correction so the logo in the middle
                      // doesn't stop it scanning.
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: ProfileTheme.deepPurple,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: ProfileTheme.ink,
                      ),
                      embeddedImage: AssetImage(AssetsName.appLogoTrsm),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(46, 46),
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      'Point your phone camera here',
                      style: TextStyle(fontSize: 12, color: ProfileTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(14),
            Text(
              widget.menuUrl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
            const Gap(16),

            // ---- Actions
            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ProfileTheme.pinkPurple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton.icon(
                  onPressed: _sharing ? null : _shareImage,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 19),
                  label: const Text('Share or save QR code'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.menuUrl),
                      );
                      AppService.showToast('Menu link copied');
                    },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy link'),
                    style: TextButton.styleFrom(
                      foregroundColor: ProfileTheme.deepPurple,
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      final uri = Uri.tryParse(widget.menuUrl);
                      if (uri != null) SocialLinks.open(uri);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open page'),
                    style: TextButton.styleFrom(
                      foregroundColor: ProfileTheme.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
