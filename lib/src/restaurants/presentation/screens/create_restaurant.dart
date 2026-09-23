// lib/features/restaurant/presentation/screens/create_restaurant_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/gradient/gradient_text.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/extensions/safe_area_extension.dart';
import 'package:khmer_cat_app/core/go_router/app_route.dart';
import 'package:khmer_cat_app/core/go_router/app_router.dart';
import 'package:khmer_cat_app/core/location/location_provider.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/place_details.dart';
import 'package:khmer_cat_app/src/restaurants/domain/entities/place_suggestion.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/screens/location_picker_screen.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/create_restaurant_viewmodel.dart';
import 'package:khmer_cat_app/src/restaurants/providers/places_providers.dart';
import '../widgets/cuisine_category_selector.dart';
import '../widgets/logo_upload_picker.dart';

const _nameMax = 60;
const _descriptionMax = 300;
const _red = Color(0xffE5484D);
const _green = Color(0xff22A45D);

class CreateRestaurant extends HookConsumerWidget {
  const CreateRestaurant({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlaceId = useState<String?>(null);
    final nameCtr = useTextEditingController();
    final addressCtr = useTextEditingController();
    final descriptionCtr = useTextEditingController();
    useListenable(nameCtr);
    useListenable(descriptionCtr);
    final logoImage = useState<File?>(null);
    final selectedCategory = useState<String?>(null);
    // Errors only appear after the first attempt to submit.
    final submitted = useState(false);
    final locating = useState(false);
    final mapController = useState<GoogleMapController?>(null);
    final pinLocation = useState(
      const LatLng(11.5564, 104.9282),
    ); // Phnom Penh default

    final createState = ref.watch(createRestaurantViewModelProvider);
    final progress = ref.watch(createRestaurantProgressProvider);
    final isCreating = createState.isLoading;

    // Keep the map preview centred on the pin when it moves.
    useEffect(() {
      mapController.value?.animateCamera(
        CameraUpdate.newLatLng(pinLocation.value),
      );
      return null;
    }, [pinLocation.value]);

    ref.listen(createRestaurantViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) {
          AppService.showToast(
            err is ApiException ? err.message : 'Something went wrong.',
            isError: true,
          );
        },
        data: (created) {
          if (created != null) {
            AppService.showToast('Restaurant created!');
            AppRouter.router.pushReplacementNamed(AppRoute.index.name);
          }
        },
      );
    });

    Future<void> openLocationPicker() async {
      final result = await Navigator.of(context).push<LocationPickResult>(
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLocation: pinLocation.value,
            initialAddress: addressCtr.text.isNotEmpty ? addressCtr.text : null,
          ),
        ),
      );

      if (result != null) {
        pinLocation.value = result.location;
        if (result.address != null) addressCtr.text = result.address!;
        if (result.name != null && nameCtr.text.isEmpty) {
          nameCtr.text = result.name!;
        }
        selectedPlaceId.value = result.placeId;
      }
    }

    Future<void> useMyLocation() async {
      locating.value = true;
      await ref.read(locationProvider.notifier).enable();
      final position = ref.read(locationProvider);
      locating.value = false;
      if (position == null) {
        AppService.showToast('Couldn\'t get your location.', isError: true);
        return;
      }
      pinLocation.value = LatLng(position.latitude, position.longitude);
      // The pin is no longer tied to a searched place.
      selectedPlaceId.value = null;
    }

    void onPlaceSelected(PlaceDetails d) {
      pinLocation.value = LatLng(d.lat, d.lng);
      selectedPlaceId.value = d.placeId;
      if (nameCtr.text.isEmpty && d.name != null) nameCtr.text = d.name!;
    }

    final nameMissing = nameCtr.text.trim().isEmpty;
    final logoMissing = logoImage.value == null;
    final categoryMissing = selectedCategory.value == null;
    final doneCount = [
      !logoMissing,
      !nameMissing,
      !categoryMissing,
    ].where((d) => d).length;

    void handleCreate() {
      submitted.value = true;
      if (nameMissing) {
        AppService.showToast('Please enter a restaurant name.', isError: true);
        return;
      }
      if (logoMissing) {
        AppService.showToast('Please add a restaurant logo.', isError: true);
        return;
      }
      if (categoryMissing) {
        AppService.showToast('Please pick a cuisine category.', isError: true);
        return;
      }
      AppService.dismissKeyboard(context);

      ref
          .read(createRestaurantViewModelProvider.notifier)
          .create(
            name: nameCtr.text.trim(),
            categoryId: cuisineCategoryIds[selectedCategory.value]!,
            profilePicture: logoImage.value!,
            description: descriptionCtr.text.trim(),
            address: addressCtr.text.trim(),
            latitude: pinLocation.value.latitude,
            longitude: pinLocation.value.longitude,
          );
    }

    return GestureDetector(
      onTap: () => AppService.dismissKeyboard(context),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header
                Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const Gap(12),
                    ],
                    Expanded(
                      child: GradientText(
                        'Create Your Restaurant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                const Text(
                  'Set up your restaurant profile to start reaching more customers.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: ProfileTheme.muted,
                  ),
                ),
                const Gap(16),
                _ProgressCard(done: doneCount, total: 3),
                const Gap(16),

                // ---- 1. Basics
                _FormSection(
                  step: 1,
                  title: 'Basics',
                  subtitle: 'Your logo, name and cuisine',
                  children: [
                    const _FieldLabel('Logo', required: true),
                    const Gap(8),
                    LogoUploadPicker(
                      image: logoImage.value,
                      hasError: submitted.value && logoMissing,
                      uploadProgress: isCreating ? progress : null,
                      onImagePicked: (file) => logoImage.value = file,
                      onRemove: () => logoImage.value = null,
                    ),
                    const _HelpText(
                      'Shown on your page, in search and next to your videos.',
                    ),
                    const Gap(20),
                    const _FieldLabel('Restaurant name', required: true),
                    const Gap(8),
                    _InputField(
                      controller: nameCtr,
                      hint: 'e.g. Angkor Bites Cafe',
                      icon: Icons.storefront_rounded,
                      maxLength: _nameMax,
                      errorText: submitted.value && nameMissing
                          ? 'Please enter a restaurant name'
                          : null,
                    ),
                    _CounterRow(
                      helper: 'The name customers will search for.',
                      count: nameCtr.text.length,
                      max: _nameMax,
                    ),
                    const Gap(20),
                    const _FieldLabel('Cuisine category', required: true),
                    const Gap(8),
                    CuisineCategorySelector(
                      selected: selectedCategory.value,
                      hasError: submitted.value && categoryMissing,
                      onSelect: (label) => selectedCategory.value = label,
                    ),
                    if (submitted.value && categoryMissing)
                      const _ErrorText('Pick the cuisine that fits best')
                    else
                      const _HelpText('Choose the one that fits best.'),
                  ],
                ),
                const Gap(14),

                // ---- 2. Location
                _FormSection(
                  step: 2,
                  title: 'Location',
                  subtitle: 'Help customers find you',
                  children: [
                    const _FieldLabel('Address', optional: true),
                    const Gap(8),
                    _AddressField(
                      controller: addressCtr,
                      verified: selectedPlaceId.value != null,
                      onPlaceSelected: onPlaceSelected,
                      onEdited: () => selectedPlaceId.value = null,
                    ),
                    const Gap(20),
                    const _FieldLabel('Pin location', optional: true),
                    const Gap(8),
                    _MapPreview(
                      location: pinLocation.value,
                      locating: locating.value,
                      onMapCreated: (c) => mapController.value = c,
                      onOpenPicker: openLocationPicker,
                      onUseMyLocation: useMyLocation,
                    ),
                    const _HelpText(
                      'Tap the map to drop the pin precisely, or use your current location.',
                    ),
                  ],
                ),
                const Gap(14),

                // ---- 3. About
                _FormSection(
                  step: 3,
                  title: 'About',
                  subtitle: 'Tell your story',
                  children: [
                    const _FieldLabel('Description', optional: true),
                    const Gap(8),
                    _InputField(
                      controller: descriptionCtr,
                      hint:
                          'Tell customers about your restaurant, specialties, and dining experience.',
                      icon: Icons.notes_rounded,
                      maxLines: 5,
                      minLines: 4,
                      maxLength: _descriptionMax,
                    ),
                    _CounterRow(
                      helper: 'A few sentences work best.',
                      count: descriptionCtr.text.length,
                      max: _descriptionMax,
                    ),
                  ],
                ),
                const Gap(22),

                _CreateButton(
                  loading: isCreating,
                  progress: progress,
                  onTap: isCreating ? null : handleCreate,
                ),
                Gap(context.safeBottomPadding()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Form chrome
// =============================================================================

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTheme.purple.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: ProfileTheme.deepPurple,
          ),
        ),
      ),
    );
  }
}

