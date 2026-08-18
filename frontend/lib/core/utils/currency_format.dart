import 'package:intl/intl.dart';

final _rwf = NumberFormat('#,###', 'en_US');

/// Formats an integer RWF amount as `RWF 45,000` or `45,000 RWF`.
String formatRwf(int amount, {bool suffix = false}) {
  final n = _rwf.format(amount);
  return suffix ? '$n RWF' : 'RWF $n';
}
