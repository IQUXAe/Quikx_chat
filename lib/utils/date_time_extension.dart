import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/matrix.dart';

/// Provides extra functionality for formatting the time.
extension DateTimeExtension on DateTime {
  bool operator <(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  bool operator >(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  bool operator >=(DateTime other) {
    return millisecondsSinceEpoch >= other.millisecondsSinceEpoch;
  }

  bool operator <=(DateTime other) {
    return millisecondsSinceEpoch <= other.millisecondsSinceEpoch;
  }

  /// Checks if two DateTimes are close enough to belong to the same
  /// environment.
  bool sameEnvironment(DateTime prevTime) =>
      difference(prevTime) < const Duration(hours: 1);

  /// Returns a simple time String.
  String localizedTimeOfDay(BuildContext context) {
    final use24Hour = Matrix.of(context).store.getBool('use24HourFormat') ?? true;
    return use24Hour
        ? DateFormat('HH:mm', L10n.of(context).localeName).format(this)
        : DateFormat('h:mm a', L10n.of(context).localeName).format(this);
  }

  /// Returns [localizedTimeOfDay()] if the ChatTime is today, the name of the week
  /// day if the ChatTime is this week and a date string else.
  String localizedTimeShort(BuildContext context) {
    final now = DateTime.now();

    final sameYear = now.year == year;

    final sameDay = sameYear && now.month == month && now.day == day;

    final sameWeek = sameYear &&
        !sameDay &&
        now.millisecondsSinceEpoch - millisecondsSinceEpoch <
            1000 * 60 * 60 * 24 * 7;

    if (sameDay) {
      return localizedTimeOfDay(context);
    } else if (sameWeek) {
      return DateFormat.E(Localizations.localeOf(context).languageCode)
          .format(this);
    } else if (sameYear) {
      return DateFormat.MMMd(Localizations.localeOf(context).languageCode)
          .format(this);
    }
    return DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
        .format(this);
  }

  /// If the DateTime is today, this returns [localizedTimeOfDay()], if not it also
  /// shows the date.
  String localizedTime(BuildContext context) {
    final now = DateTime.now();

    final sameYear = now.year == year;

    final sameDay = sameYear && now.month == month && now.day == day;

    if (sameDay) return localizedTimeOfDay(context);
    return L10n.of(context).dateAndTimeOfDay(
      localizedTimeShort(context),
      localizedTimeOfDay(context),
    );
  }
}
