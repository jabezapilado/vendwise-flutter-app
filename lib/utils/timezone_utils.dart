const Duration _kPhilippinesOffset = Duration(hours: 8);

DateTime toPhilippineTime(DateTime dateTime) {
  return dateTime.toUtc().add(_kPhilippinesOffset);
}

DateTime startOfPhilippineDay(DateTime dateTime) {
  final local = toPhilippineTime(dateTime);
  return DateTime(local.year, local.month, local.day);
}
