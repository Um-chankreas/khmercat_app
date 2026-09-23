import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import '../domain/duration_option.dart';
import 'video_upload_screen.dart';

class CameraRecordScreen extends HookWidget {
  const CameraRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ---------------- State Hooks ----------------
    final controller = useState<CameraController?>(null);
    final cameras = useState<List<CameraDescription>>([]);
    final cameraIndex = useState<int>(0);
    final selectedDuration = useState<DurationOption>(durationOptions[1]);
    final isRecording = useState<bool>(false);
    final elapsedSeconds = useState<int>(0);
    final isInitializing = useState<bool>(true);
    final flashMode = useState<FlashMode>(FlashMode.off);

    // Operational Refs
    final isProcessing = useRef<bool>(false);
    final timerRef = useRef<Timer?>(null);

    // ---------------- Camera Controller Init ----------------
    Future<void> initController(
      CameraDescription description,
      FlashMode currentFlashMode,
    ) async {
      isInitializing.value = true;

      final oldController = controller.value;
      controller.value = null;
      await oldController?.dispose();

      final newController = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: true,
      );

      try {
        await newController.initialize();

        if (description.lensDirection == CameraLensDirection.back) {
          await newController.setFlashMode(currentFlashMode);
        } else {
          flashMode.value = FlashMode.off;
        }

        controller.value = newController;
      } catch (e) {
        debugPrint('Error initializing camera controller: $e');
      } finally {
        isInitializing.value = false;
      }
    }

    // ---------------- Setup & Cleanup Hook ----------------
    useEffect(() {
      Future<void> setup() async {
        try {
          final available = await availableCameras();
          cameras.value = available;
          if (available.isNotEmpty) {
            await initController(available[0], flashMode.value);
          } else {
            isInitializing.value = false;
          }
        } catch (e) {
          debugPrint('Error loading available cameras: $e');
          isInitializing.value = false;
        }
      }

      setup();

      return () {
        timerRef.value?.cancel();
        controller.value?.dispose();
      };
    }, const []);

    // ---------------- Lifecycle State Observer Hook ----------------
    useOnAppLifecycleStateChange((previousState, currentState) {
      final cam = controller.value;
      if (cam == null || !cam.value.isInitialized) return;

      if (currentState == AppLifecycleState.inactive) {
        cam.dispose();
      } else if (currentState == AppLifecycleState.resumed &&
          cameras.value.isNotEmpty) {
        initController(cameras.value[cameraIndex.value], flashMode.value);
      }
    });

    // ---------------- Navigation Action ----------------
    void goToUpload(File file) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoUploadScreen(
            key: ValueKey(file.path),
            initialVideoFile: file,
          ),
        ),
      );
    }

    // ---------------- Camera Handlers ----------------
    Future<void> stopRecording() async {
      final cam = controller.value;
      if (cam == null ||
          !isRecording.value ||
          !cam.value.isRecordingVideo ||
          isProcessing.value) {
        return;
      }

      isProcessing.value = true;
      timerRef.value?.cancel();

      try {
        if (elapsedSeconds.value < 1) {
          await Future.delayed(const Duration(milliseconds: 800));
        }

        final file = await cam.stopVideoRecording();
        isRecording.value = false;
        goToUpload(File(file.path));
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
        isRecording.value = false;
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> startRecording() async {
      final cam = controller.value;
      if (cam == null ||
          !cam.value.isInitialized ||
          isRecording.value ||
          isProcessing.value) {
        return;
      }

      isProcessing.value = true;

      try {
        await cam.startVideoRecording();
        isRecording.value = true;
        elapsedSeconds.value = 0;

        timerRef.value?.cancel();
        timerRef.value = Timer.periodic(const Duration(seconds: 1), (t) {
          elapsedSeconds.value++;
          if (elapsedSeconds.value >= selectedDuration.value.seconds) {
            stopRecording();
          }
        });
      } catch (e) {
        debugPrint('Error starting video recording: $e');
        isRecording.value = false;
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> toggleFlash() async {
      final cam = controller.value;
      if (cam == null ||
          !cam.value.isInitialized ||
          cameras.value[cameraIndex.value].lensDirection ==
              CameraLensDirection.front) {
        return;
      }

      final nextMode = flashMode.value == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await cam.setFlashMode(nextMode);
      flashMode.value = nextMode;
    }

    Future<void> flipCamera() async {
      if (cameras.value.length < 2 || isRecording.value || isProcessing.value) {
        return;
      }
      isProcessing.value = true;
      cameraIndex.value = (cameraIndex.value + 1) % cameras.value.length;
      await initController(cameras.value[cameraIndex.value], flashMode.value);
      isProcessing.value = false;
    }

    Future<void> pickFromGallery() async {
      if (isRecording.value || isProcessing.value) return;
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) goToUpload(File(picked.path));
    }

    // ---------------- Loading View ----------------
    if (isInitializing.value ||
        controller.value == null ||
        !controller.value!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isBackCamera =
        cameras.value[cameraIndex.value].lensDirection ==
        CameraLensDirection.back;
    final progress = elapsedSeconds.value / selectedDuration.value.seconds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // True Fullscreen Edge-to-Edge Camera Preview
          ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value!.value.previewSize!.height,
                  height: controller.value!.value.previewSize!.width,
                  child: CameraPreview(controller.value!),
                ),
              ),
            ),
          ),

          // Top Action Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              showFlash: isBackCamera,
              isFlashOn: flashMode.value == FlashMode.torch,
              isRecording: isRecording.value,
              onCloseTap: () => Navigator.of(context).pop(),
              onFlashTap: toggleFlash,
              onFlipTap: flipCamera,
            ),
          ),

          // Bottom Controls Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRecording.value)
                      _DurationSelector(
                        selectedDuration: selectedDuration.value,
                        onDurationSelected: (option) =>
                            selectedDuration.value = option,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          '${elapsedSeconds.value}s / ${selectedDuration.value.seconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          child: isRecording.value
                              ? null
                              : _GalleryButton(onTap: pickFromGallery),
                        ),
                        const SizedBox(width: 40),
                        _RecordButton(
                          isRecording: isRecording.value,
                          progress: progress,
                          onTap: isRecording.value
                              ? stopRecording
                              : startRecording,
                        ),
                        const SizedBox(width: 40),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- UI Modular Helper Components ----------------

