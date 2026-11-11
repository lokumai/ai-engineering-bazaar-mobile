/// The owner of the course and the app, as the web prints it in its footer and on `/legend/#legal` (web D122,
/// `src/lib/site.ts` `SITE_OWNER`): the registered trade name, MERSİS number and address from the company's LEI record,
/// which MERSİS corroborates, and the email and phone of the company's contact page. Copied, since the bundle does not
/// carry them; a change on the web is a change here.
abstract final class SiteOwner {
  static const tradeName = 'İŞ ZEKASI YAZILIM DANIŞMANLIK HİZMETLERİ TİCARET ANONİM ŞİRKETİ';
  static const mersis = '0481058685800001';
  static const address =
      'Atatürk Mah Turgut Özal Bulvarı Gardenya 1 İş Merkezi No:42/b, Kat 1, Ataşehir, 34758 İstanbul, Türkiye';
  static const email = 'info@intellica.net';
  static const phone = '+90 216 688 45 46';
}

/// The pages the privacy note and the legal note point at, as the web links them (web `src/lib/site.ts`).
abstract final class LegalLinks {
  /// GitHub's own sentence that a Pages site logs every visitor's IP address.
  static final githubPages = Uri.parse(
    'https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages',
  );
  static final githubPrivacy = Uri.parse(
    'https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement',
  );
  static final licence = Uri.parse('https://github.com/lokumai/ai-engineering-bazaar/blob/main/LICENSE');
  static final email = Uri(scheme: 'mailto', path: SiteOwner.email);
  static final phone = Uri(scheme: 'tel', path: SiteOwner.phone.replaceAll(' ', ''));
}
