import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/image_network/cat_head_avatar.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/place_suggestion.dart';
import 'package:khmer_cat_app/src/restaurants/providers/places_providers.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';

import '../domain/saved_address.dart';
import 'address_widgets.dart';
import 'addresses_controller.dart';

// Shown until the device position is known.
const _phnomPenh = LatLng(11.5564, 104.9282);

// The bottom sheet's height, not counting the system inset under it. Fixed
// so the map can keep its pin centered in the space above the sheet.
const _sheetHeight = 234.0;

/// Add (or, with [initial], edit) a saved address. The pin stays in the
/// middle of the map and the map moves under it; the street address is
/// looked up for wherever it lands. Searching for a place moves the map
/// there. Below: an optional house / building line, a Home / Office /
/// Other label, and Save.
class AddressFormScreen extends HookConsumerWidget {
  final SavedAddress? initial;
  const AddressFormScreen({this.initial, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = this.initial;
    final l = AppLocalizations.of(context);
    final position = ref.watch(locationProvider);
    final here = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    final map = useState<GoogleMapController?>(null);
    // Where the pin is. Follows the camera without rebuilding each frame.
    final target = useRef<LatLng>(
      initial != null
          ? LatLng(initial.latitude, initial.longitude)
          : here ?? _phnomPenh,
    );
    // The spot [address] belongs to, so a camera that settles back on it
    // (first frame, keyboard, a search result) doesn't look it up again.
    final resolvedAt = useRef<LatLng?>(initial == null ? null : target.value);
    final address = useState<String?>(initial?.address);
    final resolving = useState(false);
    final lookupSeq = useRef(0);
    final userMoved = useRef(false);
    // The map is being dragged or animated: the pin lifts off the ground.
    final moving = useState(false);

    final label = useState(initial?.label ?? AddressLabel.home);
    final detailCtr = useTextEditingController(text: initial?.detail ?? '');
    final saving = useState(false);

    final searchCtr = useTextEditingController();
    final searchFocus = useFocusNode();
    final suggestions = useState(const <PlaceSuggestion>[]);
    final debounce = useRef<Timer?>(null);
    useEffect(
      () =>
          () => debounce.value?.cancel(),
      const [],
    );

    Future<void> resolve(LatLng point) async {
      final seq = ++lookupSeq.value;
      resolving.value = true;
      final found = await ref
          .read(placesRepositoryProvider)
          .reverseGeocode(point.latitude, point.longitude);
      if (!context.mounted || seq != lookupSeq.value) return;
      resolvedAt.value = point;
      // No street address there (or no connection): the coordinates still
      // pin the spot down.
      address.value =
          found ??
          '${point.latitude.toStringAsFixed(5)}, '
              '${point.longitude.toStringAsFixed(5)}';
      resolving.value = false;
    }

    void onCameraIdle() {
      final point = target.value;
      final last = resolvedAt.value;
      if (last != null &&
          Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                point.latitude,
                point.longitude,
              ) <
              3) {
        return;
      }
      resolve(point);
    }

    void moveCamera(LatLng point) {
      target.value = point;
      map.value?.animateCamera(CameraUpdate.newLatLngZoom(point, 17));
    }

    // A new address starts on the user's position once it's known, unless
    // they've already moved the map themselves.
    useEffect(() {
      if (initial == null && here != null && !userMoved.value) {
        moveCamera(here);
      }
      return null;
    }, [here, map.value]);

    void onSearchChanged(String query) {
      debounce.value?.cancel();
      if (query.trim().isEmpty) {
        suggestions.value = const [];
        return;
      }
      debounce.value = Timer(const Duration(milliseconds: 400), () async {
        try {
          final results = await ref
              .read(placesRepositoryProvider)
              .autocomplete(query);
          if (context.mounted && searchCtr.text == query) {
            suggestions.value = results;
          }
        } catch (_) {
          // Keep typing or try again; nothing to show.
        }
      });
    }

    Future<void> pickSuggestion(PlaceSuggestion suggestion) async {
      searchFocus.unfocus();
      searchCtr.clear();
      suggestions.value = const [];
      try {
        final details = await ref
            .read(placesRepositoryProvider)
            .getPlaceDetails(suggestion.placeId);
        if (details == null || !context.mounted) return;
        final point = LatLng(details.lat, details.lng);
        // The place's own address is better than a lookup of its pin.
        lookupSeq.value++;
        resolvedAt.value = point;
        address.value = details.address ?? suggestion.description;
        resolving.value = false;
        userMoved.value = true;
        moveCamera(point);
      } catch (_) {
        AppService.showToast(l.placeOpenFailed, isError: true);
      }
    }

    Future<void> save() async {
      final street = address.value;
      if (street == null || saving.value) return;
      FocusScope.of(context).unfocus();
      saving.value = true;
      final pin = resolvedAt.value ?? target.value;
      final detail = detailCtr.text.trim();
      final result = await ref
          .read(addressesControllerProvider.notifier)
          .save(
            id: initial?.id,
            label: label.value,
            address: street,
            detail: detail.isEmpty ? null : detail,
            latitude: pin.latitude,
            longitude: pin.longitude,
          );
      if (!context.mounted) return;
      saving.value = false;
      if (!result.ok) {
        AppService.showToast(
          result.message ?? l.addressSaveFailed,
          isError: true,
        );
        return;
      }
      AppService.showToast(initial == null ? l.addressSaved : l.addressUpdated);
      Navigator.of(context).pop();
    }

    final photoUrl = ref.watch(currentUserProvider)?.profilePicture;
    final media = MediaQuery.of(context);
    final sheetHeight = _sheetHeight + media.viewPadding.bottom;
    final surface = Theme.of(context).colorScheme.surface;
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];

