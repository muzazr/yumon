import 'package:intl/intl.dart';

class DateFormatter {
  static final _short = DateFormat('dd MMM yyyy');
  static final _month = DateFormat('MMMM yyyy');
  static final _time = DateFormat('dd MMM yyyy, HH:mm');

  static String short(DateTime date) => _short.format(date);
  static String month(DateTime date) => _month.format(date);
  static String dateTime(DateTime date) => _time.format(date);
}
