import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:primware/theme/fonts.dart';
import '../theme/colors.dart';
import 'button_dialog.dart';

class WebCameraDialog extends StatefulWidget {
  final Function(XFile) onImageCaptured;

  const WebCameraDialog({super.key, required this.onImageCaptured});

  @override
  State<WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<WebCameraDialog> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras!.first, ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTheme.textDark,
      content: isLoading
          ? Text(
              'Cargando camara',
              style: FontsTheme.p(),
            )
          : AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
      actions: [
        BotonDialog(
          text: 'Tomar Foto',
          bgcolor: ColorTheme.success,
          onPressed: () async {
            if (_controller != null && _controller!.value.isInitialized) {
              final image = await _controller!.takePicture();
              widget.onImageCaptured(image);
              Navigator.pop(context);
            }
          },
        ),
        BotonDialog(
          text: 'Cancelar',
          bgcolor: ColorTheme.error,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
