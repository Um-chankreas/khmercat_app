import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/utils/assets_name.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/restaurant.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/my_restaurants_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/widgets/restaurant_logo.dart';
import 'package:khmer_cat_app/src/search/presentation/search_controller.dart';

/// Which upload endpoint the picked restaurant is for — reviewing someone
/// else's restaurant vs. posting on behalf of one you own/manage.
enum UploadMode { review, restaurantPost }

typedef UploadTargetSelection = ({UploadMode mode, Restaurant restaurant});

const _pink = Color(0xffFF54AB);
const _purple = Color(0xff9B6BFF);
const _blue = Color(0xff74BFFF);
const _ink = Color(0xff1F1B3A);
const _muted = Color(0xff7A7896);

const _sheetGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_pink, _purple, _blue],
);

List<BoxShadow> _softShadow([double alpha = 0.05]) => [
  BoxShadow(
    color: _purple.withValues(alpha: alpha),
    blurRadius: 12,
    offset: const Offset(0, 3),
  ),
];

/// Full-screen picker for the upload target. Two tabs when the user owns at
/// least one restaurant:
///  - "Review" — search any restaurant to review it.
///  - "My restaurant" — pick one of your own to post as.
/// Users with no restaurants of their own only ever see the review tab.
Future<UploadTargetSelection?> showUploadTargetSheet(BuildContext context) {
  return showModalBottomSheet<UploadTargetSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _UploadTargetSheet(),
  );
}

class _UploadTargetSheet extends HookConsumerWidget {
  const _UploadTargetSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRestaurants = ref.watch(myRestaurantsControllerProvider);
    final myList =
        myRestaurants.valueOrNull?.restaurants ?? const <Restaurant>[];
    final hasOwnRestaurants = myList.isNotEmpty;

    // Acting as a restaurant → open on "My restaurant".
    final mode = useState(
      myRestaurants.valueOrNull?.activeRestaurantId != null && hasOwnRestaurants
          ? UploadMode.restaurantPost
          : UploadMode.review,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const Gap(10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(14),
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Select a restaurant',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _ink,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: Material(
                          color: const Color(0xffF3F1FA),
                          shape: const CircleBorder(),
                          elevation: 0,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: _muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                if (hasOwnRestaurants) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ModeToggle(
                      value: mode.value,
                      onChanged: (m) => mode.value = m,
                    ),
                  ),
                  const Gap(14),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    child: KeyedSubtree(
                      key: ValueKey(mode.value),
                      child: mode.value == UploadMode.restaurantPost
                          ? _MyRestaurantsList(
                              restaurants: myList,
                              activeId:
                                  myRestaurants.valueOrNull?.activeRestaurantId,
                              scrollController: scrollController,
                            )
                          : _RestaurantSearchList(
                              scrollController: scrollController,
                            ),
                    ),
                  ),
                ),
                if (mode.value == UploadMode.restaurantPost)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _softShadow(),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: _purple,
                        ),
                        Gap(10),
                        Expanded(
                          child: Text(
                            'Manage menus, orders, and stories directly on your profile',
                            style: TextStyle(fontSize: 12.5, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Segmented control with a gradient thumb that slides between the tabs.
class _ModeToggle extends StatelessWidget {
  final UploadMode value;
  final ValueChanged<UploadMode> onChanged;
  const _ModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isReview = value == UploadMode.review;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _purple.withValues(alpha: 0.10)),
        boxShadow: _softShadow(),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: isReview ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _sheetGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ModeSegment(
                  label: 'Review',
                  iconAsset: AssetsName.review,
                  selected: isReview,
                  onTap: () => onChanged(UploadMode.review),
                ),
              ),
              Expanded(
                child: _ModeSegment(
                  label: 'My restaurant',
                  iconAsset: AssetsName.foodservice,
                  selected: !isReview,
                  onTap: () => onChanged(UploadMode.restaurantPost),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : _muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: color,
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1,
                duration: const Duration(milliseconds: 200),
                child: Image.asset(
                  iconAsset,
                  width: 18,
                  height: 18,
                  color: color,
                ),
              ),
              const Gap(7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRestaurantsList extends StatelessWidget {
  final List<Restaurant> restaurants;
  final String? activeId;
  final ScrollController scrollController;

  const _MyRestaurantsList({
    required this.restaurants,
    required this.activeId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const _EmptyState(
        icon: Icons.storefront_outlined,
        title: 'No restaurants yet',
        message: 'You don\'t manage any restaurants yet.',
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final r = restaurants[index];
        final isActive = r.id == activeId;
        return _AnimatedEntry(
          index: index,
          child: _RestaurantRow(
            restaurant: r,
            highlighted: isActive,
            status: _StatusChip(active: isActive),
            onTap: () => Navigator.of(
              context,
            ).pop((mode: UploadMode.restaurantPost, restaurant: r)),
          ),
        );
      },
    );
  }
}

class _RestaurantSearchList extends HookConsumerWidget {
  final ScrollController scrollController;
  const _RestaurantSearchList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final inputCtr = useTextEditingController();
    final focus = useFocusNode();
    // Rebuild on focus / text change for the border glow + clear button.
    useListenable(focus);
    useListenable(inputCtr);

    Widget body;
    if (!state.hasSearched) {
      body = const _EmptyState(
        key: ValueKey('idle'),
        icon: Icons.search_rounded,
        title: 'Find a restaurant',
        message: 'Start typing to find a restaurant',
      );
    } else if (state.isLoading) {
      body = const _SkeletonList(key: ValueKey('loading'));
    } else if (state.errorMessage != null && state.restaurants.isEmpty) {
      body = _EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: state.errorMessage!,
      );
    } else if (state.restaurants.isEmpty) {
      body = _EmptyState(
        key: const ValueKey('empty'),
        icon: Icons.search_off_rounded,
        title: 'No restaurants found',
        message:
            'We couldn\'t find anything for "${state.query}".\n'
            'Try a different name.',
      );
    } else {
      body = ListView.builder(
        key: ValueKey('results-${state.query}'),
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: state.restaurants.length,
        itemBuilder: (context, index) {
          final r = state.restaurants[index];
          return _AnimatedEntry(
            index: index,
            child: _RestaurantRow(
              restaurant: r,
              onTap: () => Navigator.of(
                context,
              ).pop((mode: UploadMode.review, restaurant: r)),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: focus.hasFocus
                    ? _purple.withValues(alpha: 0.7)
                    : _purple.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: _softShadow(),
            ),
            child: TextField(
              controller: inputCtr,
              focusNode: focus,
              autofocus: true,
              onChanged: vm.onQueryChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: TextStyle(
                  color: _muted.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: ShaderMask(
                  shaderCallback: (r) => _sheetGradient.createShader(r),
                  child: const Icon(Icons.search_rounded, color: Colors.white),
                ),
                suffixIcon: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: _purple,
                          ),
                        ),
                      )
                    : inputCtr.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: _muted),
                        onPressed: () {
                          inputCtr.clear();
                          vm.onQueryChanged('');
                        },
                      )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: body,
          ),
        ),
      ],
    );
  }
}

