import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/components/rating/rating_badge.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/location_picker_screen.dart';
import 'package:khmer_cat_app/src/search/presentation/discover_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/nearby_map_controller.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/map_pins.dart';
import 'package:khmer_cat_app/src/search/presentation/widgets/search_widgets.dart';

// Shown until the device position is known.
const _phnomPenh = LatLng(11.5564, 104.9282);
const _radiiKm = [0.5, 1.0, 2.0, 3.0, 4.0, nearbyMapMaxKm];
const _defaultKm = 2.0;
const _cardHeight = 218.0;

/// Full-screen map of the restaurants around the user: a circle of the
/// chosen radius with a pin for every restaurant inside it. On top, the
/// location (with "Change" to search for another place) over the radius
/// chips, up to [nearbyMapMaxKm]; at the bottom, a carousel of the same
/// restaurants. Dragging the center pin or long-pressing the map also
/// moves the search.
class RestaurantMapScreen extends HookConsumerWidget {
  const RestaurantMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(locationProvider);
    // Where the user moved the search to; null = their own position.
    final moved = useState<LatLng?>(null);
    // The address or place name of [moved], when it was picked by name.
    final movedLabel = useState<String?>(null);
    final map = useState<GoogleMapController?>(null);
    final radiusKm = useState(_defaultKm);
    final selectedId = useState<String?>(null);
    final pages = usePageController(viewportFraction: 0.8);

    final here = position == null
        ? null
        : LatLng(position.latitude, position.longitude);
    final center = moved.value ?? here;
    final nearbyProvider = center == null
        ? null
        : nearbyMapProvider((lat: center.latitude, lng: center.longitude));
    final AsyncValue<List<NearbyRestaurant>> nearby = nearbyProvider == null
        ? const AsyncData([])
        : ref.watch(nearbyProvider);
    final inRadius = [
      for (final n in nearby.value ?? const <NearbyRestaurant>[])
        if (n.meters! <= radiusKm.value * 1000) n,
    ];
    // The carousel always rests on a card, so one is always selected.
    final selected =
        inRadius
            .where((n) => n.restaurant.id == selectedId.value)
            .firstOrNull ??
        inRadius.firstOrNull;

    void moveTo(LatLng point, {String? label}) {
      moved.value = point;
      movedLabel.value = label;
    }

