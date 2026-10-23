import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatMoney(num v) => _money.format(v);
String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String formatShort(DateTime d) => DateFormat('d MMM').format(d);
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}