/// Fades + slides a list item in, staggered by its index.
class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (index.clamp(0, 8)) * 45);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350) + delay,
      curve: Interval(
        delay.inMilliseconds / (350 + delay.inMilliseconds),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xff22A45D) : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const Gap(5),
          Text(
            active ? 'Currently active' : 'Offline',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final Restaurant restaurant;
  final Widget? status;
  final bool highlighted;
  final VoidCallback onTap;

  const _RestaurantRow({
    required this.restaurant,
    required this.onTap,
    this.status,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final category = r.category?.name;
    final address = r.address?.trim();
    final followers = r.followersCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(highlighted ? 1.5 : 0),
        decoration: BoxDecoration(
          gradient: highlighted ? _sheetGradient : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(highlighted ? 20.5 : 22),
            side: highlighted
                ? BorderSide.none
                : BorderSide(color: _purple.withValues(alpha: 0.10)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.black.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RestaurantLogo(restaurant: r),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            letterSpacing: -0.2,
                            color: _ink,
                          ),
                        ),
                        if (category != null && category.isNotEmpty) ...[
                          const Gap(4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff6B4EFF),
                              ),
                            ),
                          ),
                        ],
                        if (address != null && address.isNotEmpty) ...[
                          const Gap(6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: _pink,
                              ),
                              const Gap(3),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (followers != null) ...[
                          const Gap(4),
                          Row(
                            children: [
                              const Icon(
                                Icons.people_alt_rounded,
                                size: 14,
                                color: _blue,
                              ),
                              const Gap(3),
                              Text(
                                '$followers follower${followers == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (status != null) ...[const Gap(8), status!],
                      ],
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: _sheetGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _pink.withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _pink.withValues(alpha: 0.18),
                      _blue.withValues(alpha: 0.22),
                    ],
                  ),
                ),
                child: ShaderMask(
                  shaderCallback: (r) => _sheetGradient.createShader(r),
                  child: Icon(icon, size: 44, color: Colors.white),
                ),
              ),
            ),
            const Gap(18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const Gap(6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing placeholder cards shown while a search is in flight.
class _SkeletonList extends HookWidget {
  const _SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final t = useAnimation(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    final bar = _purple.withValues(alpha: 0.07 + 0.08 * t);

    Widget block(double w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 4,
      itemBuilder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _softShadow(),
        ),
        child: Row(
          children: [
            block(56, 56, 16),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(150, 16),
                  const Gap(8),
                  block(90, 12),
                  const Gap(8),
                  block(200, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
