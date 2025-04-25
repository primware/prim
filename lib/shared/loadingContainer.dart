import 'package:flutter/material.dart';
import 'package:primware/theme/colors.dart';

class LoadingContainer extends StatelessWidget {
  const LoadingContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: CircularProgressIndicator(
          color: ColorTheme.accentLight,
        ),
      ),
    );
  }
}
