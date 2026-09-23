enum UploadStage { idle, picking, compressing, uploading, success, error }

class VideoUploadState {
  final UploadStage stage;
  final String? originalPath;
  final int? originalSizeBytes;
  final String? compressedPath;
  final int? compressedSizeBytes;
  final double compressionProgress; // 0.0 - 1.0
  final double uploadProgress; // 0.0 - 1.0
  final Duration? compressionDuration; // for perf testing
  final String? uploadedVideoId;
  final String? uploadedVideoStatus; // "processing" — never polled, see spec
  final String? errorMessage;

  const VideoUploadState({
    this.stage = UploadStage.idle,
    this.originalPath,
    this.originalSizeBytes,
    this.compressedPath,
    this.compressedSizeBytes,
    this.compressionProgress = 0,
    this.uploadProgress = 0,
    this.compressionDuration,
    this.uploadedVideoId,
    this.uploadedVideoStatus,
    this.errorMessage,
  });

  double? get compressionRatio {
    if (originalSizeBytes == null ||
        compressedSizeBytes == null ||
        originalSizeBytes == 0) {
      return null;
    }
    return 1 - (compressedSizeBytes! / originalSizeBytes!);
  }

  VideoUploadState copyWith({
    UploadStage? stage,
    String? originalPath,
    int? originalSizeBytes,
    String? compressedPath,
    int? compressedSizeBytes,
    double? compressionProgress,
    double? uploadProgress,
    Duration? compressionDuration,
    String? uploadedVideoId,
    String? uploadedVideoStatus,
    String? errorMessage,
  }) {
    return VideoUploadState(
      stage: stage ?? this.stage,
      originalPath: originalPath ?? this.originalPath,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      compressedPath: compressedPath ?? this.compressedPath,
      compressedSizeBytes: compressedSizeBytes ?? this.compressedSizeBytes,
      compressionProgress: compressionProgress ?? this.compressionProgress,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      compressionDuration: compressionDuration ?? this.compressionDuration,
      uploadedVideoId: uploadedVideoId ?? this.uploadedVideoId,
      uploadedVideoStatus: uploadedVideoStatus ?? this.uploadedVideoStatus,
      errorMessage: errorMessage,
    );
  }
}
