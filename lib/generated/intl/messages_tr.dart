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

  static String m0(robot, ground) => "${robot}, ${ground}";

  static String m1(language) => "${language} kodu";

  static String m2(number) => "ŞEKİL ${number}";

  static String m3(number) => "TABLO ${number}";

  static String m4(number) => "Tablo ${number}";

  static String m5(start, end) => "${start} ile ${end} arası";

  static String m6(start) => "${start} ve sonrası";

  static String m7(title) => "Kervan ${title} durağında";

  static String m8(index, count) => "Durak ${index} / ${count}";

  static String m9(level) => "Güç: 5 üzerinden ${level}";

  static String m10(count) => "${Intl.plural(count, one: '1 trend', other: '${count} trend')}";

  static String m11(minutes) => "${minutes} dk";

  static String m12(title) => "${title} modülünü tamamla";

  static String m13(approved, total) => "${approved}/${total}";

  static String m14(count) => "${Intl.plural(count, other: '${count} sonuç')}";

  static String m15(query) => "“${query}” için bir şey bulunamadı.";

  static String m16(count) => "ilk ${count} tanesi gösteriliyor";

  static String m17(day) => "Son yedek: ${day}";

  static String m18(seconds) =>
      "${Intl.plural(seconds, one: 'Sıfırlandı. 1 saniye içinde geri alabilirsin.', other: 'Sıfırlandı. ${seconds} saniye içinde geri alabilirsin.')}";

  static String m19(count) => "${Intl.plural(count, one: '1 modül durumu', other: '${count} modül durumu')}";

  static String m20(hours) => "~${hours} sa";

  static String m21(hours, minutes) => "~${hours} sa ${minutes} dk";

  static String m22(minutes) => "~${minutes} dk";

  static String m23(url) => "${url} açılamadı";

  static String m24(count, first) =>
      "Kurs, ${first} ile başlayan ${count} seviyeye ayrılır. İlkinden başla, hazır olduğunda bir sonrakine geç.";

  static String m25(percent) => "%${percent} okundu";

  static String m26(minutes, words) => "${minutes} dk · ${words} kelime";

  static String m27(approved, total) => "${approved}/${total} tamamlandı";

  static String m28(total) => "--/${total} tamamlandı";

  static String m29(count) => "${Intl.plural(count, one: '1 modül', other: '${count} modül')}";

  static String m30(count) => "${count} kelime biliyor";

  static String m31(level) => "Seviye ${level}";

  static String m32(value) => "kayıp ${value}";

  static String m33(count) => "${count} bitmiş modül bekliyor";

  static String m34(words) => "Diyor ki: ${words}";

  static String m35(level) => "Cep modeli, seviye ${level}. Sevmek için dokun.";

  static String m36(level) => "Seviye ${level}: artık daha çok şey söyleyebiliyor.";

  static String m37(level, items) => "Seviye ${level}. Gardırobunda yeni: ${items}.";

  static String m38(count, level) => "Seviye ${level} için ${count}";

  static String m39(count) => "${count} token";

  static String m40(count) => "${Intl.plural(count, one: '1 quiz', other: '${count} quiz')}";

  static String m41(taken, total) => "${total} quizden ${taken} tanesi çözüldü";

  static String m42(index, count) => "Soru ${index} / ${count}";

  static String m43(previous, best, total) => "Bir önceki: ${previous} / ${total}. En iyi: ${best} / ${total}.";

  static String m44(score, total) => "${score} / ${total}";

  static String m45(last, best, total) => "Son ${last} / ${total} · en iyi ${best} / ${total}";

  static String m46(count) => "Bu modülün ana noktalarına dair ${count} soru";

  static String m47(letter) => "Bu değil. Doğru cevap ${letter}.";

  static String m48(date) => "${date} tarihinde tamamlandı";

  static String m49(position, total) => "${total} eşleşmeden ${position}.";

  static String m50(minutes) => "${minutes} dk";

  static String m51(number, count) => "MODÜL ${number} / ${count}";

  static String m52(label) => "${label} · Planlandı";

  static String m53(hash, date) => "Rev. ${hash} · ${date}";

  static String m54(reason) => "Kaydedilmedi: ${reason}. Korumak için bir dosyaya yedekle.";

  static String m55(reason) => "Güncelleme kontrolü tamamlanmadı: ${reason}.";

  static String m56(name, level) => "${name}, ${level}. seviyede açılır";

  static String m57(name) => "${name}, giyili";

  static String m58(hat, head, body) => "Robot: ${hat}, ${head}, ${body}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about_close": MessageLookupByLibrary.simpleMessage("Kapat"),
    "about_english": MessageLookupByLibrary.simpleMessage("Hikâye İngilizce yazıldı."),
    "about_failed": MessageLookupByLibrary.simpleMessage(
      "Hikâye açılamadı. Güncellemeleri kontrol et, sonra yeniden aç.",
    ),
    "about_next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "about_previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "about_skip": MessageLookupByLibrary.simpleMessage("Geç"),
    "app_icon_cream": MessageLookupByLibrary.simpleMessage("Krem"),
    "app_icon_dark": MessageLookupByLibrary.simpleMessage("Koyu"),
    "app_icon_default": MessageLookupByLibrary.simpleMessage("Varsayılan"),
    "app_icon_ground": MessageLookupByLibrary.simpleMessage("Zemin"),
    "app_icon_name": m0,
    "app_icon_note_android": MessageLookupByLibrary.simpleMessage(
      "Yeni ikon, uygulamadan çıktığında ana ekrana gelir. Bazı telefonlar o sırada kısayolu ana ekrandan kaldırır; uygulama listesi yeni ikonu gösterir. Temalı simgeler açıksa telefon her ikonu kendi renkleriyle çizer.",
    ),
    "app_icon_note_ios": MessageLookupByLibrary.simpleMessage("Telefon yeni ikonu bir mesajla onaylar."),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "appearance_dark": MessageLookupByLibrary.simpleMessage("Koyu"),
    "appearance_light": MessageLookupByLibrary.simpleMessage("Açık"),
    "block_code_label": m1,
    "block_figure_caption": m2,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program çıktısı"),
    "block_table_caption": m3,
    "block_table_region": m4,
    "block_unknown": MessageLookupByLibrary.simpleMessage("Bu bölüm için uygulamanın daha yeni bir sürümü gerekiyor."),
    "caravan_all_trends": MessageLookupByLibrary.simpleMessage("Tüm trendler"),
    "caravan_all_years": MessageLookupByLibrary.simpleMessage("Tüm yıllar"),
    "caravan_hint": MessageLookupByLibrary.simpleMessage(
      "Yol almak için kartı kaydır, yolu sürükle ya da bir tezgâha dokun.",
    ),
    "caravan_in_course": MessageLookupByLibrary.simpleMessage("Kursta"),
    "caravan_next": MessageLookupByLibrary.simpleMessage("Sonraki durak"),
    "caravan_no_trend": MessageLookupByLibrary.simpleMessage("Eşleşen trend yok."),
    "caravan_period": m5,
    "caravan_period_open": m6,
    "caravan_previous": MessageLookupByLibrary.simpleMessage("Önceki durak"),
    "caravan_reading": MessageLookupByLibrary.simpleMessage("Okumalar"),
    "caravan_sample_articles": MessageLookupByLibrary.simpleMessage("Örnek makale"),
    "caravan_sample_badge": MessageLookupByLibrary.simpleMessage("Örnek"),
    "caravan_sample_notice": MessageLookupByLibrary.simpleMessage(
      "Örnek veri: Kervan hazırlanırken bu trendler yer tutucu.",
    ),
    "caravan_sample_repositories": MessageLookupByLibrary.simpleMessage("Örnek depo"),
    "caravan_sample_tools": MessageLookupByLibrary.simpleMessage("Örnek araç"),
    "caravan_sample_videos": MessageLookupByLibrary.simpleMessage("Örnek video"),
    "caravan_search": MessageLookupByLibrary.simpleMessage("Trendlerde ara"),
    "caravan_stage_label": m7,
    "caravan_stop_of": m8,
    "caravan_strength": MessageLookupByLibrary.simpleMessage("Güç"),
    "caravan_strength_of": m9,
    "caravan_strip_label": MessageLookupByLibrary.simpleMessage("Kervanın yeri"),
    "caravan_tour": MessageLookupByLibrary.simpleMessage("Yolu gez"),
    "caravan_tour_stop": MessageLookupByLibrary.simpleMessage("Geziyi durdur"),
    "caravan_trend_count": m10,
    "card_description": MessageLookupByLibrary.simpleMessage("Açıklama"),
    "card_length": MessageLookupByLibrary.simpleMessage("Süre"),
    "card_length_minutes": m11,
    "card_requires": MessageLookupByLibrary.simpleMessage("Ön koşul"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Yok"),
    "catalog_complete_module": m12,
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Tamamlananlar"),
    "catalog_level_dial": m13,
    "catalog_search_clear": MessageLookupByLibrary.simpleMessage("Aramayı temizle"),
    "catalog_search_count": m14,
    "catalog_search_hint": MessageLookupByLibrary.simpleMessage("Modüllerde ara"),
    "catalog_search_none": m15,
    "catalog_search_shown": m16,
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
    "data_back_up": MessageLookupByLibrary.simpleMessage("Yedekle"),
    "data_backed_up": m17,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "Yedek dosyası yazılamadı. Hiçbir şey yedeklendi olarak işaretlenmedi.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "İlerlemen yalnızca bu cihazda kayıtlı. Bir yedek dosyası, uygulamanın verileri silinirse ilerlemeni korur; onu başka bir cihaza ya da web sitesine taşımanı da sağlar.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Sıfırla"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Sıfırlandı. Geri alma süresi doldu."),
    "data_reset_counting": m18,
    "data_reset_not_finished": MessageLookupByLibrary.simpleMessage(
      "Sıfırlama tamamlanmadı: uygulama dosyalarını silemedi. Bu cihazdaki ilerlemen değişmedi.",
    ),
    "data_restore": MessageLookupByLibrary.simpleMessage("Geri yükle"),
    "data_restore_empty": MessageLookupByLibrary.simpleMessage(
      "Hiçbir şey değişmedi. Bu dosyada ilerleme yok; ilerleme yalnızca yedek dosyasında bulunur.",
    ),
    "data_restore_malformed": MessageLookupByLibrary.simpleMessage(
      "Bu dosya, uygulamanın ya da web sitesinin yazdığı bir yedek değil. Hiçbir şey değişmedi.",
    ),
    "data_restore_newer": MessageLookupByLibrary.simpleMessage(
      "Bu dosya, uygulamanın ya da web sitesinin daha yeni bir sürümüyle yazılmış. Uygulamayı güncelle, sonra dosyayı yeniden geri yükle.",
    ),
    "data_restore_not_done": MessageLookupByLibrary.simpleMessage(
      "Dosya geri yüklenmedi, çünkü bir sıfırlama sürüyordu. Yeniden dene.",
    ),
    "data_restore_too_large": MessageLookupByLibrary.simpleMessage(
      "Bu yedek, uygulamanın saklayabileceğinden büyük. Hiçbir şey değişmedi.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("Bu dosya açılamadı."),
    "data_restored": MessageLookupByLibrary.simpleMessage("Dosyadan geri yüklendi."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("BU CİHAZDA KAYITLI BİR ŞEY YOK"),
    "data_tally_states": m19,
    "data_undo": MessageLookupByLibrary.simpleMessage("Geri al"),
    "diagram_expand": MessageLookupByLibrary.simpleMessage("Diyagramı tam ekran aç"),
    "duration_hours": m20,
    "duration_hours_minutes": m21,
    "duration_minutes": m22,
    "erase_backup_statement": MessageLookupByLibrary.simpleMessage(
      "Cihaz yedeklerinden birinde ilerlemenin daha eski bir kopyası hâlâ bulunabilir.",
    ),
    "erase_confirm": MessageLookupByLibrary.simpleMessage("Bütün verileri sil"),
    "erase_field_label": MessageLookupByLibrary.simpleMessage("Onaylamak için SİL yaz"),
    "erase_keep": MessageLookupByLibrary.simpleMessage("Verilerimi koru"),
    "erase_mark": MessageLookupByLibrary.simpleMessage("Sil"),
    "erase_scope": MessageLookupByLibrary.simpleMessage(
      "Bu işlem kaydı bu cihazdan kaldırır. Uygulamanın okuyamadığı bir sürümden kalıp kenara ayrılan kopya da buna dahil.",
    ),
    "erase_scores": MessageLookupByLibrary.simpleMessage("Bu cihazdaki quiz skorları da silinir."),
    "erase_title": MessageLookupByLibrary.simpleMessage("Bu cihazdaki bütün ilerleme silinsin mi?"),
    "erase_word": MessageLookupByLibrary.simpleMessage("SİL"),
    "error_link_open_failed": m23,
    "feedback_failed": MessageLookupByLibrary.simpleMessage("Bildirim gönderilemedi. Daha sonra yeniden dene."),
    "feedback_field": MessageLookupByLibrary.simpleMessage("Ne oldu"),
    "feedback_intro": MessageLookupByLibrary.simpleMessage(
      "Neyin ters gittiğini yaz. Bildirim; uygulamanın sürümü, cihazın modeli ve sistemiyle birlikte Sentry\'ye gider, ad ya da e-posta gitmez. Uygulama içindeki e-postaları ve diğer kişisel ayrıntıları cihazdan çıkmadan önce gizler.",
    ),
    "feedback_send": MessageLookupByLibrary.simpleMessage("Gönder"),
    "feedback_sending": MessageLookupByLibrary.simpleMessage("Gönderiliyor"),
    "feedback_sent": MessageLookupByLibrary.simpleMessage("Bildirim gönderildi."),
    "feedback_title": MessageLookupByLibrary.simpleMessage("Sorun bildir"),
    "guide_complete": MessageLookupByLibrary.simpleMessage(
      "Bir modülü bitirince tamamlandı olarak işaretle. Katalog ne okuduğunu, Ana sayfa sırada ne olduğunu gösterir.",
    ),
    "guide_complete_title": MessageLookupByLibrary.simpleMessage("Bitirdiğini işaretle"),
    "guide_levels": m24,
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
    "home_continue": MessageLookupByLibrary.simpleMessage("Devam et"),
    "home_continue_reading": MessageLookupByLibrary.simpleMessage("Okumaya devam et"),
    "home_offline_body": MessageLookupByLibrary.simpleMessage(
      "Bağlantı olmadan da okunur. Uygulama her açılışta siteye daha yeni bir sürüm olup olmadığını sorar.",
    ),
    "home_offline_title": MessageLookupByLibrary.simpleMessage("Kurs bu cihazda"),
    "home_open_module": MessageLookupByLibrary.simpleMessage("Modülü aç"),
    "home_path": MessageLookupByLibrary.simpleMessage("Yolun"),
    "home_practice": MessageLookupByLibrary.simpleMessage("Pratik için quizler"),
    "home_practice_lede": MessageLookupByLibrary.simpleMessage("Tamamladığın modüllerin quizleri."),
    "home_read_percent": m25,
    "home_see_catalog": MessageLookupByLibrary.simpleMessage("Bütün kataloğu gör"),
    "home_up_next": MessageLookupByLibrary.simpleMessage("Sıradaki"),
    "image_expand": MessageLookupByLibrary.simpleMessage("Görseli tam ekran aç"),
    "image_replay": MessageLookupByLibrary.simpleMessage("Baştan oynat"),
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
    "length_minutes_words": m26,
    "level_completed": m27,
    "level_completed_pending": m28,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("Genel notlar"),
    "level_module_count": m29,
    "loading": MessageLookupByLibrary.simpleMessage("Yükleniyor"),
    "module_planned": MessageLookupByLibrary.simpleMessage("Planlandı"),
    "nav_caravan": MessageLookupByLibrary.simpleMessage("Kervan"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("Katalog"),
    "nav_home": MessageLookupByLibrary.simpleMessage("Ana sayfa"),
    "nav_quiz": MessageLookupByLibrary.simpleMessage("Quiz"),
    "nav_settings": MessageLookupByLibrary.simpleMessage("Ayarlar"),
    "not_found_message": MessageLookupByLibrary.simpleMessage(
      "Bu adres müfredattaki bir modüle ait değil. Modüllerin hepsi katalogda listeleniyor.",
    ),
    "not_found_title": MessageLookupByLibrary.simpleMessage("Böyle bir modül yok"),
    "open_on_the_web": MessageLookupByLibrary.simpleMessage("Web\'de aç"),
    "outfit_body_astronaut": MessageLookupByLibrary.simpleMessage("Uzay giysisi"),
    "outfit_body_classic": MessageLookupByLibrary.simpleMessage("Klasik"),
    "outfit_body_hoodie": MessageLookupByLibrary.simpleMessage("Kapüşonlu"),
    "outfit_body_kaftan": MessageLookupByLibrary.simpleMessage("Kaftan"),
    "outfit_body_lab_coat": MessageLookupByLibrary.simpleMessage("Laboratuvar önlüğü"),
    "outfit_body_suit": MessageLookupByLibrary.simpleMessage("Takım elbise ve papyon"),
    "outfit_body_vest": MessageLookupByLibrary.simpleMessage("İşlemeli yelek"),
    "outfit_hat_antenna": MessageLookupByLibrary.simpleMessage("Anten"),
    "outfit_hat_beanie": MessageLookupByLibrary.simpleMessage("Bere"),
    "outfit_hat_crown": MessageLookupByLibrary.simpleMessage("Taç"),
    "outfit_hat_fez": MessageLookupByLibrary.simpleMessage("Fes"),
    "outfit_hat_mortarboard": MessageLookupByLibrary.simpleMessage("Mezuniyet kepi"),
    "outfit_hat_top_hat": MessageLookupByLibrary.simpleMessage("Silindir şapka"),
    "outfit_hat_turban": MessageLookupByLibrary.simpleMessage("Sarık"),
    "outfit_hat_wizard": MessageLookupByLibrary.simpleMessage("Büyücü şapkası"),
    "outfit_head_classic": MessageLookupByLibrary.simpleMessage("Klasik ekran"),
    "outfit_head_dome": MessageLookupByLibrary.simpleMessage("Yuvarlak kafa"),
    "outfit_head_ears": MessageLookupByLibrary.simpleMessage("Kedi kulakları"),
    "outfit_head_tv": MessageLookupByLibrary.simpleMessage("Eski televizyon"),
    "outfit_head_visor": MessageLookupByLibrary.simpleMessage("Uzay kaskı"),
    "pocket_ask": MessageLookupByLibrary.simpleMessage("Konuştur"),
    "pocket_feed": MessageLookupByLibrary.simpleMessage("Token yedir"),
    "pocket_hallucinating": MessageLookupByLibrary.simpleMessage("halüsinasyon"),
    "pocket_known": m30,
    "pocket_lede": MessageLookupByLibrary.simpleMessage("Saçmalayabilen oyuncak bir model."),
    "pocket_level": m31,
    "pocket_level_word": MessageLookupByLibrary.simpleMessage("seviye"),
    "pocket_loss": m32,
    "pocket_loss_empty": MessageLookupByLibrary.simpleMessage("Eğri ilk beslemeyle başlar."),
    "pocket_loss_title": MessageLookupByLibrary.simpleMessage("Eğitim kaybı"),
    "pocket_read_module": MessageLookupByLibrary.simpleMessage("Bitirdiğin bir modülü okut"),
    "pocket_read_none": MessageLookupByLibrary.simpleMessage("Bir modülü bitirince onu da okuyabilir."),
    "pocket_read_waiting": m33,
    "pocket_reset": MessageLookupByLibrary.simpleMessage("Baştan başlat"),
    "pocket_reset_body": MessageLookupByLibrary.simpleMessage(
      "Okuduğu bütün tokenları unutur ve seviye 0\'dan yeniden başlar. Kurs ve ilerlemen olduğu gibi kalır.",
    ),
    "pocket_reset_keep": MessageLookupByLibrary.simpleMessage("Kalsın"),
    "pocket_reset_title": MessageLookupByLibrary.simpleMessage("Cep modeli baştan başlasın mı?"),
    "pocket_says": m34,
    "pocket_stage_label": m35,
    "pocket_status_asleep": MessageLookupByLibrary.simpleMessage("Uyuyor. Uyandırmak için dokun."),
    "pocket_status_cold": MessageLookupByLibrary.simpleMessage("Soğuk: her seferinde en olası sözcükleri söylüyor."),
    "pocket_status_hallucinating": MessageLookupByLibrary.simpleMessage(
      "Fazla sıcak: halüsinasyon görüyor. Sıcaklığı düşür.",
    ),
    "pocket_status_hungry": MessageLookupByLibrary.simpleMessage("Aç: saatlerdir beslenmedi."),
    "pocket_status_level_up": m36,
    "pocket_status_newborn": MessageLookupByLibrary.simpleMessage(
      "Yeni: henüz hiç sözcük bilmiyor. Ona biraz token yedir.",
    ),
    "pocket_status_overfit": MessageLookupByLibrary.simpleMessage(
      "Aşırı öğrendi: tokenları ezberledi ve onları tekrarlıyor. Birkaç saniye dinlensin.",
    ),
    "pocket_status_recovered": MessageLookupByLibrary.simpleMessage("Dinlendi, yeniden öğrenmeye hazır."),
    "pocket_status_unlocked": m37,
    "pocket_temperature": MessageLookupByLibrary.simpleMessage("Sıcaklık"),
    "pocket_title": MessageLookupByLibrary.simpleMessage("Cep modeli"),
    "pocket_to_next": m38,
    "pocket_tokens": m39,
    "pocket_top": MessageLookupByLibrary.simpleMessage("Tam eğitildi"),
    "privacy_contact": MessageLookupByLibrary.simpleMessage("Kişisel verilerle ilgili her soru için bize yaz."),
    "privacy_crash": MessageLookupByLibrary.simpleMessage(
      "Uygulama çöktüğünde, hatanın düzeltilebilmesi için Sentry\'ye bir çökme raporu gönderir. Uygulamanın sağlığını sürüm sürüm izlemek için ne zaman açılıp kapandığını, açılmasının ne kadar sürdüğünü ve ne zaman donduğunu da bu kuruluma ait rastgele bir numarayla Sentry\'ye bildirir. Bunların hiçbiri adını, ne okuduğunu ya da quiz cevaplarını içermez. Uygulama kişisel ayrıntıları cihazdan çıkmadan önce gizler; Sentry IP adresini saklamaz. Sorun bildir\'den gönderdiğin bir sorun da Sentry\'ye aynı şekilde gider.",
    ),
    "privacy_download": MessageLookupByLibrary.simpleMessage(
      "Uygulama kursu web sitesinden indirir; site GitHub Pages\'te barındırılır. GitHub, güvenlik için her ziyaretçinin IP adresini kaydeder ve saklar. Bu kayıt GitHub\'ındır, bizim değil.",
    ),
    "privacy_github_pages": MessageLookupByLibrary.simpleMessage("GitHub Pages nedir?"),
    "privacy_github_statement": MessageLookupByLibrary.simpleMessage("GitHub Genel Gizlilik Bildirimi"),
    "privacy_no_data": MessageLookupByLibrary.simpleMessage(
      "Bu uygulama kişisel veri toplamaz. Hesap, analiz aracı ve reklam yoktur.",
    ),
    "privacy_on_device": MessageLookupByLibrary.simpleMessage(
      "İlerlemen, quiz skorların ve ayarların yalnızca bu cihazda saklanır. Onları Ayarlar\'da İlerlemen bölümünden yedekleyebilir, geri yükleyebilir ya da silebilirsin.",
    ),
    "privacy_site_note": MessageLookupByLibrary.simpleMessage("Sitedeki gizlilik notu"),
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
    "quiz_list_count": m40,
    "quiz_list_taken": m41,
    "quiz_next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "quiz_progress": m42,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", doğru"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", yanlış"),
    "quiz_score_before": m43,
    "quiz_score_count": m44,
    "quiz_score_line": m45,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("doğru cevap"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("Sonuçları gör"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Baştan başla"),
    "quiz_subtitle": m46,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Bu modülle ilgili sorular"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage("Bu quiz açılamadı. Kapatıp daha sonra yeniden dene."),
    "quiz_wrong": m47,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Kısmen yazıldı"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Yalnızca bölüm planı"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Başlamadan önce"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Kapat"),
    "reader_completed_on": m48,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Modülü tamamlama"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("İçindekiler"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("Kursun sonu"),
    "reader_failed": MessageLookupByLibrary.simpleMessage(
      "Bu modül bu cihazda okunamadı. Yeniden dene ya da uygulamayı yeniden başlat.",
    ),
    "reader_find_close": MessageLookupByLibrary.simpleMessage("Arama işaretlerini kaldır"),
    "reader_find_next": MessageLookupByLibrary.simpleMessage("Sonraki eşleşme"),
    "reader_find_position": m49,
    "reader_find_previous": MessageLookupByLibrary.simpleMessage("Önceki eşleşme"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Bu modülü tamamlandı olarak işaretle"),
    "reader_minutes": m50,
    "reader_module_of": m51,
    "reader_next": MessageLookupByLibrary.simpleMessage("Sonraki"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage(
      "Bu modülün Herkes için sürümü henüz planlama aşamasında.",
    ),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("Neler yapabileceksin"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("Bu sayfada"),
    "reader_pager_planned": m52,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Önceki"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Mühendisler için sürümünü oku"),
    "reader_retry": MessageLookupByLibrary.simpleMessage("Yeniden dene"),
    "reader_revision": m53,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Açıklama"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Madde"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Bölüm planı"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Bölümler"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("Herkes için yazılanlara bak"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Kursun başı"),
    "record_not_saved": m54,
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
    "settings_app_icon": MessageLookupByLibrary.simpleMessage("App ikonu"),
    "settings_appearance": MessageLookupByLibrary.simpleMessage("Görünüm"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("Güncellemeleri kontrol et"),
    "settings_content": MessageLookupByLibrary.simpleMessage("İçerik"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("Sürüm"),
    "settings_customize": MessageLookupByLibrary.simpleMessage("Kişiselleştir"),
    "settings_data": MessageLookupByLibrary.simpleMessage("İlerlemen"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Geliştirici konsolu"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Dil"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Lisanslar"),
    "settings_pocket_button": MessageLookupByLibrary.simpleMessage("Cep modeli"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("Gizlilik ve yasal bilgiler"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Yayın tarihi"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("Okuma"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Güncellemeler kontrol ediliyor"),
    "settings_refresh_failed": m55,
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
    "settings_robot": MessageLookupByLibrary.simpleMessage("Gardırop"),
    "settings_source": MessageLookupByLibrary.simpleMessage("Kaynak"),
    "settings_source_bundled": MessageLookupByLibrary.simpleMessage("Uygulamayla birlikte geldi"),
    "settings_source_downloaded": MessageLookupByLibrary.simpleMessage("Web sitesinden indirildi"),
    "settings_story": MessageLookupByLibrary.simpleMessage("Bazaar\'ın hikâyesi"),
    "settings_track": MessageLookupByLibrary.simpleMessage("Anlatım"),
    "track_engineers": MessageLookupByLibrary.simpleMessage("Mühendisler için"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("Herkes için"),
    "wardrobe_body": MessageLookupByLibrary.simpleMessage("Gövde"),
    "wardrobe_hat": MessageLookupByLibrary.simpleMessage("Şapka"),
    "wardrobe_head": MessageLookupByLibrary.simpleMessage("Kafa"),
    "wardrobe_item_locked": m56,
    "wardrobe_item_worn": m57,
    "wardrobe_note": MessageLookupByLibrary.simpleMessage("Cep modelinin her seviyesi giyecek yeni bir şey açar."),
    "wardrobe_preview": m58,
    "welcome_start": MessageLookupByLibrary.simpleMessage("Öğrenmeye başla"),
    "welcome_story_continue": MessageLookupByLibrary.simpleMessage("Öğrenmeye başla"),
    "welcome_to_story": MessageLookupByLibrary.simpleMessage("Hikâyemiz"),
    "welcome_track_engineers": MessageLookupByLibrary.simpleMessage(
      "Teknik modüller: her parçanın nasıl çalıştığı, arkasındaki kod ve sayılarla.",
    ),
    "welcome_track_everyone": MessageLookupByLibrary.simpleMessage(
      "Aynı modüller, sade bir dille, teknik geçmişi olmayan okurlar için.",
    ),
    "welcome_track_title": MessageLookupByLibrary.simpleMessage("Nasıl okumak istersin?"),
  };
}
