import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

const _bgTop = Color(0xffF8C8DE);
const _bgBottom = Color(0xffCFE1F8);
const _background = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_bgTop, _bgBottom],
);

/// Opens a person's profile QR code, sliding up from the bottom.
Future<void> openProfileQr(
  BuildContext context, {
  required String name,
  required String username,
  String? avatarUrl,
}) => _openQr(
  context,
  ProfileQrScreen(
    name: name,
    subtitle: '@$username',
    link: AppConfig.profileLink(username),
    fileSlug: username,
    avatarUrl: avatarUrl,
  ),
);

/// Opens a restaurant's profile QR code: the same card, with its logo and
/// [category] under the name.
Future<void> openRestaurantQr(
  BuildContext context, {
  required String name,
  required String restaurantId,
  String? category,
  String? avatarUrl,
}) => _openQr(
  context,
  ProfileQrScreen(
    name: name,
    subtitle: category,
    link: AppConfig.restaurantLink(restaurantId),
    fileSlug: 'restaurant-$restaurantId',
    avatarUrl: avatarUrl,
  ),
);

Future<void> _openQr(BuildContext context, ProfileQrScreen screen) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// "Profile QR": the profile's card with a QR code of its link, to save to
/// the gallery or share.
class ProfileQrScreen extends StatefulWidget {
  final String name;

  /// Under the name: "@username", or a restaurant's category.
  final String? subtitle;

  /// What the QR code opens.
  final String link;

  /// Names the saved image (`khmercat-<slug>-qr`).
  final String fileSlug;
  final String? avatarUrl;
  const ProfileQrScreen({
    required this.name,
    required this.link,
    required this.fileSlug,
    this.subtitle,
    this.avatarUrl,
    super.key,
  });

  @override
  State<ProfileQrScreen> createState() => _ProfileQrScreenState();
}

class _ProfileQrScreenState extends State<ProfileQrScreen> {
  /// Wraps the card (and its avatar), so exactly that is captured.
  final _cardKey = GlobalKey();
  bool _busy = false;

  String get _link => widget.link;

  /// The card as a PNG on the screen's pink → blue background (the card
  /// alone has transparent corners around the avatar).
  Future<Uint8List> _cardPng() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    const ratio = 3.0;
    final card = await boundary.toImage(pixelRatio: ratio);
    const pad = 28 * ratio;
    final w = card.width + pad * 2;
    final h = card.height + pad * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, Paint()..shader = _background.createShader(rect));
    canvas.drawImage(card, const Offset(pad, pad), Paint());
    final image = await recorder.endRecording().toImage(w.round(), h.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('no image');
    return bytes.buffer.asUint8List();
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      AppService.showToast(failure, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
    try {
      await Gal.putImageBytes(
        await _cardPng(),
        name: 'khmercat-${widget.fileSlug}-qr',
      );
      AppService.showToast('Saved to your photos');
    } on GalException catch (e) {
      AppService.showToast(
        e.type == GalExceptionType.accessDenied
            ? 'Allow photo access to save the image.'
            : 'Couldn\'t save the image.',
        isError: true,
      );
    }
  }, 'Couldn\'t save the image.');

  Future<void> _share() => _run(() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            await _cardPng(),
            mimeType: 'image/png',
            name: 'profile-qr.png',
          ),
        ],
        fileNameOverrides: ['profile-qr.png'],
        text: [
          widget.name,
          if (widget.subtitle case final subtitle?) '($subtitle)',
          'on KhmerCat: $_link',
        ].join(' '),
        subject: 'KhmerCat',
      ),
    );
  }, 'Couldn\'t share the QR code.');

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: _background),
          child: SafeArea(
            child: Column(
              children: [
                // ---- Top bar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 16,
                        child: _BackButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const Text(
                        'Profile QR',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ProfileTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _QrCard(
                        name: widget.name,
                        subtitle: widget.subtitle,
                        avatarUrl: widget.avatarUrl,
                        link: _link,
                      ),
                    ),
                  ),
                ),
                // ---- Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: 'Save image',
                          dark: false,
                          onTap: _busy ? null : _save,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _PillButton(
                          label: 'Share',
                          dark: true,
                          onTap: _busy ? null : _share,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final String link;
  const _QrCard({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.link,
  });

  static const _avatar = 84.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: _avatar / 2),
          padding: const EdgeInsets.fromLTRB(24, _avatar / 2 + 14, 24, 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff3B1C7A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.ink,
                ),
              ),
              if (subtitle case final subtitle?) ...[
                const Gap(4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: ProfileTheme.muted,
                  ),
                ),
              ],
              const Gap(18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F4F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: link,
                  size: 188,
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xffF3F4F7),
                  // High error correction so the logo in the middle doesn't
                  // stop it scanning.
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: ProfileTheme.ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: ProfileTheme.ink,
                  ),
                  embeddedImage: AssetImage(AssetsName.appLogoTrsm),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(40, 40),
                  ),
                ),
              ),
              const Gap(16),
              const Text(
                'Scan to open this profile in KhmerCat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ProfileTheme.muted),
              ),
            ],
          ),
        ),
        _Avatar(url: avatarUrl, name: name, size: _avatar),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: ProfileTheme.brandGradient,
                ),
                child: Center(
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: ProfileTheme.ink,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(AssetsName.back),
      ),
    );
  }
}

/// "Save image" (white) / "Share" (black) pill.
class _PillButton extends StatelessWidget {
  final String label;
  final bool dark;
  final VoidCallback? onTap;
  const _PillButton({
    required this.label,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? const Color(0xff17171C) : Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : ProfileTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
