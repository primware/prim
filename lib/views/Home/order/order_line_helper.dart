String orderLineDisplayName(Map<dynamic, dynamic> line) {
  String? referenceName(dynamic reference) {
    if (reference is! Map) return null;
    for (final key in const ['identifier', 'Name', 'name']) {
      final text = reference[key]?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  final productName = referenceName(line['M_Product_ID']);
  if (productName != null) {
    final separator = productName.indexOf('_');
    return separator >= 0 && separator < productName.length - 1
        ? productName.substring(separator + 1).trim()
        : productName;
  }

  final chargeName = referenceName(line['C_Charge_ID']);
  if (chargeName != null) return chargeName;

  final description = line['Description']?.toString().trim();
  if (description != null && description.isNotEmpty && description.toLowerCase() != 'null') return description;

  return 'Cargo';
}