/// "n of 3 required details done" with a gradient progress bar.
class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final complete = done == total;
    return ProfileCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.playlist_add_check_rounded,
                size: 20,
                color: complete ? _green : ProfileTheme.purple,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  complete
                      ? 'All required details added'
                      : '$done of $total required details added',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(done / total * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ProfileTheme.deepPurple,
                ),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  color: ProfileTheme.purple.withValues(alpha: 0.10),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  widthFactor: done / total,
                  child: Container(
                    height: 7,
                    decoration: const BoxDecoration(
                      gradient: ProfileTheme.gradient,
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

/// A numbered card grouping related fields.
class _FormSection extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _FormSection({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: ProfileTheme.pinkPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: ProfileTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Step $step of 3',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: ProfileTheme.muted,
                ),
              ),
            ],
          ),
          const Gap(16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  final bool optional;
  const _FieldLabel(this.text, {this.required = false, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _red,
            ),
          ),
        if (optional)
          const Text(
            '  Optional',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ProfileTheme.muted,
            ),
          ),
      ],
    );
  }
}

class _HelpText extends StatelessWidget {
  final String text;
  const _HelpText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: ProfileTheme.muted,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _red),
          const Gap(4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _red,
            ),
          ),
        ],
      ),
    );
  }
}

/// Help text on the left, "n/max" on the right (turns red near the limit).
class _CounterRow extends StatelessWidget {
  final String helper;
  final int count;
  final int max;
  const _CounterRow({
    required this.helper,
    required this.count,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final nearLimit = count >= max * 0.9;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              helper,
              style: const TextStyle(fontSize: 12, color: ProfileTheme.muted),
            ),
          ),
          Text(
            '$count/$max',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: nearLimit ? _red : ProfileTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text field with a leading icon, tinted fill, gradient-purple focus ring
/// and a red error state. The character counter is drawn by [_CounterRow].
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final String? errorText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.errorText,
    this.suffix,
    this.onChanged,
  });

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ProfileTheme.muted.withValues(alpha: 0.65),
        ),
        counterText: '',
        errorText: errorText,
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _red,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: maxLines > 1 ? 14 : 0,
          ),
          child: Align(
            alignment: maxLines > 1 ? Alignment.topCenter : Alignment.center,
            widthFactor: 1,
            heightFactor: maxLines > 1 ? 1 : null,
            child: Icon(icon, size: 20, color: ProfileTheme.purple),
          ),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: ProfileTheme.purple.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _border(ProfileTheme.purple.withValues(alpha: 0.18)),
        enabledBorder: _border(ProfileTheme.purple.withValues(alpha: 0.18)),
        focusedBorder: _border(ProfileTheme.purple, 1.6),
        errorBorder: _border(_red.withValues(alpha: 0.7), 1.3),
        focusedErrorBorder: _border(_red, 1.6),
      ),
    );
  }
}

