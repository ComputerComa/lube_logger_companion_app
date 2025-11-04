import 'package:intl/intl.dart';

class DateFormatters {
  static final DateFormat _apiDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  
  static String formatForApi(DateTime date) {
    return _apiDateFormat.format(date);
  }
  
  static DateTime? parseFromApi(String dateString) {
    try {
      return _apiDateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  static String formatForDisplay(DateTime date) {
    return _displayDateFormat.format(date);
  }
  
  static String formatDateTimeForDisplay(DateTime date) {
    return _displayDateTimeFormat.format(date);
  }
}
