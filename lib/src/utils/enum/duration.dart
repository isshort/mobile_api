enum DurationEnum {
  /// 1 second
  shortest(1),

  /// 5 seconds
  veryShortest(5),

  /// 10 seconds
  veryShort(10),

  /// 30 seconds
  short(30),

  /// 1 minute
  medium(60),

  /// 2 minutes
  long(120),

  /// 5 minutes
  extraLong(300);

  const DurationEnum(this.value);
  final int value;

  Duration get duration => Duration(seconds: value);
}
