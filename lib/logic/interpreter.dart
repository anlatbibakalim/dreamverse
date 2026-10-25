import '../data/symbols.dart';

class Interpreter {
  // ============================================================
  // 1. DİL ANALİZİ
  // ============================================================

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokenize(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return [];

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static bool _containsAny(String text, List<String> patterns) {
    return patterns.any((pattern) => text.contains(pattern));
  }

  // ============================================================
  // 2. OLAY VE EYLEM SÖZLÜĞÜ
  //
  // Eşleştirmeler, olayları analiz etmek için kullanılır.
  // Bunlar tek başına kesin rüya anlamları değildir.
  // ============================================================

  static const Map<String, List<String>> _eylemler = {
    'yikama': [
      'yika', 'yikani', 'yikand', 'yikiyor',
      'yikad', 'yikan', 'yikamak',
    ],
    'kopma': [
      'kop', 'koptu', 'kopuyor', 'kopmus',
      'koparak', 'kopar', 'kopmas',
    ],
    'dusme': [
      'dus', 'dust', 'dusuyor', 'dusmus',
      'duserek', 'dusmek',
    ],
    'ucma': [
      'uc', 'uctu', 'ucuyor', 'ucmak',
      'ucarak',
    ],
    'kacma': [
      'kac', 'kacti', 'kaciyor', 'kacmak',
      'kacarak',
    ],
    'kovalanma': [
      'kovala', 'kovalani', 'kovaladi',
      'kovaliyordu', 'takip',
    ],
    'arama': [
      'ara', 'ariyor', 'aradim', 'aramak',
      'ararken',
    ],
    'bulma': [
      'bul', 'buldum', 'buldu', 'buluyor',
      'bulmak',
    ],
    'kaybetme': [
      'kaybet', 'kaybettim', 'kaybol',
      'kayboldum', 'kayboldu', 'kaybolmus',
    ],
    'aglama': [
      'agla', 'agladim', 'agliyor',
      'agliyordum', 'aglamak',
    ],
    'gulumseme': [
      'gulumse', 'guldum', 'guluyordum',
      'gulen', 'gulus',
    ],
    'konusma': [
      'konus', 'konustum', 'konusuyor',
      'konusmak', 'soyledi',
    ],
    'kavga': [
      'kavga', 'dovus', 'vurdu',
      'saldirdi', 'savas',
    ],
    'kurtulma': [
      'kurtul', 'kurtuldum', 'kurtardi',
      'kurtulmak',
    ],
    'olum': [
      'oldu', 'olum', 'olmus', 'olmek',
      'oldugunu',
    ],
    'dogum': [
      'dogdu', 'dogum', 'dogur',
      'bebek dog',
    ],
    'girme': [
      'girdim', 'girdi', 'giriyor',
      'girmek', 'icine girdim',
    ],
    'cikma': [
      'ciktim', 'cikti', 'cikiyor',
      'cikmak',
    ],
    'kirma': [
      'kirdi', 'kirdim', 'kirildi',
      'kiriliyor', 'kirmak',
    ],
    'kesme': [
      'kesti', 'kestim', 'kesildi',
      'kesiyor', 'kesmek',
    ],
    'kovma': [
      'kovdu', 'kovuldum', 'kovmak',
      'kovuyor',
    ],
  };

  // ============================================================
  // 3. DUYGULAR
  // ============================================================

  static const Map<String, List<String>> _duygular = {
    'korku': [
      'kork', 'dehset', 'panik', 'kabus',
      'urktum', 'endiseliyim', 'tehlike',
      'korkunc',
    ],
    'uzuntu': [
      'uzgun', 'uzuldum', 'uzuluyordum',
      'agladim', 'agliyordum', 'huzun',
      'aci cektim',
    ],
    'mutluluk': [
      'mutlu', 'sevindim', 'sevincli',
      'neseli', 'keyifli', 'guldum',
    ],
    'huzur': [
      'huzur', 'rahatladim', 'sakindim',
      'guvende', 'icim rahatti',
    ],
    'ofke': [
      'sinirlendim', 'ofkeliydim',
      'kizdim', 'nefret', 'ofke',
    ],
    'saskinlik': [
      'sasirdim', 'saskindim',
      'inanamadim', 'hayret',
    ],
    'tiksinme': [
      'igrendim', 'tiksindim',
      'mide bulantisi',
    ],
  };

  static const Map<String, List<String>> _olumsuzluklar = {
    'korku': ['korkmadim', 'korkmuyordum', 'korkmuyorum'],
    'uzuntu': ['uzulmedim', 'aglamadim'],
    'mutluluk': ['sevinmedim', 'mutlu degildim'],
    'huzur': ['rahat degildim', 'huzursuzdum'],
  };

  // ============================================================
  // 4. KELİME VE BAĞLAM EŞLEŞTİRMESİ
  // ============================================================

  static bool _kelimeEslesir(
    String kelime,
    String anahtar,
  ) {
    final k = _normalize(kelime);
    final a = _normalize(anahtar);

    if (k.isEmpty || a.isEmpty) return false;
    if (k == a) return true;

    // Türkçe ek almış kelimeler.
    // Kısa kelimelerde gelişigüzel iç eşleşme yapılmaz.
    if (a.length >= 3 && k.startsWith(a)) return true;

    return false;
  }

  static bool _ifadeVar(
    String metin,
    List<String> ifadeler,
  ) {
    final kelimeler = _tokenize(metin);

    for (final ifade in ifadeler) {
      final ifadeKelimeleri = _tokenize(ifade);
      if (ifadeKelimeleri.isEmpty) continue;

      for (int i = 0;
          i <= kelimeler.length - ifadeKelimeleri.length;
          i++) {
        bool eslesti = true;

        for (int j = 0; j < ifadeKelimeleri.length; j++) {
          if (!_kelimeEslesir(
            kelimeler[i + j],
            ifadeKelimeleri[j],
          )) {
            eslesti = false;
            break;
          }
        }

        if (eslesti) return true;
      }
    }

    return false;
  }

  static List<String> _tespitEt(
    String metin,
    Map<String, List<String>> sozluk,
  ) {
    final bulunanlar = <String>[];

    for (final entry in sozluk.entries) {
      if (_ifadeVar(metin, entry.value)) {
        bulunanlar.add(entry.key);
      }
    }

    return bulunanlar;
  }

  // ============================================================
  // 5. SEMBOL TESPİTİ
  // ============================================================

  static List<Ruyasembolu> _sembolleriBul(String metin) {
    final bulunanlar = <Ruyasembolu>[];
    final anahtarlar = <String>{};
    final kelimeler = _tokenize(metin);

    for (final sembol in tumSemboller) {
      final anahtar = _normalize(sembol.anahtar);

      if (anahtarlar.contains(anahtar)) continue;

      final eslesmeler = <String>[
        sembol.anahtar,
        ...sembol.eslesenKelimeler,
      ];

      bool bulundu = false;

      for (final eslesme in eslesmeler) {
        final aranacak = _tokenize(eslesme);

        if (aranacak.isEmpty) continue;

        for (int i = 0;
            i <= kelimeler.length - aranacak.length;
            i++) {
          bool eslesti = true;

          for (int j = 0; j < aranacak.length; j++) {
            if (!_kelimeEslesir(
              kelimeler[i + j],
              aranacak[j],
            )) {
              eslesti = false;
              break;
            }
          }

          if (eslesti) {
            bulundu = true;
            break;
          }
        }

        if (bulundu) break;
      }

      if (bulundu) {
        bulunanlar.add(sembol);
        anahtarlar.add(anahtar);
      }
    }

    return bulunanlar;
  }

  // ============================================================
  // 6. OLAYLAR ARASINDAKİ İLİŞKİLER
  //
  // Bu bölüm rüyanın bütününü değerlendirmeye çalışır.
  // ============================================================

  static List<String> _iliskileriAnalizEt({
    required String metin,
    required List<String> eylemler,
    required List<String> duygular,
    required List<Ruyasembolu> semboller,
  }) {
    final sonuc = <String>[];
    final normal = _normalize(metin);

    final eylemSeti = eylemler.toSet();
    final duyguSeti = duygular.toSet();

    // Bir olay sırasında kayıp veya zarar oluşması.
    if (eylemSeti.contains('yikama') &&
        eylemSeti.contains('kopma')) {
      sonuc.add(
        'Rüyada temizlenme veya yenilenme çağrışımı yapan '
        'bir eylem ile kayıp görüntüsü aynı olayda birleşiyor. '
        'Bu karşıtlık, bir değişim isteğiyle bir şeyi kaybetme '
        'endişesinin birlikte düşünülmesini mümkün kılıyor.',
      );
    }

    // Tehdit ve kaçış.
    if (eylemSeti.contains('kovalanma') &&
        eylemSeti.contains('kacma')) {
      sonuc.add(
        'Takip edilme ve kaçma olayları birlikte görülüyor. '
        'Bu, rüya bağlamında baskı altında hissetme veya '
        'bir sorunla yüzleşememe ihtimali üzerinden incelenebilir.',
      );
    }

    // Kayıp ve üzüntü.
    if ((eylemSeti.contains('kaybetme') ||
            eylemSeti.contains('kopma')) &&
        duyguSeti.contains('uzuntu')) {
      sonuc.add(
        'Kayıp görüntüsü ile üzüntü aynı anlatıda yer alıyor. '
        'Bu nedenle yorumda yalnızca değişim değil, '
        'kaybedilen şeyin duygusal önemi de dikkate alınmalı.',
      );
    }

    // Korku ve kurtuluş.
    if (duyguSeti.contains('korku') &&
        eylemSeti.contains('kurtulma')) {
      sonuc.add(
        'Rüyada korku ile kurtulma birlikte bulunuyor. '
        'Bu durum yalnızca tehdit hissini değil, '
        'tehlikeden uzaklaşma veya rahatlama temasını da '
        'değerlendirmeyi gerektiriyor.',
      );
    }

    // Düşme ve korku.
    if (eylemSeti.contains('dusme') &&
        duyguSeti.contains('korku')) {
      sonuc.add(
        'Düşme olayı korkuyla birlikte anlatılmış. '
        'Bu bağlamda güvensizlik veya kontrol kaybı ihtimali '
        'değerlendirilebilir; ancak tek başına kesin bir '
        'anlam çıkarılamaz.',
      );
    }

    // Tehdit ve huzur gibi karşıt duygular.
    if (duyguSeti.contains('korku') &&
        (duyguSeti.contains('huzur') ||
            duyguSeti.contains('mutluluk'))) {
      sonuc.add(
        'Rüyada hem olumsuz hem olumlu duygulara işaret eden '
        'ifadeler var. Bu, rüyanın tek bir duyguya '
        'indirgenmemesi gerektiğini gösteriyor.',
      );
    }

    // Sembol ve olay ilişkileri için genel kontrol.
    if (semboller.length >= 2) {
      sonuc.add(
        'Rüyada birden fazla sembol bulunuyor. Bunları '
        'birbirinden bağımsız yorumlamak yerine, hangi '
        'olayın içinde yer aldıklarını ve anlatıda nasıl '
        'bir araya geldiklerini değerlendirmek gerekir.',
      );
    }

    // Genel bağlam, yalnızca belirli kuralların çalışmasına bağlı değil.
    if (sonuc.isEmpty && normal.isNotEmpty) {
      sonuc.add(
        'Mevcut kurallarla belirgin bir olay ilişkisi '
        'kurulamadı. Bu nedenle sembollerin anlamlarını '
        'kesin bir sonuca dönüştürmek yerine, rüyanın '
        'anlatılan ayrıntıları üzerinden değerlendirmek gerekir.',
      );
    }

    return sonuc;
  }

  // ============================================================
  // 7. DUYGU ANALİZİ
  // ============================================================

  static String _duyguOzeti(
    List<String> duygular,
    String metin,
  ) {
    if (duygular.isEmpty) {
      return 'Rüyanızda hissettiğiniz duygu açıkça '
          'belirtilmediği için duygusal tonunu kesinleştiremiyorum.';
    }

    final aciklamalar = <String, String>{
      'korku': 'korku veya tedirginlik',
      'uzuntu': 'üzüntü veya kayıp hissi',
      'mutluluk': 'mutluluk veya sevinç',
      'huzur': 'huzur veya rahatlama',
      'ofke': 'öfke veya kızgınlık',
      'saskinlik': 'şaşkınlık',
      'tiksinme': 'tiksinme',
    };

    final tespitEdilenler = duygular
        .map((duygu) => aciklamalar[duygu])
        .whereType<String>()
        .toList();

    return 'Metninizde şu duygulara işaret eden ifadeler '
        'bulunuyor: ${tespitEdilenler.join(", ")}. '
        'Bu tespit, yalnızca yazdığınız ifadelerin '
        'dilsel analizine dayanıyor.';
  }

  // ============================================================
  // 8. ANA YORUMLAMA MOTORU
  // ============================================================

  static String yorumla(String metin) {
    if (metin.trim().isEmpty) {
      return 'Lütfen yorumlamamı istediğiniz rüyayı anlatın.';
    }

    final semboller = _sembolleriBul(metin);
    final eylemler = _tespitEt(metin, _eylemler);
    final duygular = _tespitEt(metin, _duygular);

    final buffer = StringBuffer();

    buffer.writeln('RÜYANIN GENEL ANALİZİ\n');

    buffer.writeln(_duyguOzeti(duygular, metin));
    buffer.writeln();

    // Sembolleri ve eylemleri birbirinden ayır.
    if (semboller.isNotEmpty) {
      buffer.writeln('RÜYADA TESPİT EDİLEN SEMBOLLER\n');

      for (final sembol in semboller) {
        buffer.writeln('• ${sembol.anahtar}');
        buffer.writeln(sembol.yorum);
        buffer.writeln();
      }
    }

    if (eylemler.isNotEmpty) {
      buffer.writeln('RÜYADAKİ EYLEMLER\n');

      buffer.writeln(
        'Anlatınızda şu eylemlere işaret eden ifadeler '
        'bulunuyor: ${eylemler.join(", ")}.',
      );

      buffer.writeln();
    }

    // Olay ilişkilerini birlikte değerlendir.
    final iliskiler = _iliskileriAnalizEt(
      metin: metin,
      eylemler: eylemler,
      duygular: duygular,
      semboller: semboller,
    );

    buffer.writeln('BÜTÜNSEL DEĞERLENDİRME\n');

    for (final iliski in iliskiler) {
      buffer.writeln('• $iliski');
      buffer.writeln();
    }

    // Kullanıcıya özgü yorum için eksik bilgileri belirle.
    buffer.writeln('KİŞİSEL BAĞLAM\n');

    if (duygular.isEmpty) {
      buffer.writeln(
        'Bu rüyayı daha iyi değerlendirmek için '
        'rüya sırasında ne hissettiğinizi bilmek isterim.',
      );
    } else if (semboller.isEmpty) {
      buffer.writeln(
        'Anlatınızda mevcut sembol veritabanıyla '
        'eşleştirebildiğim bir sembol bulunmadı. '
        'Bu, rüyanızın anlamsız olduğu anlamına gelmez.',
      );
    } else {
      buffer.writeln(
        'Bu rüyanın sizin için ne ifade ettiğini '
        'anlamak için, rüyadaki olayların gerçek '
        'yaşamınızda size ne çağrıştırdığını düşünmek '
        'yararlı olabilir.',
      );
    }

    buffer.writeln();

    buffer.writeln('SONUÇ\n');

    buffer.writeln(
      'Bu değerlendirme, metninizden tespit edilen '
      'sembollere, eylemlere ve duygu ifadelerine '
      'dayanan yerel bir kural tabanlı analizdir. '
      'Olası anlamları düşünmenize yardımcı olabilir; '
      'kesin bir kehanet veya psikolojik teşhis değildir.',
    );

    return buffer.toString().trim();
  }
}
