// lib/features/restaurant/presentation/widgets/cuisine_category_selector.dart
import 'package:flutter/material.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';

/// Category name -> backend `restaurant_categories.id`. There's no
/// GET /categories endpoint yet, but RestaurantCategorySeeder inserts
/// exactly these six, in this exact order, on a fresh database — so the
/// seeded auto-increment ids line up 1:1 with this list. Swap this for a
/// real lookup the moment a categories endpoint exists.
const Map<String, String> cuisineCategoryIds = {
  'Beverage': '1',
  'Khmer Food': '2',
  'Fast Food': '3',
  'Hotpot & BBQ': '4',
  'Asian': '5',
  'Western': '6',
};

final cuisineOptions = cuisineCategoryIds.keys.toList();

/// Icon shown on each cuisine chip.
const Map<String, IconData> cuisineIcons = {
  'Beverage': Icons.local_cafe_rounded,
  'Khmer Food': Icons.rice_bowl_rounded,
  'Fast Food': Icons.fastfood_rounded,
  'Hotpot & BBQ': Icons.outdoor_grill_rounded,
  'Asian': Icons.ramen_dining_rounded,
  'Western': Icons.dinner_dining_rounded,
};

const _halalGreen = Color(0xff16A34A);

/// One-of-six category picker. The backend takes a single `category_id`, so
/// the cuisines are single-select: tapping another chip moves the selection.
///
/// With [onHalalChanged], a green Halal chip follows them; it toggles on its
/// own, alongside whichever cuisine is picked (the restaurant's `is_halal`).
class CuisineCategorySelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool hasError;
  final bool halal;
  final ValueChanged<bool>? onHalalChanged;

  const CuisineCategorySelector({
    required this.selected,
    required this.onSelect,
    this.hasError = false,
    this.halal = false,
    this.onHalalChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._cuisineChips(),
        if (onHalalChanged case final onChanged?)
          HalalChip(selected: halal, onTap: () => onChanged(!halal)),
      ],
    );
  }

  List<Widget> _cuisineChips() {
    return cuisineOptions.map((label) {
      final isSelected = selected == label;
      final idle = hasError ? const Color(0xffE5484D) : ProfileTheme.deepPurple;
      return GestureDetector(
        onTap: () => onSelect(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected ? ProfileTheme.brandGradient : null,
            color: isSelected ? null : idle.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : idle.withValues(alpha: hasError ? 0.5 : 0.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ProfileTheme.brandBlue.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_rounded : cuisineIcons[label],
                size: 17,
                color: isSelected ? ProfileTheme.ink : idle,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? ProfileTheme.ink : idle,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// The green Halal toggle chip, next to the cuisine chips.
class HalalChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const HalalChip({required this.selected, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _halalGreen : _halalGreen.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : _halalGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.verified_rounded,
              size: 17,
              color: selected ? Colors.white : _halalGreen,
            ),
            const SizedBox(width: 7),
            Text(
              'Halal',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _halalGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
