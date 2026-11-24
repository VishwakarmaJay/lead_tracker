/// Small, dependency-free display formatters. All inputs are converted to
/// local time here — the database stores UTC.
library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `3:05 PM`
String formatTime(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// `24 Nov 2026`
String formatDate(DateTime time) {
  final local = time.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// `Today, 3:05 PM` · `Yesterday, 3:05 PM` · `24 Nov 2026, 3:05 PM`
String formatDateTime(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final difference = todayDay.difference(day).inDays;
  final datePart = switch (difference) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => formatDate(local),
  };
  return '$datePart, ${formatTime(local)}';
}

/// `45s` · `2m 05s` · `1h 02m`
String formatCallDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    return '${minutes}m ${(seconds % 60).toString().padLeft(2, '0')}s';
  }
  return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}
