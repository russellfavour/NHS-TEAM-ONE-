/// Shared date/time formatting helpers used across screens.
library;

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Compact relative time, e.g. "Just now", "5m ago", "3h ago", "2d ago".
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  if (dateTime.isAfter(now)) return 'Just now';
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  // Convert to local time before formatting (API dates are UTC).
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Full local date + time, e.g. "Aug 12, 2026 at 14:20".
String formatDateTime(DateTime dateTime) {
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);
  return '${_months[local.month - 1]} ${local.day}, ${local.year} '
      'at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Date only, e.g. "Aug 12, 2026".
String formatDate(DateTime dateTime) {
  final local = DateTime(dateTime.year, dateTime.month, dateTime.day);
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Short day-of-week label for a date (used in chart axes).
String shortWeekday(DateTime dateTime) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return days[dateTime.weekday % 7];
}
