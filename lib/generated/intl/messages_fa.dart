// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fa locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fa';

  static String m0(language) => "کد ${language}";

  static String m1(number) => "شکل ${number}";

  static String m2(number) => "جدول ${number}";

  static String m3(number) => "جدول ${number}";

  static String m4(minutes) => "${minutes} دقیقه";

  static String m5(title) => "تکمیل ${title}";

  static String m6(approved, total) => "${approved}/${total}";

  static String m7(count) => "${Intl.plural(count, other: '${count} نتیجه')}";

  static String m8(query) => "برای «${query}» چیزی پیدا نشد.";

  static String m9(count) => "${count} مورد اول نشان داده شده";

  static String m10(day) => "پشتیبان گرفته‌شده در ${day}";

  static String m11(seconds) =>
      "${Intl.plural(seconds, one: 'بازنشانی شد. تا 1 ثانیه می‌توانید آن را برگردانید.', other: 'بازنشانی شد. تا ${seconds} ثانیه می‌توانید آن را برگردانید.')}";

  static String m12(count) => "${Intl.plural(count, one: 'وضعیت 1 درس', other: 'وضعیت ${count} درس')}";

  static String m13(hours) => "~${hours} ساعت";

  static String m14(hours, minutes) => "~${hours} ساعت و ${minutes} دقیقه";

  static String m15(minutes) => "~${minutes} دقیقه";

  static String m16(url) => "باز کردن ${url} ممکن نشد";

  static String m17(count, first) =>
      "دوره در ${count} سطح چیده شده و با ${first} شروع می‌شود. از سطح اول شروع کنید و هر وقت آماده بودید به سطح بعد بروید.";

  static String m18(percent) => "${percent}٪ خوانده شده";

  static String m19(minutes, words) => "${minutes} دقیقه مطالعه · ${words} کلمه";

  static String m20(approved, total) => "${approved}/${total} تکمیل‌شده";

  static String m21(total) => "--/${total} تکمیل‌شده";

  static String m22(count) => "${Intl.plural(count, one: '1 درس', other: '${count} درس')}";

  static String m23(count) => "${Intl.plural(count, one: '1 آزمون', other: '${count} آزمون')}";

  static String m24(taken, total) => "${taken} از ${total} آزمون حل شده";

  static String m25(index, count) => "پرسش ${index} از ${count}";

  static String m26(previous, best, total) => "دفعهٔ قبل: ${previous} از ${total}. بهترین: ${best} از ${total}.";

  static String m27(score, total) => "${score} از ${total}";

  static String m28(last, best, total) => "آخرین ${last} از ${total} · بهترین ${best} از ${total}";

  static String m29(count) => "${count} پرسش دربارهٔ نکته‌های اصلی این درس";

  static String m30(letter) => "این گزینه نیست. پاسخ درست ${letter} است.";

  static String m31(date) => "تکمیل‌شده در ${date}";

  static String m32(position, total) => "مورد ${position} از ${total}";

  static String m33(minutes) => "${minutes} دقیقه";

  static String m34(number, count) => "درس ${number} از ${count}";

  static String m35(label) => "${label} · برنامه‌ریزی‌شده";

  static String m36(hash, date) => "ویرایش ${hash} · ${date}";

  static String m37(reason) => "ذخیره نشد: ${reason}. برای نگه داشتن آن، در یک فایل پشتیبان بگیرید.";

  static String m38(reason) => "بررسی به‌روزرسانی‌ها کامل نشد: ${reason}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about_close": MessageLookupByLibrary.simpleMessage("بستن"),
    "about_english": MessageLookupByLibrary.simpleMessage("داستان به انگلیسی نوشته شده است."),
    "about_failed": MessageLookupByLibrary.simpleMessage(
      "داستان باز نشد. به‌روزرسانی‌ها را بررسی کنید و دوباره باز کنید.",
    ),
    "about_next": MessageLookupByLibrary.simpleMessage("بعدی"),
    "about_previous": MessageLookupByLibrary.simpleMessage("قبلی"),
    "about_skip": MessageLookupByLibrary.simpleMessage("رد شدن"),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "block_code_label": m0,
    "block_figure_caption": m1,
    "block_program_output": MessageLookupByLibrary.simpleMessage("خروجی برنامه"),
    "block_table_caption": m2,
    "block_table_region": m3,
    "block_unknown": MessageLookupByLibrary.simpleMessage("این بخش به نسخهٔ جدیدتری از برنامه نیاز دارد."),
    "caravan_maintenance": MessageLookupByLibrary.simpleMessage("در دست تعمیر و نگهداری"),
    "caravan_maintenance_body": MessageLookupByLibrary.simpleMessage(
      "کاروان، گاه‌شمار آنچه در مهندسی هوش مصنوعی پرطرفدار بوده، هنوز در دست ساخت است.",
    ),
    "card_description": MessageLookupByLibrary.simpleMessage("توضیح"),
    "card_length": MessageLookupByLibrary.simpleMessage("مدت"),
    "card_length_minutes": m4,
    "card_requires": MessageLookupByLibrary.simpleMessage("پیش‌نیاز"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("ندارد"),
    "catalog_complete_module": m5,
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("تکمیل‌شده"),
    "catalog_level_dial": m6,
    "catalog_search_clear": MessageLookupByLibrary.simpleMessage("پاک کردن جستجو"),
    "catalog_search_count": m7,
    "catalog_search_hint": MessageLookupByLibrary.simpleMessage("جستجو در ماژول‌ها"),
    "catalog_search_none": m8,
    "catalog_search_shown": m9,
    "catalog_state_complete": MessageLookupByLibrary.simpleMessage("تکمیل‌شده"),
    "catalog_state_not_yet": MessageLookupByLibrary.simpleMessage("هنوز نه"),
    "content_broken_message": MessageLookupByLibrary.simpleMessage(
      "محتوای دوره در این برنامه باز نشد. به‌روزرسانی برنامه آن را بازمی‌گرداند. پیشرفت شما در این دستگاه حفظ می‌شود.",
    ),
    "content_broken_storage_message": MessageLookupByLibrary.simpleMessage(
      "برنامه نتوانست از فضای ذخیره‌سازی خود برای محتوای دوره استفاده کند. پیشرفت شما در این دستگاه حفظ می‌شود.",
    ),
    "content_broken_title": MessageLookupByLibrary.simpleMessage("دوره باز نمی‌شود"),
    "content_notice_cache_discarded": MessageLookupByLibrary.simpleMessage(
      "محتوای دانلودشده خوانده نشد، پس برنامه آن را حذف کرد و محتوایی را نشان می‌دهد که همراه این نسخه آمده است. برای دانلود دوبارهٔ آن، در تنظیمات به‌روزرسانی‌ها را بررسی کنید.",
    ),
    "content_unreadable": MessageLookupByLibrary.simpleMessage(
      "این بخش از دوره روی این دستگاه خوانده نشد. برای بارگذاری دوباره، برنامه را از نو باز کنید.",
    ),
    "data_back_up": MessageLookupByLibrary.simpleMessage("پشتیبان‌گیری در فایل"),
    "data_backed_up": m10,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "فایل پشتیبان نوشته نشد. هیچ چیز به‌عنوان پشتیبان‌گیری‌شده علامت نخورد.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "پیشرفت شما فقط روی این دستگاه ذخیره می‌شود. فایل پشتیبان آن را در صورت پاک شدن داده‌های برنامه حفظ می‌کند و به دستگاهی دیگر یا به وب‌سایت منتقل می‌کند.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("بازنشانی"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("بازنشانی شد. زمان برگرداندن آن گذشته است."),
    "data_reset_counting": m11,
    "data_reset_not_finished": MessageLookupByLibrary.simpleMessage(
      "بازنشانی کامل نشد: برنامه نتوانست فایل‌هایش را حذف کند. پیشرفت روی این دستگاه تغییری نکرده است.",
    ),
    "data_restore": MessageLookupByLibrary.simpleMessage("بازیابی از فایل"),
    "data_restore_empty": MessageLookupByLibrary.simpleMessage(
      "چیزی تغییر نکرد. این فایل پیشرفتی در خود ندارد؛ فقط فایل پشتیبان پیشرفت را نگه می‌دارد.",
    ),
    "data_restore_malformed": MessageLookupByLibrary.simpleMessage(
      "این فایل پشتیبانی نیست که برنامه یا وب‌سایت نوشته باشد. چیزی تغییر نکرد.",
    ),
    "data_restore_newer": MessageLookupByLibrary.simpleMessage(
      "این فایل را نسخهٔ جدیدتری از برنامه یا وب‌سایت نوشته است. برنامه را به‌روزرسانی کنید و دوباره آن را بازیابی کنید.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("این فایل باز نشد."),
    "data_restored": MessageLookupByLibrary.simpleMessage("از فایل بازیابی شد."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("چیزی روی این دستگاه ثبت نشده است"),
    "data_tally_states": m12,
    "data_undo": MessageLookupByLibrary.simpleMessage("برگرداندن"),
    "diagram_expand": MessageLookupByLibrary.simpleMessage("نمایش نمودار در تمام صفحه"),
    "duration_hours": m13,
    "duration_hours_minutes": m14,
    "duration_minutes": m15,
    "erase_backup_statement": MessageLookupByLibrary.simpleMessage(
      "ممکن است پشتیبان دستگاه هنوز نسخهٔ قدیمی‌تری از پیشرفت شما را داشته باشد.",
    ),
    "erase_confirm": MessageLookupByLibrary.simpleMessage("پاک کردن همهٔ داده‌ها"),
    "erase_field_label": MessageLookupByLibrary.simpleMessage("برای تأیید، ERASE را تایپ کنید"),
    "erase_keep": MessageLookupByLibrary.simpleMessage("داده‌هایم را نگه دار"),
    "erase_mark": MessageLookupByLibrary.simpleMessage("پاک کردن"),
    "erase_scope": MessageLookupByLibrary.simpleMessage(
      "این کار سابقه را از این دستگاه حذف می‌کند، از جمله نسخه‌ای که از یک نسخهٔ دیگر برنامه کنار گذاشته شده بود و این نسخه نمی‌توانست آن را بخواند.",
    ),
    "erase_scores": MessageLookupByLibrary.simpleMessage("امتیازهای آزمون در این دستگاه هم پاک می‌شوند."),
    "erase_title": MessageLookupByLibrary.simpleMessage("همهٔ پیشرفت روی این دستگاه پاک شود؟"),
    "error_link_open_failed": m16,
    "guide_complete": MessageLookupByLibrary.simpleMessage(
      "وقتی درسی را تمام کردید، آن را تکمیل‌شده علامت بزنید. کاتالوگ نشان می‌دهد چه خوانده‌اید و صفحهٔ خانه درس بعدی را نشان می‌دهد.",
    ),
    "guide_complete_title": MessageLookupByLibrary.simpleMessage("آنچه را تمام می‌کنید علامت بزنید"),
    "guide_levels": m17,
    "guide_levels_title": MessageLookupByLibrary.simpleMessage("سطح به سطح"),
    "guide_modules": MessageLookupByLibrary.simpleMessage(
      "هر درس 20 تا 30 دقیقه مطالعه است، همراه با نمودار و کد. در پایان برخی درس‌ها چند پرسش برای سنجیدن خودتان هست.",
    ),
    "guide_modules_title": MessageLookupByLibrary.simpleMessage("درس‌های کوتاه"),
    "guide_offline": MessageLookupByLibrary.simpleMessage(
      "تمام دوره داخل برنامه است و بدون اتصال خوانده می‌شود. حسابی در کار نیست: پیشرفت شما روی همین گوشی می‌ماند.",
    ),
    "guide_offline_title": MessageLookupByLibrary.simpleMessage("روی همین دستگاه، بدون اینترنت"),
    "guide_title": MessageLookupByLibrary.simpleMessage("بازار چطور کار می‌کند"),
    "home_after": MessageLookupByLibrary.simpleMessage("بعد از آن"),
    "home_all_complete": MessageLookupByLibrary.simpleMessage("همهٔ درس‌های نوشته‌شده تکمیل شده‌اند."),
    "home_continue": MessageLookupByLibrary.simpleMessage("ادامه"),
    "home_continue_reading": MessageLookupByLibrary.simpleMessage("ادامهٔ خواندن"),
    "home_offline_body": MessageLookupByLibrary.simpleMessage(
      "بدون اتصال به اینترنت هم خوانده می‌شود. برنامه هر بار که باز می‌شود، از سایت نسخهٔ جدیدتر را می‌پرسد.",
    ),
    "home_offline_title": MessageLookupByLibrary.simpleMessage("دوره روی این دستگاه است"),
    "home_open_module": MessageLookupByLibrary.simpleMessage("باز کردن درس"),
    "home_path": MessageLookupByLibrary.simpleMessage("مسیر شما"),
    "home_practice": MessageLookupByLibrary.simpleMessage("آزمون‌هایی برای تمرین"),
    "home_practice_lede": MessageLookupByLibrary.simpleMessage("آزمون‌های درس‌هایی که تکمیل کرده‌اید."),
    "home_read_percent": m18,
    "home_see_catalog": MessageLookupByLibrary.simpleMessage("دیدن کل کاتالوگ"),
    "home_up_next": MessageLookupByLibrary.simpleMessage("درس بعدی"),
    "image_expand": MessageLookupByLibrary.simpleMessage("نمایش تصویر در تمام صفحه"),
    "image_replay": MessageLookupByLibrary.simpleMessage("پخش دوباره"),
    "legal_address": MessageLookupByLibrary.simpleMessage("نشانی"),
    "legal_email": MessageLookupByLibrary.simpleMessage("ایمیل"),
    "legal_images": MessageLookupByLibrary.simpleMessage(
      "برخی تصاویر از مقاله‌ها و دیگر منابع عمومی آمده‌اند، با سپاس صمیمانه از نویسندگانشان. این تصاویر دارایی صاحبانشان می‌مانند، هیچ حقی بر آن‌ها ادعا نمی‌شود و فقط برای توضیح مطلب کنارشان نشان داده می‌شوند. صاحب تصویر یا نشانی که اینجا آمده می‌تواند به نشانی زیر بنویسد تا نامش افزوده شود یا آن برداشته شود، هر کدام را که ترجیح دهد.",
    ),
    "legal_licence": MessageLookupByLibrary.simpleMessage(
      "مجوز MIT پروژه کد و محتوای آن را در بر می‌گیرد. نشان‌ها و تصاویر دیگران را در بر نمی‌گیرد.",
    ),
    "legal_licence_link": MessageLookupByLibrary.simpleMessage("مجوز MIT"),
    "legal_marks": MessageLookupByLibrary.simpleMessage(
      "نام‌ها و نشان‌های شرکت‌ها که در ماژول‌ها می‌آیند متعلق به صاحبانشان هستند. فقط برای این آمده‌اند که بگویند منظور کدام شرکت است و به این معنا نیستند که آن شرکت این برنامه را تأیید می‌کند.",
    ),
    "legal_marks_title": MessageLookupByLibrary.simpleMessage("نشان‌ها و تصاویر دیگران"),
    "legal_mersis": MessageLookupByLibrary.simpleMessage("شماره MERSİS"),
    "legal_owner": MessageLookupByLibrary.simpleMessage("مالک"),
    "legal_phone": MessageLookupByLibrary.simpleMessage("تلفن"),
    "legal_title": MessageLookupByLibrary.simpleMessage("اطلاعات حقوقی"),
    "length_minutes_words": m19,
    "level_completed": m20,
    "level_completed_pending": m21,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("یادداشت‌های کلی"),
    "level_module_count": m22,
    "loading": MessageLookupByLibrary.simpleMessage("در حال بارگذاری"),
    "module_planned": MessageLookupByLibrary.simpleMessage("برنامه‌ریزی‌شده"),
    "nav_caravan": MessageLookupByLibrary.simpleMessage("کاروان"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("کاتالوگ"),
    "nav_home": MessageLookupByLibrary.simpleMessage("خانه"),
    "nav_quiz": MessageLookupByLibrary.simpleMessage("آزمون"),
    "nav_settings": MessageLookupByLibrary.simpleMessage("تنظیمات"),
    "not_found_message": MessageLookupByLibrary.simpleMessage(
      "این نشانی به هیچ درسی از برنامهٔ آموزشی تعلق ندارد. همهٔ درس‌ها در کاتالوگ فهرست شده‌اند.",
    ),
    "not_found_title": MessageLookupByLibrary.simpleMessage("چنین درسی وجود ندارد"),
    "open_on_the_web": MessageLookupByLibrary.simpleMessage("باز کردن در وب"),
    "privacy_contact": MessageLookupByLibrary.simpleMessage("برای هر پرسشی درباره داده‌های شخصی به ما بنویسید."),
    "privacy_crash": MessageLookupByLibrary.simpleMessage(
      "وقتی برنامه از کار می‌افتد، گزارش خطا را به Sentry می‌فرستد تا ایراد رفع شود. برنامه پیش از خروج گزارش از دستگاه، جزئیات شخصی آن را می‌پوشاند.",
    ),
    "privacy_download": MessageLookupByLibrary.simpleMessage(
      "برنامه دوره را از وب‌سایت دانلود می‌کند که روی GitHub Pages میزبانی می‌شود. GitHub برای امنیت، نشانی IP هر بازدیدکننده را ثبت و نگهداری می‌کند. این سابقه متعلق به GitHub است، نه ما.",
    ),
    "privacy_github_pages": MessageLookupByLibrary.simpleMessage("What is GitHub Pages?"),
    "privacy_github_statement": MessageLookupByLibrary.simpleMessage("GitHub General Privacy Statement"),
    "privacy_no_data": MessageLookupByLibrary.simpleMessage(
      "این برنامه هیچ داده شخصی جمع نمی‌کند. حساب کاربری، ابزار تحلیل و تبلیغ ندارد.",
    ),
    "privacy_on_device": MessageLookupByLibrary.simpleMessage(
      "پیشرفت، امتیاز آزمون‌ها و تنظیمات شما فقط روی همین دستگاه ذخیره می‌شوند. می‌توانید در تنظیمات، بخش پیشرفت شما، از آن‌ها نسخه پشتیبان بگیرید، بازیابی‌شان کنید یا پاکشان کنید.",
    ),
    "privacy_title": MessageLookupByLibrary.simpleMessage("حریم خصوصی"),
    "quarantine_copy_not_written": MessageLookupByLibrary.simpleMessage(
      "کپی نوشته نشد. سابقهٔ کنارگذاشته‌شده تغییری نکرده است.",
    ),
    "quarantine_copy_saved": MessageLookupByLibrary.simpleMessage("یک کپی از سابقهٔ کنارگذاشته‌شده ذخیره شد."),
    "quarantine_delete": MessageLookupByLibrary.simpleMessage("حذف آن"),
    "quarantine_delete_body": MessageLookupByLibrary.simpleMessage(
      "این نسخه از برنامه نمی‌تواند آن را بخواند. حذف آن برگشت‌پذیر نیست.",
    ),
    "quarantine_delete_confirm": MessageLookupByLibrary.simpleMessage("حذف"),
    "quarantine_delete_title": MessageLookupByLibrary.simpleMessage("سابقهٔ کنارگذاشته‌شده حذف شود؟"),
    "quarantine_keep": MessageLookupByLibrary.simpleMessage("نگه داشتن آن"),
    "quarantine_kept_note": MessageLookupByLibrary.simpleMessage(
      "یکی از اجراهای قبلی برنامه نتوانست پیشرفت ذخیره‌شده را بخواند. بایت‌های آن بدون تغییر روی این دستگاه نگه داشته شده است.",
    ),
    "quarantine_kept_readout": MessageLookupByLibrary.simpleMessage("یک سابقهٔ ذخیره‌شده کنار گذاشته شده است"),
    "quarantine_label": MessageLookupByLibrary.simpleMessage("وضعیت سابقه"),
    "quarantine_malformed_note": MessageLookupByLibrary.simpleMessage(
      "سابقهٔ ذخیره‌شده ساختاری ندارد که این نسخه از برنامه بتواند بخواند. به‌جای دور ریخته شدن، بدون تغییر در جای جداگانه‌ای روی این دستگاه کپی شده و چیزی روی آن نوشته نشده است.",
    ),
    "quarantine_malformed_readout": MessageLookupByLibrary.simpleMessage(
      "پیشرفتی که این نسخه از برنامه نتوانست بخواند. خوانده نشد.",
    ),
    "quarantine_newer_note": MessageLookupByLibrary.simpleMessage(
      "برای خواندن آن، برنامه را به‌روزرسانی کنید. سابقهٔ ذخیره‌شده بدون تغییر روی این دستگاه نگه داشته می‌شود.",
    ),
    "quarantine_newer_readout": MessageLookupByLibrary.simpleMessage(
      "پیشرفتی که نسخهٔ جدیدتری از برنامه نوشته است. خوانده نشد.",
    ),
    "quarantine_save_copy": MessageLookupByLibrary.simpleMessage("ذخیرهٔ یک کپی"),
    "quiz_all_right": MessageLookupByLibrary.simpleMessage("همه پاسخ‌ها درست"),
    "quiz_back_to_module": MessageLookupByLibrary.simpleMessage("بازگشت به درس"),
    "quiz_back_to_questions": MessageLookupByLibrary.simpleMessage("بازگشت به پرسش‌ها"),
    "quiz_correct": MessageLookupByLibrary.simpleMessage("درست است."),
    "quiz_done": MessageLookupByLibrary.simpleMessage("تمام"),
    "quiz_list_count": m23,
    "quiz_list_taken": m24,
    "quiz_next": MessageLookupByLibrary.simpleMessage("بعدی"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("قبلی"),
    "quiz_progress": m25,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage("، درست"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage("، نادرست"),
    "quiz_score_before": m26,
    "quiz_score_count": m27,
    "quiz_score_line": m28,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("را درست پاسخ دادید"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("دیدن نتیجه‌ها"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("شروع دوباره"),
    "quiz_subtitle": m29,
    "quiz_title": MessageLookupByLibrary.simpleMessage("پرسش‌های این درس"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage(
      "این آزمون باز نشد. آن را ببندید و بعداً دوباره امتحان کنید.",
    ),
    "quiz_wrong": m30,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("بخشی نوشته شده"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("فقط برنامهٔ بخش‌ها"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("پیش از شروع"),
    "reader_close": MessageLookupByLibrary.simpleMessage("بستن"),
    "reader_completed_on": m31,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("تکمیل درس"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("فهرست مطالب"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("پایان دوره"),
    "reader_find_close": MessageLookupByLibrary.simpleMessage("حذف نشانه‌های جستجو"),
    "reader_find_next": MessageLookupByLibrary.simpleMessage("مورد بعدی"),
    "reader_find_position": m32,
    "reader_find_previous": MessageLookupByLibrary.simpleMessage("مورد قبلی"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("علامت زدن این درس به‌عنوان تکمیل‌شده"),
    "reader_minutes": m33,
    "reader_module_of": m34,
    "reader_next": MessageLookupByLibrary.simpleMessage("بعدی"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("نسخهٔ «برای همه»ی این درس برنامه‌ریزی شده است."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("آنچه خواهید توانست انجام دهید"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("در این صفحه"),
    "reader_pager_planned": m35,
    "reader_previous": MessageLookupByLibrary.simpleMessage("قبلی"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("خواندن نسخهٔ «برای مهندسان»"),
    "reader_revision": m36,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("توضیح"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("مورد"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("برنامهٔ بخش‌ها"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("بخش‌ها"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("دیدن آنچه «برای همه» نوشته شده است"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("آغاز دوره"),
    "record_not_saved": m37,
    "record_not_saved_blocked": MessageLookupByLibrary.simpleMessage("برنامه نتوانست فایل خود را بنویسد"),
    "record_not_saved_quota": MessageLookupByLibrary.simpleMessage("فضای خالی این دستگاه تمام شده است"),
    "record_not_saved_too_large": MessageLookupByLibrary.simpleMessage("حجم سابقه بیشتر از حدی است که برنامه می‌نویسد"),
    "restore_confirm_effect": MessageLookupByLibrary.simpleMessage(
      "بازیابی، آن را با پیشرفت داخل فایل جایگزین می‌کند.",
    ),
    "restore_confirm_holds": MessageLookupByLibrary.simpleMessage("اکنون روی این دستگاه:"),
    "restore_confirm_replace": MessageLookupByLibrary.simpleMessage("جایگزین کردن"),
    "restore_confirm_title": MessageLookupByLibrary.simpleMessage("پیشرفت روی این دستگاه جایگزین شود؟"),
    "settings": MessageLookupByLibrary.simpleMessage("تنظیمات"),
    "settings_about": MessageLookupByLibrary.simpleMessage("درباره"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("بررسی به‌روزرسانی‌ها"),
    "settings_content": MessageLookupByLibrary.simpleMessage("محتوا"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("نسخه"),
    "settings_data": MessageLookupByLibrary.simpleMessage("پیشرفت شما"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("کنسول توسعه‌دهنده"),
    "settings_language": MessageLookupByLibrary.simpleMessage("زبان"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("مجوزها"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("حریم خصوصی و اطلاعات حقوقی"),
    "settings_published": MessageLookupByLibrary.simpleMessage("انتشار"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("خواندن"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("در حال بررسی به‌روزرسانی‌ها"),
    "settings_refresh_failed": m38,
    "settings_refresh_idle": MessageLookupByLibrary.simpleMessage("از زمان باز شدن برنامه بررسی نشده است"),
    "settings_refresh_needs_app_update": MessageLookupByLibrary.simpleMessage(
      "محتوای جدیدتر به نسخهٔ جدیدتری از برنامه نیاز دارد. برای دریافت آن، برنامه را به‌روزرسانی کنید.",
    ),
    "settings_refresh_reason_checksum": MessageLookupByLibrary.simpleMessage(
      "یک فایل دانلودشده با checksum خود مطابقت نداشت",
    ),
    "settings_refresh_reason_format": MessageLookupByLibrary.simpleMessage(
      "وب‌سایت محتوایی فرستاد که این نسخه از برنامه نمی‌تواند بخواند",
    ),
    "settings_refresh_reason_http_status": MessageLookupByLibrary.simpleMessage("وب‌سایت با خطا پاسخ داد"),
    "settings_refresh_reason_network": MessageLookupByLibrary.simpleMessage("اتصالی به وب‌سایت برقرار نیست"),
    "settings_refresh_reason_storage": MessageLookupByLibrary.simpleMessage(
      "برنامه نتوانست در فضای ذخیره‌سازی خود بنویسد",
    ),
    "settings_refresh_reason_stored": MessageLookupByLibrary.simpleMessage("محتوای ذخیره‌شده خوانده نشد"),
    "settings_refresh_up_to_date": MessageLookupByLibrary.simpleMessage("به‌روز است"),
    "settings_refresh_updated": MessageLookupByLibrary.simpleMessage("به آخرین محتوا به‌روزرسانی شد"),
    "settings_source": MessageLookupByLibrary.simpleMessage("منبع"),
    "settings_source_bundled": MessageLookupByLibrary.simpleMessage("همراه برنامه"),
    "settings_source_downloaded": MessageLookupByLibrary.simpleMessage("دانلودشده از وب‌سایت"),
    "settings_story": MessageLookupByLibrary.simpleMessage("داستان بازار"),
    "settings_track": MessageLookupByLibrary.simpleMessage("مخاطب"),
    "track_engineers": MessageLookupByLibrary.simpleMessage("برای مهندسان"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("برای همه"),
    "welcome_start": MessageLookupByLibrary.simpleMessage("شروع خواندن"),
    "welcome_story_continue": MessageLookupByLibrary.simpleMessage("شروع یادگیری"),
    "welcome_to_story": MessageLookupByLibrary.simpleMessage("برو به داستان ما"),
    "welcome_track_engineers": MessageLookupByLibrary.simpleMessage(
      "درس‌های فنی: هر بخش چطور کار می‌کند، همراه با کد و عددهای پشت آن.",
    ),
    "welcome_track_everyone": MessageLookupByLibrary.simpleMessage(
      "همین درس‌ها به زبان ساده، برای خوانندگانی که پیش‌زمینهٔ فنی ندارند.",
    ),
    "welcome_track_lede": MessageLookupByLibrary.simpleMessage(
      "زبان خود و یکی از دو نسخهٔ هر درس را انتخاب کنید. هر زمان بخواهید می‌توانید هر دو را در تنظیمات تغییر دهید.",
    ),
    "welcome_track_title": MessageLookupByLibrary.simpleMessage("دوست دارید چطور بخوانید؟"),
  };
}
