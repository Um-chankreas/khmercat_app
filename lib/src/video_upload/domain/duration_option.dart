// lib/features/video_upload/domain/duration_option.dart
class DurationOption {
  final String label;
  final int seconds;
  const DurationOption(this.label, this.seconds);
}

const durationOptions = [
  DurationOption('15s', 15),
  DurationOption('30s', 30),
  DurationOption('60s', 60),
];
