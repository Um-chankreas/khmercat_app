import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/core/components/buttons/app_text_button_gradient.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'package:khmer_cat_app/core/utils/size_responsive.dart';
import 'package:khmer_cat_app/src/restaurants/presentation/viewmodel/location_picker_viewmodel.dart';

class LocationPickResult {
  final LatLng location;
  final String? address;
  final String? name;
  final String? placeId;

  const LocationPickResult({
    required this.location,
    this.address,
    this.name,
    this.placeId,
  });
}

class LocationPickerScreen extends HookConsumerWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    this.initialLocation,
    this.initialAddress,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationPickerViewModelProvider);
    final searchCtr = useTextEditingController();
    final mapController = useState<GoogleMapController?>(null);

    useEffect(() {
      if (initialLocation != null) {
        Future.microtask(
          () => ref
              .read(locationPickerViewModelProvider.notifier)
              .setInitialLocation(initialLocation!, address: initialAddress),
        );
      }
      return null;
    }, []);

    void confirm() {
      Navigator.of(context).pop(
        LocationPickResult(
          location: state.selectedLocation,
          address: state.selectedAddress,
          name: state.selectedName,
          placeId: state.selectedPlaceId,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: state.selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (c) => mapController.value = c,
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: state.selectedLocation,
                draggable: true,
                onDragEnd: (pos) => ref
                    .read(locationPickerViewModelProvider.notifier)
                    .selectOnMap(pos),
              ),
            },
            onTap: (pos) => ref
                .read(locationPickerViewModelProvider.notifier)
                .selectOnMap(pos),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Search bar + suggestions overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: searchCtr,
                            decoration: const InputDecoration(
                              hintText: 'Search restaurant or place name',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onChanged: (v) => ref
                                .read(locationPickerViewModelProvider.notifier)
                                .search(v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.suggestions.length,
                        separatorBuilder: (_, ind) => Divider(
                          height: 1,
                          color: AppColors.lightGrey.withValues(alpha: 0.1),
                        ),
                        itemBuilder: (context, index) {
                          final s = state.suggestions[index];
                          return InkWell(
                            onTap: () async {
                              searchCtr.clear();
                              await ref
                                  .read(
                                    locationPickerViewModelProvider.notifier,
                                  )
                                  .selectSuggestion(s);
                              final loc = ref
                                  .read(locationPickerViewModelProvider)
                                  .selectedLocation;
                              mapController.value?.animateCamera(
                                CameraUpdate.newLatLng(loc),
                              );
                            },
                            child: Container(
                              padding: context.all(14),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined),
                                  Gap(context.sc(8)),
                                  Expanded(
                                    child: Text(
                                      s.description,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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

          // Confirm button + selected address preview
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.selectedAddress != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place, color: AppColors.appPrimaryPink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.selectedAddress!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppTextButtonGradient(
                    onTap: confirm,
                    text: 'Confirm location',
                    height: 45,
                    borderRadius: BorderRadius.circular(16),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
