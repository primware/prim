import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../theme/colors.dart';

enum SnackType { success, failure, warning, help }

class SnackMessage {
  static void show({
    required BuildContext context,
    required String message,
    required SnackType type,
  }) {
    showTopSnackBar(
      Overlay.of(context),
      _buildCustomSnackBar(context, message, type),
    );
  }

  static CustomSnackBar _buildCustomSnackBar(
      BuildContext context, String message, SnackType type) {
    switch (type) {
      case SnackType.success:
        return CustomSnackBar.success(
          message: message,
          backgroundColor: ColorTheme.success,
          textStyle: Theme.of(context).textTheme.bodySmall!,
          icon: const Icon(Icons.check_circle_outline,
              color: Color(0x15000000), size: 120),
        );
      case SnackType.failure:
        return CustomSnackBar.error(
          message: message,
          backgroundColor: ColorTheme.error,
          textStyle: Theme.of(context).textTheme.bodyMedium!,
          icon: const Icon(Icons.error_outline,
              color: Color(0x15000000), size: 120),
        );
      case SnackType.warning:
        return CustomSnackBar.info(
          message: message,
          backgroundColor: ColorTheme.atention,
          icon: const Icon(Icons.error_outline,
              color: Color(0x15000000), size: 120),
          textStyle: Theme.of(context).textTheme.bodyMedium!,
        );
      case SnackType.help:
        return CustomSnackBar.info(
          message: message,
          backgroundColor: ColorTheme.info,
          textStyle: Theme.of(context).textTheme.bodyMedium!,
          icon: const Icon(Icons.info_outline,
              color: Color(0x15000000), size: 120),
        );
    }
  }
}
