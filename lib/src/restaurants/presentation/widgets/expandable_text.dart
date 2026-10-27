import 'package:flutter/material.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';

/// Text clamped to [maxLines] with an inline "… more" that expands it.
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const ExpandableText({required this.text, required this.style, super.key});

  static const maxLines = 3;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final more = widget.style.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xffB0125A),
    );
    final moreText = '… ${AppLocalizations.of(context).textMore}';
    return LayoutBuilder(
      builder: (context, c) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        TextPainter layout(String t, {bool withMore = false}) => TextPainter(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: t),
              if (withMore) TextSpan(text: moreText, style: more),
            ],
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: ExpandableText.maxLines,
        )..layout(maxWidth: c.maxWidth);

        if (_expanded || !layout(widget.text).didExceedMaxLines) {
          return Text(widget.text, style: widget.style);
        }
        // Longest prefix that still fits, with "… more", in maxLines.
        var lo = 0, hi = widget.text.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          final fits = !layout(
            widget.text.substring(0, mid).trimRight(),
            withMore: true,
          ).didExceedMaxLines;
          if (fits) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }
        return GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text.rich(
            TextSpan(
              style: widget.style,
              children: [
                TextSpan(text: widget.text.substring(0, lo).trimRight()),
                TextSpan(text: moreText, style: more),
              ],
            ),
          ),
        );
      },
    );
  }
}