// =============================================================================
// Address with auto-suggest
// =============================================================================

class _AddressField extends HookConsumerWidget {
  final TextEditingController controller;
  final bool verified;
  final ValueChanged<PlaceDetails> onPlaceSelected;
  final VoidCallback onEdited;

  const _AddressField({
    required this.controller,
    required this.verified,
    required this.onPlaceSelected,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(controller);
    final suggestions = useState<List<PlaceSuggestion>>([]);
    final searching = useState(false);
    final debounce = useRef<Timer?>(null);
    useEffect(
      () =>
          () => debounce.value?.cancel(),
      const [],
    );

    void onChanged(String value) {
      onEdited();
      debounce.value?.cancel();
      if (value.trim().length < 3) {
        suggestions.value = [];
        searching.value = false;
        return;
      }
      searching.value = true;
      debounce.value = Timer(const Duration(milliseconds: 400), () async {
        try {
          final results = await ref
              .read(placesRepositoryProvider)
              .autocomplete(value.trim());
          if (!context.mounted) return;
          suggestions.value = results.take(4).toList();
        } catch (_) {
          // Keep typing — suggestions are a convenience, not required.
        } finally {
          if (context.mounted) searching.value = false;
        }
      });
    }

    Future<void> pick(PlaceSuggestion s) async {
      suggestions.value = [];
      AppService.dismissKeyboard(context);
      final details = await ref
          .read(placesRepositoryProvider)
          .getPlaceDetails(s.placeId);
      if (details == null || !context.mounted) return;
      controller.text = details.address ?? s.description;
      onPlaceSelected(details);
    }

    final hasText = controller.text.trim().isNotEmpty;
    final Widget? suffix = searching.value
        ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: ProfileTheme.purple,
              ),
            ),
          )
        : verified
        ? const Icon(Icons.check_circle_rounded, color: _green)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          controller: controller,
          hint: 'Search or type your address',
          icon: Icons.location_on_rounded,
          maxLines: 2,
          suffix: suffix,
          onChanged: onChanged,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: suggestions.value.isEmpty
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ProfileTheme.hairline),
                    boxShadow: ProfileTheme.cardShadow(),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final s in suggestions.value)
                        InkWell(
                          onTap: () => pick(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: ProfileTheme.pink,
                                ),
                                const Gap(10),
                                Expanded(
                                  child: Text(
                                    s.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        // Validation indicator
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : hasText
                    ? Icons.info_outline_rounded
                    : Icons.tips_and_updates_outlined,
                size: 14,
                color: verified ? _green : ProfileTheme.muted,
              ),
              const Gap(5),
              Expanded(
                child: Text(
                  verified
                      ? 'Address verified from a real place'
                      : hasText
                      ? 'Pick a suggestion to verify this address'
                      : 'Start typing to see suggestions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: verified ? FontWeight.w700 : FontWeight.w500,
                    color: verified ? _green : ProfileTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Map preview
// =============================================================================

class _MapPreview extends StatelessWidget {
  final LatLng location;
  final bool locating;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onOpenPicker;
  final VoidCallback onUseMyLocation;

  const _MapPreview({
    required this.location,
    required this.locating,
    required this.onMapCreated,
    required this.onOpenPicker,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProfileTheme.purple.withValues(alpha: 0.25)),
        boxShadow: ProfileTheme.cardShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          IgnorePointer(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: location, zoom: 14),
              onMapCreated: onMapCreated,
              markers: {
                Marker(
                  markerId: const MarkerId('preview'),
                  position: location,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRose,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          // Tapping anywhere on the map opens the full-screen picker.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenPicker,
                splashColor: ProfileTheme.purple.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Hint chip
          Positioned(
            left: 10,
            bottom: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ProfileTheme.cardShadow(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: ProfileTheme.deepPurple,
                    ),
                    Gap(6),
                    Text(
                      'Tap map to place pin',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ProfileTheme.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Current-location button
          Positioned(
            right: 10,
            bottom: 10,
            child: GestureDetector(
              onTap: locating ? null : onUseMyLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: ProfileTheme.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ProfileTheme.purple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: locating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Create button
// =============================================================================

/// Gradient button; while creating it shows a spinner, "Creating… n%" and a
/// progress bar along its bottom edge.
class _CreateButton extends StatelessWidget {
  final bool loading;
  final double progress;
  final VoidCallback? onTap;
  const _CreateButton({
    required this.loading,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: loading ? 0.92 : 1,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: ProfileTheme.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: ProfileTheme.purple.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.rocket_launch_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  const Gap(10),
                  Text(
                    loading
                        ? 'Creating… ${(progress * 100).round()}%'
                        : 'Create restaurant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (loading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 3.5,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
