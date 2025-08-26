extension StringExtension on String {
  String get subStringLongString => (length > 2000) ? substring(0, 2000) : this;
}
