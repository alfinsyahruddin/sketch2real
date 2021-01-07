String getFileName() {
  DateTime dateTime = DateTime.now();
  String dateTimeString = 'IMG_' +
      dateTime.year.toString() +
      dateTime.month.toString() +
      dateTime.day.toString() +
      dateTime.hour.toString() +
      ':' +
      dateTime.minute.toString() +
      ':' +
      dateTime.second.toString() +
      ':' +
      dateTime.millisecond.toString() +
      ':' +
      dateTime.microsecond.toString();
  return dateTimeString;
}
