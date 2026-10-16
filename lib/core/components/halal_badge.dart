import 'package:flutter/material.dart';

const _green = Color(0xff16A34A);

/// Small green "Halal" tag for restaurant cards. [onImage] gives it a solid
/// fill so it reads over a photo.
class HalalBadge extends StatelessWidget {
  final bool onImage;
  const HalalBadge({this.onImage = false, super.key});

  @override
  Widget build(BuildContext context) {
    final fg = onImage ? Colors.white : _green;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
      decoration: BoxDecoration(
        color: onImage ? _green : _green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            'Halal',
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// [name] with a [HalalBadge] right after it when [isHalal]; the name gives
/// way (ellipsis) before the badge does.
class NameWithHalalBadge extends StatelessWidget {
  final Widget name;
  final bool isHalal;
  const NameWithHalalBadge({
    required this.name,
    required this.isHalal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHalal) return name;
    return Row(
      children: [
        Flexible(child: name),
        const SizedBox(width: 6),
        const HalalBadge(),
      ],
    );
  }
}
