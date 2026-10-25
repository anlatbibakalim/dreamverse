import '../data/symbols.dart';

class Interpreter {
  // =========================================================
  // 1. TÜRKÇE METİN İŞLEME
  // =========================================================

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _words(String text) {
    final normalized = _normalize(text);

    if (normalized.isEmpty) return [];

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static bool _matches(String word, String root) {
    final w = _normalize(word);
    final r = _normalize(root);

    if (w.isEmpty || r.isEmpty) return false;
    if (w == r) return true;

    // Kısa kelimelerde yanlış eşleşmeleri azalt.
    if (r.length < 3) return false;

    // Türkçe kelime eklerini kısmen destekle.
    return w.startsWith(r);
  }

  static bool _hasPhrase(
    List<String> words,
    List<String> phrases,
  ) {
    for (final phrase in phrases) {
      final parts = _words(phrase);

      if (parts.isEmpty || parts.length > words.length) {
        continue;
      }

      for (int i = 0; i <= words.length - parts.length; i++) {
        bool match = true;

        for (int j = 0; j < parts.length; j++) {
          if (!_matches(words[i + j], parts[j])) {
            match = false;
            break;
          }
        }

        if (match) return true;
      }
    }

    return false;
  }

  // =========================================================
  // 2. OLAY TESPİTİ
  // =========================================================

  static const Map<String, List<String>> _eventPatterns = {
    'sac_yikama': [
      'saçımı yıkıyorum',
      'saçlarımı yıkıyorum',
      'saçımı yıkadım',
      'saçlarımı yıkadım',
      'saçımı yıkarken',
      'saçlarımı yıkarken',
      'saç yıkamak',
      'saç yıkıyorum',
    ],
    'sac_dokulmesi': [
      'saçım dökülüyor',
      'saçlarım dökülüyor',
      'saçım döküldü',
      'saçlarım döküldü',
      'saçlarım kopuyor',
      'saçlarım koptu',
      'saçım kopuyor',
      'saçım koptu',
      'saçlarım kopup elime geldi',
      'saçlarım tutam tutam kopuyor',
      'saçlarım tutam tutam dökülüyor',
    ],
    'dis_dokulmesi': [
      'dişim düştü',
      'dişim döküldü',
      'dişlerim döküldü',
      'dişlerim dökülüyor',
    ],
    'kovalanma': [
      'kovalanıyorum',
      'beni kovalıyor',
      'beni takip ediyor',
      'peşimden geliyor',
    ],
    'dusme': [
      'yere düştüm',
      'yüksekten düştüm',
      'düşüyorum',
      'uçurumdan düştüm',
    ],
    'ucma': [
      'uçuyorum',
      'uçtum',
      'havada uçuyordum',
    ],
    'kacma': [
      'kaçıyorum',
      'kaçtım',
      'kaçıp kurtuldum',
    ],
    'yilan_oldurme': [
      'yılanı öldürdüm',
      'yılan öldürdüm',
      'yılanı öldürüyorum',
    ],
    'aglama': [
      'ağlıyorum',
      'ağladım',
      'ağlayarak',
    ],
    'birini_kaybetme': [
      'annemi kaybettim',
      'babamı kaybettim',
      'arkadaşımı kaybettim',
      'eşimi kaybettim',
    ],
  };

  static List<String> _detectEvents(List<String> words) {
    final events = <String>[];

    for (final entry in _eventPatterns.entries) {
      if (_hasPhrase(words, entry.value)) {
        events.add(entry.key);
      }
    }

    return events;
  }

  // =========================================================
  // 3. DUYGU ANALİZİ
  // =========================================================

  static const Map<String, List<String>> _emotionPatterns = {
    'korku': [
      'korktum',
      'korkuyorum',
      'korkuyordum',
      'dehşete düştüm',
      'panikledim',
      'ürktüm',
    ],
    'üzüntü': [
      'üzüldüm',
      'üzgündüm',
      'hüzünlendim',
      'çok ağladım',
    ],
    'mutluluk': [
      'mutluydum',
      'çok mutlu oldum',
      'sevindim',
      'çok sevindim',
    ],
    'huzur': [
      'huzurluydum',
      'rahatlamıştım',
      'kendimi güvende hissettim',
    ],
    'şaşkınlık': [
      'şaşırdım',
      'çok şaşırdım',
      'hayrete düştüm',
    ],
    'öfke': [
      'sinirlendim',
      'çok öfkeliydim',
      'kızgındım',
    ],
  };

  static const Map<String, List<String>> _negativeEmotionPatterns = {
    'korku': [
      'korkmadım',
      'korkmuyordum',
      'korkmuyorum',
    ],
    'üzüntü': [
      'üzülmedim',
      'ağlamadım',
    ],
    'mutluluk': [
      'mutlu değildim',
      'sevinmedim',
    ],
    'huzur': [
      'huzurlu değildim',
      'rahat değildim',
    ],
  };

  static List<String> _detectEmotions(
    List<String> words,
    String originalText,
  ) {
    final emotions = <String>[];

    for (final entry in _emotionPatterns.entries) {
      final negatives = _negativeEmotionPatterns[entry.key] ?? [];

      // "Korkmadım" ifadesini "korktum" olarak yorumlama.
      if (_hasPhrase(words, negatives)) continue;

      if (_hasPhrase(words, entry.value)) {
        emotions.add(entry.key);
      }
    }

    return emotions;
  }

  // =========================================================
  // 4. SEMBOL TESPİTİ
  // =========================================================

  static List<Ruyasembolu> _detectSymbols(
    List<String> words,
  ) {
    final results = <Ruyasembolu>[];
    final foundKeys = <String>{};

    for (final symbol in tumSemboller) {
      final candidates = <String>[
        symbol.anahtar,
        ...symbol.eslesenKelimeler,
      ];

      bool found = false;

      for (final candidate in candidates) {
        if (_hasPhrase(words, [candidate])) {
          found = true;
          break;
        }
      }

      if (found && foundKeys.add(symbol.anahtar)) {
        results.add(symbol);
      }
    }

    return results;
  }

  // =========================================================
  // 5. BAĞLAM ANALİZİ
  // =========================================================

  static List<String> _analyzeContext({
    required List<String> events,
    required List<String> emotions,
    required List<Ruyasembolu> symbols,
  }) {
    final results = <String>[];

    final eventSet = events.toSet();
    final emotionSet = emotions.toSet();

    // Saç yıkama ve saç dökülmesi aynı olay zincirinde.
    if (eventSet.contains('sac_yikama') &&
        eventSet.contains('sac_dokulmesi')) {
      results.add(
        'Rüyanın merkezinde saç yıkama sırasında saçların '
        'kopması bulunuyor. Burada yalnızca saç sembolü '
        'değil, yenilenme veya temizlenme çağrışımı yapan '
        'eylem ile kayıp görüntüsü arasındaki ilişki de '
        'önemli. Bu durum değişim isteğiyle kaybetme '
        'endişesinin birlikte değerlendirilmesine imkân '
        'verebilir; ancak tek başına kesin bir anlam taşımaz.',
      );
    }

    // Yılan görmek ile yılan öldürmek aynı değildir.
    if (eventSet.contains('yilan_oldurme')) {
      results.add(
        'Rüyada yılanı öldürme eylemi anlatılmış. '
        'Bu nedenle yalnızca yılan sembolünün genel '
        'yorumuna dayanmak yerine, rüyadaki eylemi ve '
        'sonrasında ne olduğunu değerlendirmek gerekir.',
      );
    }

    if (eventSet.contains('kovalanma') &&
        eventSet.contains('kacma')) {
      results.add(
        'Takip edilme ve kaçma birlikte görülüyor. '
        'Bu olay dizisi, rüya bağlamında baskı altında '
        'hissetme veya bir sorundan uzaklaşma ihtimali '
        'üzerinden düşünülebilir.',
      );
    }

    if (eventSet.contains('dusme') &&
        emotionSet.contains('korku')) {
      results.add(
        'Düşme olayı korkuyla birlikte anlatılmış. '
        'Bu, kontrol kaybı veya güvensizlik hissiyle '
        'ilişkili olabilir; fakat kişisel bağlam '
        'bilinmeden kesin sonuca varılamaz.',
      );
    }

    if (emotionSet.contains('korku') &&
        emotionSet.contains('mutluluk')) {
      results.add(
        'Rüyada korku ve mutluluğa işaret eden '
        'ifadeler birlikte bulunuyor. Bu nedenle '
        'rüyanın duygusal tonunu tek bir duyguya '
        'indirgememek gerekir.',
      );
    }

    if (symbols.length >= 2 && results.isEmpty) {
      results.add(
        'Birden fazla sembol tespit edildi. Ancak '
        'mevcut kurallar bu semboller arasında özel '
        'bir ilişki belirleyemedi. Sadece birlikte '
        'görünmelerinden kesin bir anlam çıkarılmamalı.',
      );
    }

    if (results.isEmpty) {
      results.add(
        'Mevcut olay kuralları bu rüya için özgün '
        'bir ilişki belirleyemedi. Bu, rüyanın '
        'anlamsız olduğu anlamına gelmez; yorum için '
        'daha fazla olay ayrıntısı gerekebilir.',
      );
    }

    return results;
  }

  // =========================================================
  // 6. ANA YORUMLAMA MOTORU
  // =========================================================

  static String yorumla(String metin) {
    if (metin.trim().isEmpty) {
      return 'Lütfen rüyanızı anlatın.';
    }

    final words = _words(metin);

    final events = _detectEvents(words);
    final emotions = _detectEmotions(words, metin);
    final symbols = _detectSymbols(words);

    final context = _analyzeContext(
      events: events,
      emotions: emotions,
      symbols: symbols,
    );

    final buffer = StringBuffer();

    buffer.writeln('RÜYANIN BÜTÜNSEL ANALİZİ\n');

    // A. Olaylar
    if (events.isNotEmpty) {
      buffer.writeln('Rüyada tespit edilen olaylar:');

      for (final event in events) {
        buffer.writeln('• ${_eventName(event)}');
      }

      buffer.writeln();
    }

    // B. Duygular
    buffer.writeln('DUYGUSAL ANALİZ\n');

    if (emotions.isEmpty) {
      buffer.writeln(
        'Rüyanızdaki duygular açıkça belirtilmemiş. '
        'Bu nedenle korku, huzur veya üzüntü hissettiğinizi '
        'varsaymıyorum.',
      );
    } else {
      buffer.writeln(
        'Anlatımınızda şu duygulara işaret eden ifadeler '
        'bulunuyor: ${emotions.join(', ')}.',
      );

      buffer.writeln(
        'Bu tespit yazdığınız ifadelerle sınırlıdır; '
        'duygularınızın tamamını bildiğim anlamına gelmez.',
      );
    }

    buffer.writeln();

    // C. Semboller
    buffer.writeln('SEMBOLLER\n');

    if (symbols.isEmpty) {
      buffer.writeln(
        'Bilinen sembollerle güvenilir bir eşleşme '
        'kurulamadı. Buna rağmen rüyanızdaki olaylar '
        'anlamlı ayrıntılar içerebilir.',
      );
    } else {
      for (final symbol in symbols) {
        // Saç kesmek hakkındaki yorumu, saç dökülmesi
        // rüyasına doğrudan uygulama.
        if (_normalize(symbol.anahtar) == 'sac' &&
            events.contains('sac_dokulmesi')) {
          buffer.writeln('• SAÇ');

          buffer.writeln(
            'Bu rüyada saç kesilmekten ziyade saçların '
            'kopması veya dökülmesi anlatılıyor. Bu '
            'nedenle saç kesmeye ilişkin geleneksel '
            'yorum bu olaya doğrudan uygulanmamalıdır.',
          );
        } else {
          buffer.writeln('• ${symbol.anahtar.toUpperCase()}');
          buffer.writeln(symbol.yorum);
        }

        buffer.writeln();
      }
    }

    // D. Olaylar arası ilişki
    buffer.writeln('OLAYLAR ARASINDAKİ İLİŞKİ\n');

    for (final item in context) {
      buffer.writeln('• $item\n');
    }

    // E. Kişisel bağlam
    buffer.writeln('KİŞİSEL DEĞERLENDİRME\n');

    if (emotions.isEmpty) {
      buffer.writeln(
        'Rüya sırasında ne hissettiğiniz yorumu '
        'değiştirebilir. Örneğin korku, rahatlama veya '
        'şaşkınlık yaşadınız mı?',
      );
    } else {
      buffer.writeln(
        'Rüyadaki olayların sizin için ne ifade ettiğini '
        'anlamak için şu soruyu düşünebilirsiniz: '
        'Bu olay size gerçek yaşamınızda yaşadığınız '
        'bir değişimi, endişeyi veya anıyı çağrıştırıyor mu?',
      );
    }

    buffer.writeln();

    buffer.writeln('ÖNEMLİ NOT\n');

    buffer.writeln(
      'Bu yorum, cihaz üzerinde çalışan kural tabanlı '
      'bir analizdir. Rüyaların geleceği haber verdiği '
      'kanıtlanmış değildir. Geleneksel sembol yorumları '
      'kesin dini hükümler veya kişisel geleceğe dair '
      'kanıtlar olarak değerlendirilmemelidir.',
    );

    return buffer.toString().trim();
  }

  static String _eventName(String event) {
    const names = {
      'sac_yikama': 'Saç yıkama',
      'sac_dokulmesi': 'Saçların dökülmesi veya kopması',
      'dis_dokulmesi': 'Dişlerin dökülmesi',
      'kovalanma': 'Takip edilme',
      'dusme': 'Düşme',
      'ucma': 'Uçma',
      'kacma': 'Kaçma',
      'yilan_oldurme': 'Yılan öldürme',
      'aglama': 'Ağlama',
      'birini_kaybetme': 'Yakın birini kaybetme',
    };

    return names[event] ?? event;
  }
}
