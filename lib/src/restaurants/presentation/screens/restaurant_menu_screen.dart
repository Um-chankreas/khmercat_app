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

/// Must match the API's limit (RestaurantMenuController::MAX_PAGES).
const _maxPages = 20;

/// A restaurant's menu, as photos of its pages.
///
/// Everyone: scroll the pages; tap one for a full-screen, swipeable,
/// pinch-to-zoom viewer; the QR button shows the scan-for-menu code.
/// Owners/managers also get a QR banner, "Add pages" (multi-select, with
/// upload progress) and a delete button on each page.
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

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Menu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (restaurant != null)
              Text(
                restaurant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ProfileTheme.textSecondary(context),
                ),
              ),
          ],
        ),
        actions: [
          if (menuUrl != null && menuUrl.isNotEmpty)
            IconButton(
              tooltip: 'Menu QR code',
              onPressed: showQr,
              icon: const Icon(
                Icons.qr_code_2_rounded,
                color: ProfileTheme.deepPurple,
              ),
            ),
          const Gap(4),
        ],
      ),
      body: menu.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ProfileTheme.purple),
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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, isOwner ? 110 : 24),
            children: [
              if (isOwner) ...[_QrBanner(onTap: showQr), const Gap(16)],
              if (pages.isEmpty)
                _Message(
                  icon: Icons.menu_book_rounded,
                  title: isOwner ? 'Add your menu' : 'No menu yet',
                  subtitle: isOwner
                      ? 'Take or choose photos of your menu pages. Diners can '
                            'read them here or by scanning your QR code.'
                      : 'This restaurant hasn\'t added its menu yet.',
                )
              else
                for (var i = 0; i < pages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PageCard(
                      page: pages[i],
                      number: i + 1,
                      onOpen: () => _openViewer(context, pages, i),
                      onDelete: isOwner ? () => deletePage(pages[i]) : null,
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isOwner
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                  ProfileGradientButton(
                    text: uploading
                        ? 'Uploading… ${((uploadProgress.value ?? 0) * 100).round()}%'
                        : 'Add pages  (${pages.length}/$_maxPages)',
                    icon: Icons.add_photo_alternate_rounded,
                    flat: true,
                    height: 46,
                    fontSize: 14.5,
                    onTap: uploading || menu.isLoading ? null : addPages,
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

/// "Your menu QR code" — the owner's shortcut to print a table QR.
class _QrBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _QrBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: ProfileTheme.gradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 30,
                    color: ProfileTheme.deepPurple,
                  ),
                ),
                const Gap(12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your menu QR code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Gap(2),
                      Text(
                        'Print it for your tables — diners scan to see the '
                        'menu, no app needed.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  final MenuPage page;
  final int number;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  const _PageCard({
    required this.page,
    required this.number,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileTheme.hairlineColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Hero(
              tag: 'menu-page-${page.id}',
              child: CachedNetworkImage(
                imageUrl: page.url,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                placeholder: (_, _) => AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: ProfileTheme.purple.withValues(alpha: 0.06),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ProfileTheme.purple,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: ProfileTheme.purple.withValues(alpha: 0.06),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: ProfileTheme.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 10, top: 10, child: _Chip(text: 'Page $number')),
          if (onDelete != null)
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.white,
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
