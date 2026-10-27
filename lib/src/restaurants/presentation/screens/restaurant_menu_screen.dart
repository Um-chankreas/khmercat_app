import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer_cat_app/core/components/dialogs/app_dialog.dart';
import 'package:khmer_cat_app/core/components/profile/profile_action_buttons.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant_menu.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_menu_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/restaurant_profile_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/menu_qr_sheet.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

/// Must match the API's limit (RestaurantMenuController::MAX_PAGES).
const _maxPages = 20;

/// A restaurant's menu, as photos of its pages.
///
/// Everyone: the pages in a two-column grid; tap one (or Preview) for a
/// full-screen, swipeable, pinch-to-zoom viewer; the QR button in the
/// header shows the scan-for-menu code. Owners/managers also get an
/// "Add page" tile, "Add pages" (multi-select, with upload progress) and a
/// ⋯ menu on each page to delete it.
class RestaurantMenuScreen extends HookConsumerWidget {
  final String restaurantId;
  const RestaurantMenuScreen({required this.restaurantId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = restaurantMenuControllerProvider(restaurantId);
    final menu = ref.watch(provider);
    final restaurant = ref.watch(
      restaurantProfileControllerProvider(
        restaurantId,
      ).select((s) => s.restaurant),
    );
    final isOwner =
        ref
            .watch(myRestaurantsControllerProvider)
            .valueOrNull
            ?.restaurants
            .any((r) => r.id == restaurantId) ??
        false;
    final uploadProgress = useState<double?>(null);
    final name = restaurant?.name ?? 'Menu';
    final menuUrl = menu.valueOrNull?.menuUrl ?? restaurant?.menuUrl;

    void showQr() {
      if (menuUrl == null || menuUrl.isEmpty) return;
      showMenuQrSheet(context, restaurantName: name, menuUrl: menuUrl);
    }

    Future<void> addPages() async {
      final current = menu.valueOrNull?.pages.length ?? 0;
      final remaining = _maxPages - current;
      if (remaining <= 0) {
        AppService.showToast(
          'A menu can have up to $_maxPages pages.',
          isError: true,
        );
        return;
      }
      List<XFile> picked;
      try {
        picked = await ImagePicker().pickMultiImage(
          imageQuality: 85,
          maxWidth: 2000,
          limit: remaining > 1 ? remaining : null,
        );
      } on PlatformException {
        AppService.showToast(
          'Photo access is off. Enable it in Settings to add menu pages.',
          isError: true,
        );
        return;
      }
      if (picked.isEmpty) return;
      if (picked.length > remaining) picked = picked.take(remaining).toList();

      uploadProgress.value = 0;
      try {
        await ref
            .read(provider.notifier)
            .addPages(
              picked.map((f) => File(f.path)).toList(),
              onProgress: (sent, total) {
                if (total > 0 && context.mounted) {
                  uploadProgress.value = sent / total;
                }
              },
            );
        HapticFeedback.lightImpact();
        AppService.showToast(
          picked.length == 1 ? 'Page added' : '${picked.length} pages added',
        );
      } on ApiException catch (e) {
        AppService.showToast(
          e.isValidationError ? e.allErrorsMessage : e.message,
          isError: true,
        );
      } catch (_) {
        AppService.showToast('Upload failed. Please try again.', isError: true);
      } finally {
        if (context.mounted) uploadProgress.value = null;
      }
    }

    void deletePage(MenuPage page) {
      AppDialogs.showConfirm(
        context,
        title: 'Delete this page?',
        message: 'It will be removed from your menu and its QR page.',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () async {
          final ok = await ref.read(provider.notifier).deletePage(page.id);
          if (!ok) {
            AppService.showToast('Could not delete the page.', isError: true);
          }
        },
      );
    }

    final pages = menu.valueOrNull?.pages ?? const <MenuPage>[];
    final uploading = uploadProgress.value != null;

    final canAdd = isOwner && pages.length < _maxPages;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftCirclesBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  title: 'Menu',
                  subtitle: restaurant?.name,
                  onQr: menuUrl != null && menuUrl.isNotEmpty ? showQr : null,
                ),
                Expanded(
                  child: menu.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: ProfileTheme.purple,
                      ),
                    ),
                    error: (_, _) => _Message(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load the menu',
                      action: TextButton(
                        onPressed: () => ref.read(provider.notifier).reload(),
                        child: const Text('Try again'),
                      ),
                    ),
                    data: (_) => RefreshIndicator(
                      color: ProfileTheme.purple,
                      onRefresh: () => ref.read(provider.notifier).reload(),
                      child: pages.isEmpty && !isOwner
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                _Message(
                                  icon: Icons.menu_book_rounded,
                                  title: 'No menu yet',
                                  subtitle:
                                      'This restaurant hasn\'t added its menu '
                                      'yet.',
                                ),
                              ],
                            )
                          : CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    12,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: _SectionTitle(
                                      count: pages.length,
                                      // Visitors don't need the limit.
                                      max: isOwner ? _maxPages : null,
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  sliver: SliverGrid.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.76,
                                    children: [
                                      for (var i = 0; i < pages.length; i++)
                                        _PageTile(
                                          page: pages[i],
                                          onOpen: () =>
                                              _openViewer(context, pages, i),
                                          onDelete: isOwner
                                              ? () => deletePage(pages[i])
                                              : null,
                                        ),
                                      if (canAdd)
                                        _AddPageTile(
                                          onTap: uploading ? null : addPages,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isOwner && pages.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                      ),
                                      child: Text(
                                        'Take or choose photos of your menu '
                                        'pages. Diners can read them here or '
                                        'by scanning your QR code.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          color: ProfileTheme.textSecondary(
                                            context,
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
        ],
      ),
      bottomNavigationBar: pages.isEmpty && !isOwner
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (uploading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uploadProgress.value,
                        minHeight: 5,
                        color: ProfileTheme.purple,
                        backgroundColor: ProfileTheme.purple.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    const Gap(10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewButton(
                          onTap: pages.isEmpty
                              ? null
                              : () => _openViewer(context, pages, 0),
                        ),
                      ),
                      if (isOwner) ...[
                        const Gap(12),
                        Expanded(
                          child: ProfileGradientButton(
                            text: uploading
                                ? '${((uploadProgress.value ?? 0) * 100).round()}%'
                                : 'Add pages',
                            icon: Icons.add_photo_alternate_outlined,
                            flat: true,
                            height: 50,
                            fontSize: 15,
                            onTap: uploading || menu.isLoading || !canAdd
                                ? null
                                : addPages,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  static void _openViewer(BuildContext context, List<MenuPage> pages, int i) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _MenuViewer(pages: pages, initialIndex: i),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// Back on the left, "Menu" over the restaurant's name in the middle, and
/// the QR code in a round white button on the right.
class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onQr;
  const _Header({required this.title, this.subtitle, this.onQr});

  @override
  Widget build(BuildContext context) {
    // Full width: in the page's centered Column it would otherwise shrink to
    // the title, pulling back and QR in next to it.
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: ProfileTheme.textPrimary(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ProfileTheme.textPrimary(context),
                  ),
                ),
                if (subtitle case final subtitle?)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ProfileTheme.textSecondary(context),
                    ),
                  ),
              ],
            ),
          ),
          if (onQr != null)
            Positioned(
              right: 16,
              child: Tooltip(
                message: 'Menu QR code',
                child: GestureDetector(
                  onTap: onQr,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: ProfileTheme.cardShadow(),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 22,
                      color: ProfileTheme.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Menu pages · 3 of 20" (owners), "Menu pages · 3" (visitors).
class _SectionTitle extends StatelessWidget {
  final int count;
  final int? max;
  const _SectionTitle({required this.count, this.max});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Menu pages',
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: ProfileTheme.textPrimary(context),
        ),
        children: [
          TextSpan(
            text: max == null ? ' · $count' : ' · $count of $max',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ProfileTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page's photo, cropped to the tile; tap for the full-screen viewer.
/// The team gets a ⋯ menu on it (View, Delete).
class _PageTile extends StatelessWidget {
  final MenuPage page;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  const _PageTile({required this.page, required this.onOpen, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Hero(
              tag: 'menu-page-${page.id}',
              child: CachedNetworkImage(
                imageUrl: page.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(
                  color: ProfileTheme.purple.withValues(alpha: 0.06),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ProfileTheme.purple,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => ColoredBox(
                  color: ProfileTheme.purple.withValues(alpha: 0.06),
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: ProfileTheme.muted,
                  ),
                ),
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              right: 8,
              top: 8,
              child: PopupMenuButton<void>(
                tooltip: 'More',
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                itemBuilder: (_) => [
                  PopupMenuItem(onTap: onOpen, child: const Text('View')),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Color(0xffE5484D)),
                    ),
                  ),
                ],
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The empty slot after the pages: a dashed pink outline with "Add page".
class _AddPageTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddPageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorder(color: ProfileTheme.brandPink, radius: 18),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: ProfileTheme.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 24,
                  color: ProfileTheme.ink,
                ),
              ),
              const Gap(12),
              Text(
                'Add page',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
              const Gap(2),
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 12.5,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded-rect outline drawn in dashes.
class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0, gap = 5.0;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}

/// White "Preview" button: opens the pages full-screen from the first one.
class _PreviewButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _PreviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null
        ? ProfileTheme.textSecondary(context)
        : ProfileTheme.textPrimary(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ProfileTheme.cardShadow(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_outlined, size: 19, color: fg),
            const Gap(8),
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dark label over a photo ("2 / 5" in the viewer).
class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Full-screen pages: swipe between them, pinch or double-tap to zoom.
class _MenuViewer extends HookWidget {
  final List<MenuPage> pages;
  final int initialIndex;
  const _MenuViewer({required this.pages, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    final index = useState(initialIndex);
    final controller = usePageController(initialPage: initialIndex);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (i) => index.value = i,
              itemBuilder: (_, i) => _ZoomablePage(page: pages[i]),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _Chip(text: '${index.value + 1} / ${pages.length}'),
                    const Gap(12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePage extends HookWidget {
  final MenuPage page;
  const _ZoomablePage({required this.page});

  @override
  Widget build(BuildContext context) {
    final transform = useMemoized(TransformationController.new);
    useEffect(() => transform.dispose, [transform]);
    final tapPosition = useRef(Offset.zero);

    return GestureDetector(
      onDoubleTapDown: (d) => tapPosition.value = d.localPosition,
      onDoubleTap: () {
        // Double-tap: zoom 2.5x into the tapped spot, or back out.
        if (transform.value.getMaxScaleOnAxis() > 1.01) {
          transform.value = Matrix4.identity();
        } else {
          final p = tapPosition.value;
          transform.value = Matrix4.identity()
            ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
            ..scaleByDouble(2.5, 2.5, 1, 1);
        }
      },
      child: InteractiveViewer(
        transformationController: transform,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Hero(
            tag: 'menu-page-${page.id}',
            child: CachedNetworkImage(imageUrl: page.url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final muted = ProfileTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ProfileTheme.purple.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: ProfileTheme.purple),
          ),
          const Gap(14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ProfileTheme.textPrimary(context),
            ),
          ),
          if (subtitle != null) ...[
            const Gap(6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: muted),
            ),
          ],
          if (action != null) ...[const Gap(8), action!],
        ],
      ),
    );
  }
}
