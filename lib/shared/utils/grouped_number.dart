/// [n] with its thousands grouped as the web writes a word count in [lang] (web `groups` in `page-copy.ts`): a full
/// stop in Turkish, a comma otherwise, and the Latin digits in every language.
String groupedNumber(int n, String lang) =>
    '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => lang == 'tr' ? '.' : ',');
