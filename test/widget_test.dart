import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_cat_app/src/feed/domain/video_feed_item.dart';

void main() {
  group('formatCount', () {
    test('leaves small counts as-is', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
    });

    test('abbreviates thousands', () {
      expect(formatCount(1000), '1.0k');
      expect(formatCount(4210), '4.2k');
    });

    test('abbreviates millions', () {
      expect(formatCount(1500000), '1.5M');
    });
  });
}