    // Search for a place by name, or pin one, on the location picker.
    Future<void> changeLocation() async {
      final picked = await Navigator.of(context).push<LocationPickResult>(
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLocation: center ?? _phnomPenh,
            initialAddress: movedLabel.value,
          ),
        ),
      );
      if (picked == null) return;
      moveTo(picked.location, label: picked.name ?? picked.address);
    }

    void fitRadius() {
      final controller = map.value;
      if (controller == null || center == null) return;
      controller
          .animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsAround(center, radiusKm.value * 1000),
              24,
            ),
          )
          // The map can be gone (or not laid out yet) by the time this runs.
          .catchError((_) {});
    }

    // Keep the whole circle in view as it moves or resizes.
    useEffect(() {
      fitRadius();
      return null;
    }, [map.value, radiusKm.value, center]);

    // When the set of restaurants changes, put the carousel back on the
    // selected one (or the first, if it dropped out).
    final ids = [for (final n in inRadius) n.restaurant.id].join(',');
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!pages.hasClients) return;
        final index = inRadius.indexWhere(
          (n) => n.restaurant.id == selectedId.value,
        );
        pages.jumpToPage(index < 0 ? 0 : index);
      });
      return null;
    }, [ids]);

    void selectFromPin(String id) {
      selectedId.value = id;
      final index = inRadius.indexWhere((n) => n.restaurant.id == id);
      if (index < 0 || !pages.hasClients) return;
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    // Drawn once per screen density and profile photo; the stock pins
    // stand in until then.
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final photoUrl = ref.watch(currentUserProvider)?.profilePicture;
    final pins = useFuture(
      useMemoized(() => MapPins.load(pixelRatio, userPhotoUrl: photoUrl), [
        pixelRatio,
        photoUrl,
      ]),
    ).data;

    final String status;
    VoidCallback? onStatusTap;
    if (center == null) {
      status = 'Turn on location to see restaurants';
      onStatusTap = ref.read(locationProvider.notifier).enable;
    } else if (nearby.hasError) {
      status = 'Couldn\'t load restaurants · Retry';
      onStatusTap = () => ref.invalidate(nearbyProvider!);
    } else if (nearby.isLoading && !nearby.hasValue) {
      status = 'Finding restaurants…';
    } else {
      final within = 'within ${formatDistance(radiusKm.value * 1000)}';
      status = switch (inRadius.length) {
        0 => 'No restaurants $within',
        1 => '1 restaurant $within',
        final n => '$n restaurants $within',
      };
    }

    final safe = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center ?? _phnomPenh,
              zoom: 13,
            ),
            onMapCreated: (c) => map.value = c,
            // Keeps the circle and the Google logo clear of the overlays.
            padding: EdgeInsets.only(
              top: safe.top + 112,
              bottom:
                  safe.bottom + 64 + (inRadius.isEmpty ? 0 : _cardHeight + 10),
            ),
            myLocationEnabled: here != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onLongPress: moveTo,
            circles: {
              if (center != null)
                Circle(
                  circleId: const CircleId('radius'),
                  center: center,
                  radius: radiusKm.value * 1000,
                  fillColor: searchAccent.withValues(alpha: 0.08),
                  strokeColor: searchAccent.withValues(alpha: 0.55),
                  strokeWidth: 2,
                ),
            },
            markers: {
              // The middle of the search; drag it to look somewhere else.
              if (center != null)
                Marker(
                  markerId: const MarkerId('center'),
                  position: center,
                  draggable: true,
                  zIndexInt: 1,
                  icon:
                      pins?.user ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                  onDragEnd: moveTo,
                ),
              for (final n in inRadius)
                Marker(
                  markerId: MarkerId(n.restaurant.id),
                  position: LatLng(
                    n.restaurant.latitude!,
                    n.restaurant.longitude!,
                  ),
                  zIndexInt: n == selected ? 2 : 0,
                  icon: n == selected
                      ? pins?.selectedRestaurant ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueViolet,
                            )
                      : pins?.restaurant ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRose,
                            ),
                  onTap: () => selectFromPin(n.restaurant.id),
                ),
            },
          ),

          // ---- Back · location · recenter, over the radius chips
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _LocationPill(
                          label: moved.value != null
                              ? movedLabel.value ?? 'Pinned location'
                              : here != null
                              ? 'Your location'
                              : 'No location yet',
                          onChange: changeLocation,
                        ),
                      ),
                      const Gap(10),
                      _RoundButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Back to my location',
                        onTap: () {
                          if (here == null) {
                            ref.read(locationProvider.notifier).enable();
                            return;
                          }
                          // Already there: just bring the circle into view.
                          if (moved.value == null) fitRadius();
                          moved.value = null;
                          movedLabel.value = null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _radiiKm.length,
                    separatorBuilder: (_, _) => const Gap(6),
                    itemBuilder: (context, i) => _RadiusChip(
                      label: formatDistance(_radiiKm[i] * 1000),
                      selected: radiusKm.value == _radiiKm[i],
                      onTap: () => radiusKm.value = _radiiKm[i],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Count, over the restaurant carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: safe.bottom + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _StatusPill(text: status, onTap: onStatusTap),
                ),
                if (inRadius.isNotEmpty) ...[
                  const Gap(10),
                  SizedBox(
                    height: _cardHeight,
                    child: PageView.builder(
                      controller: pages,
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: inRadius.length,
                      onPageChanged: (i) =>
                          selectedId.value = inRadius[i].restaurant.id,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _RestaurantCard(
                          item: inRadius[i],
                          selected: inRadius[i] == selected,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The box that just contains a circle of [meters] around [center].
LatLngBounds _boundsAround(LatLng center, double meters) {
  const metersPerDegree = 111320.0;
  final dLat = meters / metersPerDegree;
  final dLng =
      meters / (metersPerDegree * math.cos(center.latitude * math.pi / 180));
  return LatLngBounds(
    southwest: LatLng(center.latitude - dLat, center.longitude - dLng),
    northeast: LatLng(center.latitude + dLat, center.longitude + dLng),
  );
}

List<BoxShadow> _floatShadow() => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.10),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
];

/// White circle button floating on the map.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: _floatShadow(),
          ),
          child: Icon(icon, size: 20, color: ProfileTheme.textPrimary(context)),
        ),
      ),
    );
  }
}

/// Where the map is searching around, with a button to pick another place.
class _LocationPill extends StatelessWidget {
  final String label;
  final VoidCallback onChange;
  const _LocationPill({required this.label, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChange,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _floatShadow(),
        ),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, size: 20, color: searchAccent),
            const Gap(8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: ProfileTheme.textPrimary(context),
                ),
              ),
            ),
            const Gap(8),
            const Text(
              'Change',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: searchAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One radius choice; the selected one takes the pink → periwinkle wash.
class _RadiusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadiusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? null : Theme.of(context).colorScheme.surface,
          gradient: selected ? searchSoftGradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _floatShadow(),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? ProfileTheme.ink
                : ProfileTheme.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

/// "3 restaurants within 2 km", or what's in the way of showing them (then
/// tappable, with [onTap] fixing it).
class _StatusPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _StatusPill({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _floatShadow(),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: onTap == null
                ? ProfileTheme.textPrimary(context)
                : searchAccent,
          ),
        ),
      ),
    );
  }
}

/// A restaurant in the carousel: cover photo over name + rating and
/// category · distance. The selected one has a brand-gradient outline;
/// tapping opens its profile.
class _RestaurantCard extends StatelessWidget {
  final NearbyRestaurant item;
  final bool selected;
  const _RestaurantCard({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final r = item.restaurant;
    final primary = ProfileTheme.textPrimary(context);
    final meta = [
      ?r.category?.name,
      '${formatDistance(item.meters!)} away',
    ].join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openRestaurant(r.id),
      // The outline is a gradient box showing around the inset card.
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          gradient: selected ? ProfileTheme.gradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _floatShadow(),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(17.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: NetImage(
                    url: r.coverPicture ?? r.profilePicture,
                    cacheWidth: 320,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                        if (r.avgRating != null) ...[
                          const Gap(8),
                          RatingBadge(
                            rating: r.avgRating!,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: ProfileTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
