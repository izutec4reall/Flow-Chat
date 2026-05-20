import 'package:intl/intl.dart';

class DateFormatter {
  static String formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == time.day) {
      return DateFormat('hh:mm a').format(time); // e.g. 10:30 AM
    } else if (difference.inDays < 2 && now.day - time.day == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time); // e.g. Monday
    } else {
      return DateFormat('dd MMM, yy').format(time); // e.g. 12 May, 24
    }
  }

  static String formatChatBubbleTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatChatDateSeparator(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return 'Today';
    } else if (now.difference(time).inDays < 2 && now.day - time.day == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMMM yyyy').format(time); // 12 May 2024
    }
  }
}
