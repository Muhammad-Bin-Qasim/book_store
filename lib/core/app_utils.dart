import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';

class AppUtils {
  AppUtils._();

  static double toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? dateTimeFromValue(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> stringList(dynamic value) {
    if (value is! Iterable) return <String>[];
    return value.whereType<String>().toList(growable: false);
  }

  static String formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs ',
      decimalDigits: 2,
    ).format(price);
  }

  static TextStyle priceTextStyle({TextStyle? baseStyle}) =>
      AppTheme.priceTextStyle(baseStyle: baseStyle);
}