class _TopBar extends StatelessWidget {
  final bool showFlash;
  final bool isFlashOn;
  final bool isRecording;
  final VoidCallback onCloseTap;
  final VoidCallback onFlashTap;
  final VoidCallback onFlipTap;

  const _TopBar({
    required this.showFlash,
    required this.isFlashOn,
    required this.isRecording,
    required this.onCloseTap,
    required this.onFlashTap,
    required this.onFlipTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundIconButton(icon: Icons.close, onTap: onCloseTap),
            Row(
              children: [
                if (showFlash)
                  _RoundIconButton(
                    icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: isRecording ? null : onFlashTap,
                  ),
                if (showFlash) const SizedBox(width: 12),
                _RoundIconButton(
                  icon: Icons.flip_camera_ios,
                  onTap: isRecording ? null : onFlipTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final DurationOption selectedDuration;
  final ValueChanged<DurationOption> onDurationSelected;

  const _DurationSelector({
    required this.selectedDuration,
    required this.onDurationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: durationOptions.map((option) {
          final isSelected = option.seconds == selectedDuration.seconds;
          return GestureDetector(
            onTap: () => onDurationSelected(option),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final double progress;
  final VoidCallback onTap;

  const _RecordButton({
    required this.isRecording,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRecording)
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(AppColors.appPrimaryPink),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isRecording ? 34 : 64,
              height: isRecording ? 34 : 64,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(isRecording ? 8 : 32),
                border: isRecording
                    ? null
                    : Border.all(color: Colors.white, width: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GalleryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white24,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