    Widget roundButton(IconData icon, String tooltip, VoidCallback onTap) =>
        Tooltip(
          message: tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                boxShadow: shadow,
              ),
              child: Icon(icon, size: 17, color: primary),
            ),
          ),
        );

    return Scaffold(
      // The sheet lifts above the keyboard by itself; the map stays put so
      // the pin doesn't shift (and trigger a lookup) when it opens.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: target.value,
              zoom: 16,
            ),
            onMapCreated: (c) => map.value = c,
            // Centers the camera in the space above the sheet, where the
            // pin is drawn.
            padding: EdgeInsets.only(bottom: sheetHeight),
            myLocationEnabled: here != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onCameraMoveStarted: () {
              userMoved.value = true;
              moving.value = true;
              searchFocus.unfocus();
            },
            onCameraMove: (camera) => target.value = camera.target,
            onCameraIdle: () {
              moving.value = false;
              onCameraIdle();
            },
          ),

          // ---- The pin: fixed over the camera's target
          Positioned.fill(
            bottom: sheetHeight,
            child: IgnorePointer(
              child: Center(
                child: _LivePin(photoUrl: photoUrl, moving: moving.value),
              ),
            ),
          ),

          // ---- Back + search, with results underneath
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      roundButton(
                        Icons.arrow_back_ios_new_rounded,
                        l.backAction,
                        () => Navigator.of(context).pop(),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: shadow,
                          ),
                          child: TextField(
                            controller: searchCtr,
                            focusNode: searchFocus,
                            onChanged: onSearchChanged,
                            // A touch anywhere else puts the keyboard away.
                            onTapOutside: (_) => searchFocus.unfocus(),
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: l.addressSearchHint,
                              hintStyle: TextStyle(fontSize: 15, color: muted),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: primary,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (suggestions.value.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 260),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: shadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: suggestions.value.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: ProfileTheme.hairlineColor(context),
                        ),
                        itemBuilder: (context, i) {
                          final s = suggestions.value[i];
                          return InkWell(
                            onTap: () => pickSuggestion(s),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 20,
                                    color: muted,
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: Text(
                                      s.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---- Recenter, just above the sheet
          if (here != null)
            Positioned(
              right: 12,
              bottom: sheetHeight + 16,
              child: roundButton(
                Icons.my_location_rounded,
                l.myLocation,
                () => moveCamera(here),
              ),
            ),

          // ---- The sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: media.viewInsets.bottom,
            height: sheetHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                media.viewPadding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    l.addressPinHint,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const Gap(2),
                  // Two lines' worth, so the rows below never jump.
                  SizedBox(
                    height: 38,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        address.value == null || resolving.value
                            ? l.findingAddress
                            : address.value!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: resolving.value ? muted : primary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: detailCtr,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      maxLength: 255,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l.addressDetailHint,
                        hintStyle: TextStyle(fontSize: 13.5, color: muted),
                        counterText: '',
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        border: _fieldBorder(muted.withValues(alpha: 0.35)),
                        enabledBorder: _fieldBorder(
                          muted.withValues(alpha: 0.35),
                        ),
                        focusedBorder: _fieldBorder(menuAccent),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      for (final option in AddressLabel.values) ...[
                        _LabelChip(
                          text: option.text(l),
                          selected: label.value == option,
                          onTap: () => label.value = option,
                        ),
                        const Gap(8),
                      ],
                    ],
                  ),
                  const Spacer(),
                  AddressGradientButton(
                    text: initial == null ? l.saveAddress : l.saveChanges,
                    loading: saving.value,
                    // Nothing to save until the pin has an address.
                    onTap: address.value == null || resolving.value
                        ? null
                        : save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pin, drawn like a live-location marker: the cat head with the
/// user's photo on a short stem, standing on a blue dot with a soft pulse
/// around it. The dot marks the exact spot. While the map is [moving] the
/// head lifts off the dot and the pulse rests; it drops back when the map
/// settles.
class _LivePin extends StatefulWidget {
  final String? photoUrl;
  final bool moving;
  const _LivePin({required this.photoUrl, required this.moving});

  @override
  State<_LivePin> createState() => _LivePinState();
}

class _LivePinState extends State<_LivePin>
    with SingleTickerProviderStateMixin {
  static const _headWidth = 36.0;
  static const _stem = 9.0;
  static const _dot = 12.0;
  static const _pulse = 56.0;
  static const _blue = Color(0xff3B9DFF);

  late final AnimationController _pulsing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void didUpdateWidget(_LivePin old) {
    super.didUpdateWidget(old);
    if (widget.moving == old.moving) return;
    widget.moving ? _pulsing.stop() : _pulsing.repeat();
  }

  @override
  void dispose() {
    _pulsing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _pulse,
      height: _pulse,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // The pulse: a ring that grows and fades, over and over.
          if (!widget.moving)
            AnimatedBuilder(
              animation: _pulsing,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_pulsing.value);
                return Container(
                  width: _pulse * (0.3 + 0.7 * t),
                  height: _pulse * (0.3 + 0.7 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: 0.28 * (1 - t)),
                  ),
                );
              },
            ),
          // The spot itself.
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blue,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
          ),
          // Head + stem, the stem's foot on the dot (or lifted off it).
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            bottom: _pulse / 2 + (widget.moving ? 10 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CatHeadAvatar(imageUrl: widget.photoUrl, width: _headWidth),
                Container(
                  width: 2.5,
                  height: _stem,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xff9B8CFF), _blue],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: color),
);

/// One address type: the selected one on the gradient, the rest outlined.
class _LabelChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _LabelChip({
    required this.text,
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
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          gradient: selected ? addressGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : ProfileTheme.textSecondary(context).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
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
