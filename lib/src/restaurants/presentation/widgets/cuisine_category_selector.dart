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

/// One-of-six category picker. The backend takes a single `category_id`, so
/// this is single-select: tapping another chip moves the selection.
class CuisineCategorySelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool hasError;

  const CuisineCategorySelector({
    required this.selected,
    required this.onSelect,
    this.hasError = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cuisineOptions.map((label) {
        final isSelected = selected == label;
        final idle = hasError
            ? const Color(0xffE5484D)
            : ProfileTheme.deepPurple;
        return GestureDetector(
          onTap: () => onSelect(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isSelected ? ProfileTheme.pinkPurple : null,
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
                        color: ProfileTheme.purple.withValues(alpha: 0.25),
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
                  color: isSelected ? Colors.white : idle,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : idle,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
