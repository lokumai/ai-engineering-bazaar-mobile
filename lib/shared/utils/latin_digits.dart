import 'package:intl/intl.dart';

/// The app writes Latin digits in every language, as the web does and as [groupedNumber] already wrote a word count
/// (the owner, 2026-11-23): Persian dates and numbers took Persian digits from intl, beside the Latin ones of every
/// string, so one screen read "۱۶ نوامبر ۲۰۲۶" over "درس 3 از 46" (review 5, finding 6).

/// [format] writing Latin digits: intl writes each language's own, Persian's among them.
DateFormat latinDigits(DateFormat format) => format..useNativeDigits = false;

/// The locale a number in [language] is formatted in: Persian's writes Persian digits, so it is written as English
/// writes it, which groups by comma as [groupedNumber] does in Persian; any other language keeps its own (a decimal
/// comma in Turkish).
String numberLocale(String language) => language == 'fa' ? 'en' : language;
