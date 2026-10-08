import 'package:intl/intl.dart';

final _amountFormat = NumberFormat('#,##0.00', 'en_US');

/// Formats displayed amounts with comma grouping and two decimal places.
String formatAmount(num? value) => _amountFormat.format(value ?? 0);
