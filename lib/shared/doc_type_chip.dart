import 'package:flutter/material.dart';

class DocTypeChip extends StatelessWidget {
  final String? docTypeName;
  final bool isReturn;

  const DocTypeChip({
    super.key,
    required this.docTypeName,
    this.isReturn = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = docTypeName ?? 'Documento';
    
    // Function to generate a consistent color based on string hash
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Predefined colors for common doc types
    Color baseColor;
    if (isReturn) {
      baseColor = Colors.red;
    } else if (name.toLowerCase().contains('proposal') || name.toLowerCase().contains('cotizaci')) {
      baseColor = Colors.blue;
    } else if (name.toLowerCase().contains('prepay')) {
      baseColor = Colors.teal;
    } else if (name.toLowerCase().contains('standard')) {
      baseColor = Colors.purple;
    } else if (name.toLowerCase().contains('pos')) {
      baseColor = Colors.orange;
    } else {
      // Generate color from hash for unknown document types
      final h = (hash % 360).abs().toDouble();
      baseColor = HSLColor.fromAHSL(1.0, h, 0.7, 0.45).toColor();
    }

    final Color bgColor = baseColor.withOpacity(0.12);
    final IconData icon = isReturn ? Icons.undo : Icons.description_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(fontSize: 12, color: baseColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
