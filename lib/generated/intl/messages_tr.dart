// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static String m0(language) => "${language} kodu";

  static String m1(number) => "ŞEKİL ${number}";

  static String m2(number) => "TABLO ${number}";

  static String m3(number) => "Tablo ${number}";

  static String m4(minutes) => "${minutes} dk";

  static String m5(title) => "${title} modülünü tamamla";

  static String m6(approved, total) => "${approved}/${total}";

  static String m7(day) => "Son yedek: ${day}";

  static String m8(seconds) =>
      "${Intl.plural(seconds, one: 'Sıfırlandı. 1 saniye içinde geri alabilirsin.', other: 'Sıfırlandı. ${seconds} saniye içinde geri alabilirsin.')}";

  static String m9(count) => "${Intl.plural(count, one: '1 modül durumu', other: '${count} modül durumu')}";

  static String m10(hours) => "~${hours} sa";

  static String m11(hours, minutes) => "~${hours} sa ${minutes} dk";

  static String m12(minutes) => "~${minutes} dk";

  static String m13(url) => "${url} açılamadı";

  static String m14(count, first) =>
      "Kurs, ${first} ile başlayan ${count} seviyeye ayrılır. İlkinden başla, hazır olduğunda bir sonrakine geç.";

  static String m15(approved, total) => "${approved}/${total} tamamlandı";

  static String m16(total) => "--/${total} tamamlandı";

  static String m17(count) => "${Intl.plural(count, one: '1 modül', other: '${count} modül')}";

  static String m18(count) => "${Intl.plural(count, one: '1 quiz', other: '${count} quiz')}";

  static String m19(track) => "Sorular ${track} modülleriyle gelir.";

  static String m20(taken, total) => "${total} quizden ${taken} tanesi çözüldü";

  static String m21(index, count) => "Soru ${index} / ${count}";

  static String m22(previous, best, total) => "Bir önceki: ${previous} / ${total}. En iyi: ${best} / ${total}.";

  static String m23(score, total) => "${score} / ${total}";

  static String m24(last, best, total) => "Son ${last} / ${total} · en iyi ${best} / ${total}";

  static String m25(count) => "Bu modülün ana noktalarına dair ${count} soru";

  static String m26(letter) => "Bu değil. Doğru cevap ${letter}.";

  static String m27(date) => "${date} tarihinde tamamlandı";

  static String m28(minutes) => "${minutes} dk";

  static String m29(number, count) => "MODÜL ${number} / ${count}";

  static String m30(label) => "${label} · Planlandı";

  static String m31(hash, date) => "Rev. ${hash} · ${date}";

  static String m32(reason) => "Kaydedilmedi: ${reason}. Korumak için bir dosyaya yedekle.";

  static String m33(reason) => "Güncelleme kontrolü tamamlanmadı: ${reason}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about_english": MessageLookupByLibrary.simpleMessage("Hikâye İngilizce yazıldı."),
    "about_failed": MessageLookupByLibrary.simpleMessage("Hikâye açılamadı. Güncellemeleri denetle, sonra yeniden aç."),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "block_code_label": m0,
    "block_figure_caption": m1,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program çıktısı"),
    "block_table_caption": m2,
    "block_table_region": m3,
    "block_unknown": MessageLookupByLibrary.simpleMessage("Bu bölüm için uygulamanın daha yeni bir sürümü gerekiyor."),
    "card_description": MessageLookupByLibrary.simpleMessage("Açıklama"),
    "card_length": MessageLookupByLibrary.simpleMessage("Süre"),
    "card_length_minutes": m4,
    "card_requires": MessageLookupByLibrary.simpleMessage("Ön koşul"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Yok"),
    "catalog_complete_module": m5,
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Tamamlananlar"),
    "catalog_level_dial": m6,
    "catalog_state_complete": MessageLookupByLibrary.simpleMessage("Tamamlandı"),
    "catalog_state_not_yet": MessageLookupByLibrary.simpleMessage("Henüz değil"),
    "content_broken_message": MessageLookupByLibrary.simpleMessage(
      "Bu uygulamadaki kurs içeriği açılamadı. Uygulamayı güncellemek sorunu giderir. Bu cihazdaki ilerlemen korunur.",
    ),
    "content_broken_storage_message": MessageLookupByLibrary.simpleMessage(
      "Uygulama, kurs içeriği için depolama alanını kullanamadı. Bu cihazdaki ilerlemen korunur.",
    ),
    "content_broken_title": MessageLookupByLibrary.simpleMessage("Kurs açılamıyor"),
    "content_notice_cache_discarded": MessageLookupByLibrary.simpleMessage(
      "İndirilen içerik okunamadığı için uygulama onu kaldırdı ve bu sürümle gelen içeriği gösteriyor. Yeniden indirmek için Ayarlar\'dan güncellemeleri kontrol et.",
    ),
    "content_unreadable": MessageLookupByLibrary.simpleMessage(
      "Kursun bu bölümü bu cihazda okunamadı. Yeniden yüklemek için uygulamayı yeniden başlat.",
    ),
    "data_back_up": MessageLookupByLibrary.simpleMessage("Dosyaya yedekle"),
    "data_backed_up": m7,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "Yedek dosyası yazılamadı. Hiçbir şey yedeklendi olarak işaretlenmedi.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "İlerlemen yalnızca bu cihazda kayıtlı. Bir yedek dosyası, uygulamanın verileri silinirse ilerlemeni korur; onu başka bir cihaza ya da web sitesine taşımanı da sağlar.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Sıfırla"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Sıfırlandı. Geri alma süresi doldu."),
    "data_reset_counting": m8,
    "data_reset_not_finished": MessageLookupByLibrary.simpleMessage(
      "Sıfırlama tamamlanmadı: uygulama dosyalarını silemedi. Bu cihazdaki ilerlemen değişmedi.",
    ),
    "data_restore": MessageLookupByLibrary.simpleMessage("Dosyadan geri yükle"),
    "data_restore_empty": MessageLookupByLibrary.simpleMessage(
      "Hiçbir şey değişmedi. Bu dosyada ilerleme yok; ilerleme yalnızca yedek dosyasında bulunur.",
    ),
    "data_restore_malformed": MessageLookupByLibrary.simpleMessage(
      "Bu dosya, uygulamanın ya da web sitesinin yazdığı bir yedek değil. Hiçbir şey değişmedi.",
    ),
    "data_restore_newer": MessageLookupByLibrary.simpleMessage(
      "Bu dosya, uygulamanın ya da web sitesinin daha yeni bir sürümüyle yazılmış. Uygulamayı güncelle, sonra dosyayı yeniden geri yükle.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("Bu dosya açılamadı."),
    "data_restored": MessageLookupByLibrary.simpleMessage("Dosyadan geri yüklendi."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("BU CİHAZDA KAYITLI BİR ŞEY YOK"),
    "data_tally_states": m9,
    "data_undo": MessageLookupByLibrary.simpleMessage("Geri al"),
    "duration_hours": m10,
    "duration_hours_minutes": m11,
    "duration_minutes": m12,
    "erase_backup_statement": MessageLookupByLibrary.simpleMessage(
      "Cihaz yedeklerinden birinde ilerlemenin daha eski bir kopyası hâlâ bulunabilir.",
    ),
    "erase_confirm": MessageLookupByLibrary.simpleMessage("Bütün verileri sil"),
    "erase_field_label": MessageLookupByLibrary.simpleMessage("Onaylamak için ERASE yaz"),
    "erase_keep": MessageLookupByLibrary.simpleMessage("Verilerimi koru"),
    "erase_mark": MessageLookupByLibrary.simpleMessage("Sil"),
    "erase_scope": MessageLookupByLibrary.simpleMessage(
      "Bu işlem kaydı bu cihazdan kaldırır. Uygulamanın okuyamadığı bir sürümden kalıp kenara ayrılan kopya da buna dahil.",
    ),
    "erase_scores": MessageLookupByLibrary.simpleMessage("Bu cihazdaki quiz skorları da silinir."),
    "erase_title": MessageLookupByLibrary.simpleMessage("Bu cihazdaki bütün ilerleme silinsin mi?"),
    "error_link_open_failed": m13,
    "guide_complete": MessageLookupByLibrary.simpleMessage(
      "Bir modülü bitirince tamamlandı olarak işaretle. Katalog ne okuduğunu, Ana sayfa sırada ne olduğunu gösterir.",
    ),
    "guide_complete_title": MessageLookupByLibrary.simpleMessage("Bitirdiğini işaretle"),
    "guide_levels": m14,
    "guide_levels_title": MessageLookupByLibrary.simpleMessage("Seviye seviye"),
    "guide_modules": MessageLookupByLibrary.simpleMessage(
      "Her modül, diyagramlar ve kodla 20 ile 30 dakikalık bir okuma. Bazılarının sonunda kendini sınaman için birkaç soru var.",
    ),
    "guide_modules_title": MessageLookupByLibrary.simpleMessage("Kısa modüller"),
    "guide_offline": MessageLookupByLibrary.simpleMessage(
      "Kursun tamamı uygulamanın içinde ve bağlantı olmadan okunur. Hesap yok: ilerlemen bu telefonda kalır.",
    ),
    "guide_offline_title": MessageLookupByLibrary.simpleMessage("Bu cihazda, internetsiz"),
    "guide_title": MessageLookupByLibrary.simpleMessage("Bazaar nasıl işler"),
    "home_after": MessageLookupByLibrary.simpleMessage("Sonrasında"),
    "home_all_complete": MessageLookupByLibrary.simpleMessage("Yazılmış bütün modüller tamamlandı."),
    "home_offline_body": MessageLookupByLibrary.simpleMessage(
      "Bağlantı olmadan da okunur. Uygulama her açılışta siteye daha yeni bir sürüm olup olmadığını sorar.",
    ),
    "home_offline_title": MessageLookupByLibrary.simpleMessage("Kurs bu cihazda"),
    "home_open_module": MessageLookupByLibrary.simpleMessage("Modülü aç"),
    "home_practice": MessageLookupByLibrary.simpleMessage("Tekrar et"),
    "home_practice_lede": MessageLookupByLibrary.simpleMessage(
      "Tamamladığın modüllerin quizleri: önce henüz çözülmemiş olanlar, sonra skoru en düşük olanlar.",
    ),
    "home_see_catalog": MessageLookupByLibrary.simpleMessage("Bütün kataloğu gör"),
    "home_up_next": MessageLookupByLibrary.simpleMessage("Sıradaki"),
    "legal_address": MessageLookupByLibrary.simpleMessage("Adres"),
    "legal_email": MessageLookupByLibrary.simpleMessage("E-posta"),
    "legal_images": MessageLookupByLibrary.simpleMessage(
      "Bazı görseller makalelerden ve başka açık kaynaklardan gelir; yazarlarına içtenlikle teşekkürler. Görseller sahiplerinin malı olarak kalır, üzerlerinde hiçbir hak iddia edilmez ve yalnızca yanlarındaki konuyu açıklamak için gösterilirler. Burada gösterilen bir görselin ya da markanın sahibi, aşağıdaki adrese yazarak tercihine göre adının eklenmesini ya da görselin kaldırılmasını isteyebilir.",
    ),
    "legal_licence": MessageLookupByLibrary.simpleMessage(
      "Projenin MIT lisansı kodunu ve içeriğini kapsar. Üçüncü tarafların markalarını ve görsellerini kapsamaz.",
    ),
    "legal_licence_link": MessageLookupByLibrary.simpleMessage("MIT lisansı"),
    "legal_marks": MessageLookupByLibrary.simpleMessage(
      "Modüllerde görünen şirket adları ve logoları sahiplerine aittir. Yalnızca hangi şirketin kastedildiğini söylemek için yer alırlar; o şirketin bu uygulamayı desteklediği anlamına gelmezler.",
    ),
    "legal_marks_title": MessageLookupByLibrary.simpleMessage("Üçüncü tarafların markaları ve görselleri"),
    "legal_mersis": MessageLookupByLibrary.simpleMessage("MERSİS no."),
    "legal_owner": MessageLookupByLibrary.simpleMessage("Sahibi"),
    "legal_phone": MessageLookupByLibrary.simpleMessage("Telefon"),
    "legal_title": MessageLookupByLibrary.simpleMessage("Yasal bilgiler"),
    "level_completed": m15,
    "level_completed_pending": m16,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("Genel notlar"),
    "level_module_count": m17,
    "loading": MessageLookupByLibrary.simpleMessage("Yükleniyor"),
    "module_planned": MessageLookupByLibrary.simpleMessage("Planlandı"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("Katalog"),
    "nav_home": MessageLookupByLibrary.simpleMessage("Ana sayfa"),
    "nav_quiz": MessageLookupByLibrary.simpleMessage("Quiz"),
    "nav_settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
    "not_found_message": MessageLookupByLibrary.simpleMessage(
      "Bu adres müfredattaki bir modüle ait değil. Modüllerin hepsi katalogda listeleniyor.",
    ),
    "not_found_title": MessageLookupByLibrary.simpleMessage("Böyle bir modül yok"),
    "open_on_the_web": MessageLookupByLibrary.simpleMessage("Web\'de aç"),
    "privacy_contact": MessageLookupByLibrary.simpleMessage("Kişisel verilerle ilgili her soru için bize yaz."),
    "privacy_crash": MessageLookupByLibrary.simpleMessage(
      "Uygulama çöktüğünde, hatanın düzeltilebilmesi için Sentry\'ye bir çökme raporu gönderir. Uygulama rapordaki kişisel ayrıntıları cihazdan çıkmadan önce gizler.",
    ),
    "privacy_download": MessageLookupByLibrary.simpleMessage(
      "Uygulama kursu web sitesinden indirir; site GitHub Pages\'te barındırılır. GitHub, güvenlik için her ziyaretçinin IP adresini kaydeder ve saklar. Bu kayıt GitHub\'ındır, bizim değil.",
    ),
    "privacy_github_pages": MessageLookupByLibrary.simpleMessage("What is GitHub Pages?"),
    "privacy_github_statement": MessageLookupByLibrary.simpleMessage("GitHub General Privacy Statement"),
    "privacy_no_data": MessageLookupByLibrary.simpleMessage(
      "Bu uygulama kişisel veri toplamaz. Hesap, analiz aracı ve reklam yoktur.",
    ),
    "privacy_on_device": MessageLookupByLibrary.simpleMessage(
      "İlerlemen, quiz skorların ve ayarların yalnızca bu cihazda saklanır. Onları Ayarlar\'da İlerlemen bölümünden yedekleyebilir, geri yükleyebilir ya da silebilirsin.",
    ),
    "privacy_title": MessageLookupByLibrary.simpleMessage("Gizlilik"),
    "quarantine_copy_not_written": MessageLookupByLibrary.simpleMessage(
      "Kopya yazılamadı. Kenara ayrılan kayıt değişmedi.",
    ),
    "quarantine_copy_saved": MessageLookupByLibrary.simpleMessage("Kenara ayrılan kaydın bir kopyası kaydedildi."),
    "quarantine_delete": MessageLookupByLibrary.simpleMessage("Sil"),
    "quarantine_delete_body": MessageLookupByLibrary.simpleMessage(
      "Uygulamanın bu sürümü bu kaydı okuyamıyor. Silme işlemi geri alınamaz.",
    ),
    "quarantine_delete_confirm": MessageLookupByLibrary.simpleMessage("Sil"),
    "quarantine_delete_title": MessageLookupByLibrary.simpleMessage("Kenara ayrılan kayıt silinsin mi?"),
    "quarantine_keep": MessageLookupByLibrary.simpleMessage("Kalsın"),
    "quarantine_kept_note": MessageLookupByLibrary.simpleMessage(
      "Önceki bir açılışta kayıtlı ilerleme okunamadı. Verileri bu cihazda olduğu gibi duruyor.",
    ),
    "quarantine_kept_readout": MessageLookupByLibrary.simpleMessage("KAYITLI BİR VERİ KENARA AYRILDI"),
    "quarantine_label": MessageLookupByLibrary.simpleMessage("Kayıt durumu"),
    "quarantine_malformed_note": MessageLookupByLibrary.simpleMessage(
      "Kayıt, uygulamanın bu sürümünün okuyabileceği bir biçimde değil. Silinmedi, bu cihazda olduğu gibi kenara kopyalandı ve üzerine hiçbir şey yazılmadı.",
    ),
    "quarantine_malformed_readout": MessageLookupByLibrary.simpleMessage(
      "UYGULAMANIN BU SÜRÜMÜ İLERLEMEYİ OKUYAMADI. OKUNMADI.",
    ),
    "quarantine_newer_note": MessageLookupByLibrary.simpleMessage(
      "Okumak için uygulamayı güncelle. Kayıt bu cihazda olduğu gibi duruyor.",
    ),
    "quarantine_newer_readout": MessageLookupByLibrary.simpleMessage(
      "İLERLEME, UYGULAMANIN DAHA YENİ BİR SÜRÜMÜYLE YAZILMIŞ. OKUNMADI.",
    ),
    "quarantine_save_copy": MessageLookupByLibrary.simpleMessage("Kopyasını kaydet"),
    "quiz_all_right": MessageLookupByLibrary.simpleMessage("Tüm cevaplar doğru"),
    "quiz_back_to_module": MessageLookupByLibrary.simpleMessage("Modüle dön"),
    "quiz_back_to_questions": MessageLookupByLibrary.simpleMessage("Sorulara dön"),
    "quiz_correct": MessageLookupByLibrary.simpleMessage("Doğru."),
    "quiz_done": MessageLookupByLibrary.simpleMessage("Bitti"),
    "quiz_list_count": m18,
    "quiz_list_engineers_only": m19,
    "quiz_list_taken": m20,
    "quiz_next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "quiz_progress": m21,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", doğru"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", yanlış"),
    "quiz_score_before": m22,
    "quiz_score_count": m23,
    "quiz_score_line": m24,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("doğru cevap"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("Sonuçları gör"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Baştan başla"),
    "quiz_subtitle": m25,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Bu modülle ilgili sorular"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage("Bu quiz açılamadı. Kapatıp daha sonra yeniden dene."),
    "quiz_wrong": m26,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Kısmen yazıldı"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Yalnızca bölüm planı"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Başlamadan önce"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Kapat"),
    "reader_completed_on": m27,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Modülü tamamlama"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("İçindekiler"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("Kursun sonu"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Bu modülü tamamlandı olarak işaretle"),
    "reader_minutes": m28,
    "reader_module_of": m29,
    "reader_next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage(
      "Bu modülün Herkes için sürümü henüz planlama aşamasında.",
    ),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("Neler yapabileceksin"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("Bu sayfada"),
    "reader_pager_planned": m30,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Mühendisler için sürümünü oku"),
    "reader_revision": m31,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Açıklama"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Madde"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Bölüm planı"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Bölümler"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("Herkes için yazılanlara bak"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Kursun başı"),
    "record_not_saved": m32,
    "record_not_saved_blocked": MessageLookupByLibrary.simpleMessage("uygulama dosyasına yazamadı"),
    "record_not_saved_quota": MessageLookupByLibrary.simpleMessage("bu cihazda yer kalmadı"),
    "record_not_saved_too_large": MessageLookupByLibrary.simpleMessage("kayıt, uygulamanın yazabileceğinden büyük"),
    "restore_confirm_effect": MessageLookupByLibrary.simpleMessage(
      "Geri yükleme, bunun yerine dosyadaki ilerlemeyi koyar.",
    ),
    "restore_confirm_holds": MessageLookupByLibrary.simpleMessage("Şu an bu cihazda:"),
    "restore_confirm_replace": MessageLookupByLibrary.simpleMessage("Değiştir"),
    "restore_confirm_title": MessageLookupByLibrary.simpleMessage("Bu cihazdaki ilerleme değiştirilsin mi?"),
    "settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
    "settings_about": MessageLookupByLibrary.simpleMessage("Hakkında"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("Güncellemeleri kontrol et"),
    "settings_content": MessageLookupByLibrary.simpleMessage("İçerik"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("Sürüm"),
    "settings_data": MessageLookupByLibrary.simpleMessage("İlerlemen"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Geliştirici konsolu"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Dil"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Lisanslar"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("Gizlilik ve yasal bilgiler"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Yayın tarihi"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("Okuma"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Güncellemeler kontrol ediliyor"),
    "settings_refresh_failed": m33,
    "settings_refresh_idle": MessageLookupByLibrary.simpleMessage("Uygulama açıldığından beri kontrol edilmedi"),
    "settings_refresh_needs_app_update": MessageLookupByLibrary.simpleMessage(
      "Yeni içerik, uygulamanın daha yeni bir sürümünü gerektiriyor. Almak için uygulamayı güncelle.",
    ),
    "settings_refresh_reason_checksum": MessageLookupByLibrary.simpleMessage(
      "indirilen bir dosya sağlama toplamıyla eşleşmedi",
    ),
    "settings_refresh_reason_format": MessageLookupByLibrary.simpleMessage(
      "web sitesi, uygulamanın bu sürümünün okuyamadığı içerik gönderdi",
    ),
    "settings_refresh_reason_http_status": MessageLookupByLibrary.simpleMessage("web sitesi bir hatayla yanıt verdi"),
    "settings_refresh_reason_network": MessageLookupByLibrary.simpleMessage("web sitesine bağlantı yok"),
    "settings_refresh_reason_storage": MessageLookupByLibrary.simpleMessage("uygulama depolama alanına yazamadı"),
    "settings_refresh_reason_stored": MessageLookupByLibrary.simpleMessage("kayıtlı içerik okunamadı"),
    "settings_refresh_up_to_date": MessageLookupByLibrary.simpleMessage("Güncel"),
    "settings_refresh_updated": MessageLookupByLibrary.simpleMessage("En son içeriğe güncellendi"),
    "settings_source": MessageLookupByLibrary.simpleMessage("Kaynak"),
    "settings_source_bundled": MessageLookupByLibrary.simpleMessage("Uygulamayla birlikte geldi"),
    "settings_source_downloaded": MessageLookupByLibrary.simpleMessage("Web sitesinden indirildi"),
    "settings_story": MessageLookupByLibrary.simpleMessage("Bazaar\'ın hikâyesi"),
    "settings_track": MessageLookupByLibrary.simpleMessage("Anlatım"),
    "track_engineers": MessageLookupByLibrary.simpleMessage("Mühendisler için"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("Herkes için"),
    "welcome_start": MessageLookupByLibrary.simpleMessage("Okumaya başla"),
    "welcome_story_continue": MessageLookupByLibrary.simpleMessage("Devam et"),
    "welcome_track_engineers": MessageLookupByLibrary.simpleMessage(
      "Teknik modüller: her parçanın nasıl çalıştığı, arkasındaki kod ve sayılarla.",
    ),
    "welcome_track_everyone": MessageLookupByLibrary.simpleMessage(
      "Aynı modüller, sade bir dille, teknik geçmişi olmayan okurlar için.",
    ),
    "welcome_track_lede": MessageLookupByLibrary.simpleMessage(
      "Dilini ve her modülün iki sürümünden birini seç. İkisini de istediğin zaman Ayarlar\'dan değiştirebilirsin.",
    ),
    "welcome_track_title": MessageLookupByLibrary.simpleMessage("Nasıl okumak istersin?"),
  };
}
