import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'toast_message.dart';

Future<Map<String, dynamic>?> pickValidFile({
  required BuildContext context,
  int maxUploadMB = 4,
  ImageSource source = ImageSource.gallery,
}) async {
  try {
    const allowedExtensions = ['jpg', 'jpeg', 'png'];

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source);
    if (picked == null) return null;

    final String fileName =
        (picked.name.isNotEmpty ? picked.name : picked.path.split('/').last)
            .toLowerCase();

    final String extension =
        fileName.contains('.') ? fileName.split('.').last : '';

    // Si la extensión existe y no está permitida, avisar.
    if (extension.isNotEmpty && !allowedExtensions.contains(extension)) {
      ToastMessage.show(
        context: context,
        message: 'Formato no permitido. Solo JPG, JPEG, PNG',
        type: ToastType.warning,
      );
      return null;
    }

    final Uint8List fileBytes = await picked.readAsBytes();
    final double mb = fileBytes.length / (1024 * 1024);

    if (mb > maxUploadMB) {
      ToastMessage.show(
        context: context,
        message: 'El tamaño máximo permitido es de $maxUploadMB MB',
        type: ToastType.warning,
      );
      return null;
    }

    return {
      'fileBytes': fileBytes,
      'fileName': fileName.isNotEmpty
          ? fileName
          : 'image.${extension.isEmpty ? 'png' : extension}',
      'fileSize': '${mb.toStringAsFixed(2)} MB',
    };
  } catch (e) {
    ToastMessage.show(
      context: context,
      message: 'No se pudo seleccionar la imagen ($e)',
      type: ToastType.failure,
    );
    return null;
  }
}
