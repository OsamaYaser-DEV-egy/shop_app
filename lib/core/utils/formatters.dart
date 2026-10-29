import 'package:intl/intl.dart';

/// Shared formatting helpers for prices and dates.
abstract final class Formatters {
  static final NumberFormat _price =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final DateFormat _date = DateFormat('MMM d, y');
  static final DateFormat _dateTime = DateFormat('MMM d, y • h:mm a');

  static String price(num value) => _price.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
}
