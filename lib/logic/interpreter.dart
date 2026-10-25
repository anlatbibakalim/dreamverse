import '../data/symbols.dart';

class Interpreter {
  // =========================================================
  // 1. METİN İŞLEME
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
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _words(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return [];
    return normalized.split(' ');
  }

  static List<String> _sentences(String text) {
    return text
        .split(RegExp(r'[.!?;\n]+'))
        .map(_normalize)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Kısa ve belirsiz kökler kesin eşleşme ister.
  // Uzun köklerde sınırlı ek toleransı uygulanır.
  static bool _matches(String word, String root) {
    final w = _normalize(word);
    final r = _normalize(root);

    if (w.isEmpty || r.isEmpty) return false;
    if (w == r) return true;

    // "kör" kelimesinin "korktum" ile karışmasını engelle.
    if (r == 'kor') return false;

    if (r.length < 4) return false;

    return w.startsWith(r) && w.length <= r.length + 6;
  }

  static bool _phraseAt(
    List<String> words,
    List<String> phrase,
    int start,
  ) {
    if (phrase.isEmpty || start + phrase.length > words.length) {
      return false;
    }

    for (var i = 0; i < phrase.length; i++) {
      if (!_matches(words[start + i], phrase[i])) {
        return false;
      }
    }

    return true;
  }

  static List<int> _findPhraseStarts(
    List<String> words,
    List<String> phrases,
  ) {
    final starts = <int>{};

    for (final phrase in phrases) {
      final parts = _words(phrase);
      if (parts.isEmpty || parts.length > words.length) continue;

      for (var i = 0; i <= words.length - parts.length; i++) {
        if (_phraseAt(words, parts, i)) {
          starts.add(i);
        }
      }
    }

    return starts.toList()..sort();
  }

  static bool _hasPhrase(
    List<String> words,
    List<String> phrases,
  ) {
    return _findPhraseStarts(words, phrases).isNotEmpty;
  }

  // =========================================================
  // 2. OLUMSUZLUK VE İFADE YÖNÜ
  // =========================================================

  static const List<String> _negationWords = [
    'degil',
    'degildi',
    'degildim',
    'degildik',
    'yok',
    'yoktu',
    'hic',
    'asla',
    'hayir',
  ];

  static const List<String> _contrastWords = [
    'ama',
    'fakat',
    'ancak',
    'oysa',
    'oysa ki',
    'aksine',
    'buna ragmen',
  ];

  static const List<String> _temporalWords = [
    'sonra',
    'ardindan',
    'nihayet',
    'derken',
    'sonrasinda',
  ];

  static bool _isNegatedAt(
    List<String> words,
    int start,
    int length,
  ) {
    // Önce olayın yakın çevresindeki olumsuzluğu kontrol et.
    final from = (start - 3).clamp(0, words.length);
    final to = (start + length).clamp(0, words.length);
    final nearby = words.sublist(from, to);

    if (nearby.any(_negationWords.contains)) return true;

    // Türkçede bazı olumsuzluklar fiilin içinde bulunur:
    // görmedim, düşmedi, ağlamadım, öldürmedim.
    // Bu fiiller pozitif kalıplarla eşleştirilmediği için
    // ayrıca olumsuz olay sözlüğünde ele alınırlar.
    return false;
  }

  static bool _hasNegatedExpression(
    List<String> words,
    List<String> phrases,
  ) {
    return _hasPhrase(words, phrases);
  }

  // =========================================================
  // 3. OLAY SÖZLÜĞÜ
  // =========================================================

  static const Map<String, List<String>> _eventPatterns = {
    'sac_yikama': [
      'saçımı yıkadım',
      'saçlarımı yıkadım',
      'saçımı yıkıyordum',
      'saçlarımı yıkıyordum',
      'saçımı yıkıyorum',
      'saçlarımı yıkıyorum',
      'saçımı yıkarken',
      'saçlarımı yıkarken',
      'saç yıkadım',
    ],
    'sac_dokulmesi': [
      'saçım döküldü',
      'saçlarım döküldü',
      'saçım dökülüyordu',
      'saçlarım dökülüyordu',
      'saçım dökülüyor',
      'saçlarım dökülüyor',
      'saçlarım tutam tutam döküldü',
      'saçım elime geldi',
      'saçlarım elimde kaldı',
      'saçım koptu',
      'saçlarım koptu',
      'saçlarım kopuyordu',
      'saçlarımın yarısı döküldü',
    ],
    'dis_dokulmesi': [
      'dişim düştü',
      'dişim döküldü',
      'dişim kırıldı',
      'dişim sallanıyordu',
      'dişlerim düştü',
      'dişlerim döküldü',
      'dişlerim kırıldı',
      'dişlerim sallanıyordu',
      'dişlerim tek tek döküldü',
    ],
    'kovalanma': [
      'kovalanıyorum',
      'kovalanıyordum',
      'beni kovalıyor',
      'beni kovalıyordu',
      'peşimden koşuyordu',
      'peşimden geliyordu',
      'beni takip ediyordu',
      'birisi beni kovaladı',
      'bir hayvan beni kovalıyordu',
    ],
    'dusme': [
      'yere düştüm',
      'yere düşüyordum',
      'yüksekten düştüm',
      'yüksekten düşüyordum',
      'düşüyordum',
      'düşüyorum',
      'uçurumdan düştüm',
      'merdivenden düştüm',
      'boşluğa düştüm',
      'ayağım kaydı',
    ],
    'ucma': [
      'uçuyordum',
      'uçuyorum',
      'uçtum',
      'havada uçuyordum',
      'gökyüzünde uçuyordum',
      'uçmaya başladım',
      'yerden yükseldim',
      'havaya yükseldim',
    ],
    'kacma': [
      'kaçıyordum',
      'kaçıyorum',
      'kaçtım',
      'kaçmaya başladım',
      'koşarak kaçtım',
      'kaçıp kurtuldum',
      'saklandım',
      'gizlendim',
      'kurtulmaya çalıştım',
    ],
    'yilan_gorme': [
      'yılan gördüm',
      'bir yılan gördüm',
      'yılan önümdeydi',
      'evde yılan vardı',
      'yılan üzerime geldi',
      'yılan bana doğru geldi',
      'yılan beni ısırdı',
      'yılan soktu',
      'yılan saldırdı',
    ],
    'yilan_oldurme': [
      'yılanı öldürdüm',
      'yılan öldürdüm',
      'yılanı öldürüyorum',
      'yılanı öldürüyordum',
      'yılanı ezdim',
      'yılanın kafasını kestim',
      'yılanı vurdum',
    ],
    'aglama': [
      'ağlıyorum',
      'ağlıyordum',
      'ağladım',
      'ağlamaya başladım',
      'hıçkıra hıçkıra ağladım',
      'sessizce ağladım',
      'gözyaşları döktüm',
      'ağlayarak uyandım',
    ],
    'birini_kaybetme': [
      'annemi kaybettim',
      'babamı kaybettim',
      'arkadaşımı kaybettim',
      'eşimi kaybettim',
      'sevgilimi kaybettim',
      'kardeşimi kaybettim',
      'çocuğumu kaybettim',
      'sevdiğim birini kaybettim',
      'annem öldü',
      'babam öldü',
      'kardeşim öldü',
    ],
    'suda_olma': [
      'suda yüzüyordum',
      'suda yüzdüm',
      'denizde yüzüyordum',
      'denize girdim',
      'suya girdim',
      'nehre girdim',
      'gölde yüzüyordum',
      'suyun içindeydim',
      'suya düştüm',
      'denize düştüm',
    ],
    'bogulma': [
      'boğuluyordum',
      'boğuldum',
      'suda boğuluyordum',
      'denizde boğuluyordum',
      'nefes alamıyordum',
      'su altında kaldım',
      'su altında nefessiz kaldım',
      'suya batıyordum',
    ],
    'yangin': [
      'yangın çıktı',
      'ev yanıyordu',
      'evim yanıyordu',
      'ateş gördüm',
      'her yer yanıyordu',
      'orman yanıyordu',
      'alevler yükseliyordu',
      'yangından kaçtım',
      'yangını söndürdüm',
      'ateşin içindeydim',
    ],
    'ev_gorme': [
      'ev gördüm',
      'evime girdim',
      'eski evime gittim',
      'yeni bir eve taşındım',
      'evimi kaybettim',
      'evin içinde dolaşıyordum',
      'evin kapısını açtım',
      'evde kayboldum',
      'ev yıkıldı',
    ],
    'kaybolma': [
      'kayboldum',
      'kayboluyordum',
      'yolumu kaybettim',
      'yolumu bulamadım',
      'nerede olduğumu bilmiyordum',
      'çıkış yolunu bulamadım',
      'bir yerde mahsur kaldım',
      'gideceğim yeri bulamadım',
    ],
    'kapali_yerde_kalma': [
      'bir yere kapatıldım',
      'odaya kilitlendim',
      'içeride kilitli kaldım',
      'hapisteydim',
      'hapishanedeydim',
      'kapıyı açamadım',
      'kıpırdayamıyordum',
      'ellerim bağlıydı',
    ],
    'araba_kazasi': [
      'araba kazası yaptım',
      'araba çarptı',
      'bana araba çarptı',
      'araba devrildi',
      'arabamız devrildi',
      'fren tutmadı',
      'araba kontrolden çıktı',
      'trafik kazası geçirdim',
    ],
    'sinav': [
      'sınava girdim',
      'sınava giriyordum',
      'sınava geç kaldım',
      'sınava yetişemedim',
      'soruları yapamadım',
      'sınava hazırlanmamıştım',
      'sınavı geçemedim',
      'sınav sonucumu gördüm',
      'okula geç kaldım',
    ],
    'ciplaklik': [
      'çıplaktım',
      'çıplak kaldım',
      'herkesin içinde çıplaktım',
      'üzerimde kıyafet yoktu',
      'giyinmemiştim',
    ],
    'dugun': [
      'düğünüm vardı',
      'düğüne gittim',
      'evleniyordum',
      'evlendim',
      'gelinlik giydim',
      'damatlık giydim',
      'nikâh kıyıldı',
    ],
    'hamilelik': [
      'hamileydim',
      'hamile olduğumu öğrendim',
      'hamile kaldım',
      'karnımda bebek vardı',
      'bebek bekliyordum',
      'doğum yapıyordum',
      'doğum yaptım',
    ],
    'olum_cenaze': [
      'öldüğümü gördüm',
      'ölmüştüm',
      'cenazemi gördüm',
      'cenazeye gittim',
      'birinin cenazesindeydim',
      'tabut gördüm',
      'mezar gördüm',
      'mezarlığa gittim',
    ],
    'para_kaybi': [
      'paramı kaybettim',
      'cüzdanımı kaybettim',
      'param çalındı',
      'cüzdanım çalındı',
      'çantamı kaybettim',
      'telefonumu kaybettim',
      'eşyalarım kayboldu',
    ],
    'bir_sey_bulma': [
      'para buldum',
      'altın buldum',
      'yerde para buldum',
      'kayıp eşyamı buldum',
      'hazine buldum',
      'bir şey keşfettim',
    ],
    'yukselme': [
      'merdiven çıktım',
      'merdivenleri tırmandım',
      'dağa tırmandım',
      'tepeye çıktım',
      'yükseğe çıktım',
      'zirveye ulaştım',
    ],
  };

  // Olumsuz fiil biçimleri pozitif kalıplardan ayrı tutulur.
  static const Map<String, List<String>> _negativeEventPatterns = {
    'sac_yikama': [
      'saçımı yıkamadım',
      'saçlarımı yıkamadım',
      'saçımı yıkamıyordum',
    ],
    'sac_dokulmesi': [
      'saçım dökülmedi',
      'saçlarım dökülmedi',
      'saçım dökülmüyordu',
      'saçlarım dökülmüyordu',
      'saçım kopmadı',
      'saçlarım kopmadı',
    ],
    'dis_dokulmesi': [
      'dişim düşmedi',
      'dişlerim düşmedi',
      'dişim dökülmedi',
      'dişlerim dökülmedi',
      'dişim kırılmadı',
      'dişlerim kırılmadı',
    ],
    'kovalanma': [
      'beni kimse kovalamadı',
      'kimse beni kovalamadı',
      'beni takip etmedi',
      'peşimden gelmedi',
    ],
    'dusme': [
      'düşmedim',
      'yere düşmedim',
      'yüksekten düşmedim',
      'ayağım kaymadı',
    ],
    'ucma': [
      'uçmadım',
      'uçmuyordum',
    ],
    'kacma': [
      'kaçmadım',
      'kaçmıyordum',
    ],
    'yilan_gorme': [
      'yılan görmedim',
      'hiç yılan görmedim',
      'yılan yoktu',
      'yılan bana saldırmadı',
      'yılan beni ısırmadı',
    ],
    'yilan_oldurme': [
      'yılanı öldürmedim',
      'yılan öldürmedim',
      'yılanı ezmedim',
    ],
    'aglama': [
      'ağlamadım',
      'ağlamıyordum',
    ],
    'suda_olma': [
      'suya girmedim',
      'denize girmedim',
      'suda yüzmedim',
      'denizde yüzmedim',
    ],
    'bogulma': [
      'boğulmadım',
      'boğulmuyordum',
      'nefesim kesilmedi',
    ],
    'yangin': [
      'yangın çıkmadı',
      'ev yanmadı',
      'yangın yoktu',
    ],
    'ev_gorme': [
      'ev görmedim',
      'ev yoktu',
    ],
    'kaybolma': [
      'kaybolmadım',
      'yolumu kaybetmedim',
    ],
    'araba_kazasi': [
      'kaza yapmadım',
      'araba çarpmadı',
      'kaza olmadı',
    ],
    'sinav': [
      'sınava girmedim',
      'sınav olmadı',
    ],
    'ciplaklik': [
      'çıplak değildim',
      'çıplak değildim',
    ],
    'dugun': [
      'evlenmedim',
      'düğün olmadı',
    ],
    'hamilelik': [
      'hamile değildim',
      'hamile kalmadım',
    ],
    'olum_cenaze': [
      'ölmedim',
      'ölmemiştim',
      'cenaze yoktu',
    ],
    'para_kaybi': [
      'paramı kaybetmedim',
      'cüzdanımı kaybetmedim',
      'param çalınmadı',
    ],
    'bir_sey_bulma': [
      'para bulamadım',
      'altın bulamadım',
      'hiçbir şey bulamadım',
    ],
    'yukselme': [
      'tırmanamadım',
      'yukarı çıkamadım',
    ],
  };

  static const Map<String, String> _eventNames = {
    'sac_yikama': 'Saç yıkama',
    'sac_dokulmesi': 'Saç dökülmesi veya kopması',
    'dis_dokulmesi': 'Diş dökülmesi veya kırılması',
    'kovalanma': 'Takip edilme veya kovalanma',
    'dusme': 'Düşme',
    'ucma': 'Uçma',
    'kacma': 'Kaçma veya saklanma',
    'yilan_gorme': 'Yılan görme veya yılan saldırısı',
    'yilan_oldurme': 'Yılan öldürme',
    'aglama': 'Ağlama',
    'birini_kaybetme': 'Yakın birini kaybetme',
    'suda_olma': 'Suda bulunma veya yüzme',
    'bogulma': 'Boğulma veya nefessiz kalma',
    'yangin': 'Ateş veya yangın',
    'ev_gorme': 'Ev veya mekânla ilgili olay',
    'kaybolma': 'Kaybolma veya yolunu bulamama',
    'kapali_yerde_kalma': 'Kapalı yerde kalma veya hareket edememe',
    'araba_kazasi': 'Araba kazası',
    'sinav': 'Sınav veya hazırlıksız yakalanma',
    'ciplaklik': 'Çıplaklık',
    'dugun': 'Düğün veya evlilik',
    'hamilelik': 'Hamilelik veya doğum',
    'olum_cenaze': 'Ölüm, cenaze veya mezarlık',
    'para_kaybi': 'Para veya eşya kaybı',
    'bir_sey_bulma': 'Bir şey bulma veya keşfetme',
    'yukselme': 'Yükseğe çıkma veya tırmanma',
  };

  // =========================================================
  // 4. OLAYLARI SIRALAMA VE DURUM BELİRLEME
  // =========================================================

  static List<String> _detectEvents(List<String> words) {
    final events = <String>[];

    for (final entry in _eventPatterns.entries) {
      final positivePositions =
          _findPhraseStarts(words, entry.value);
      final negativePositions =
          _findPhraseStarts(
            words,
            _negativeEventPatterns[entry.key] ?? [],
          );

      // En son açık ifade olayın durumunu belirler.
      final lastPositive = positivePositions.isEmpty
          ? -1
          : positivePositions.last;
      final lastNegative = negativePositions.isEmpty
          ? -1
          : negativePositions.last;

      if (lastPositive > lastNegative && lastPositive >= 0) {
        final phrase = entry.value.firstWhere(
          (p) => _findPhraseStarts(words, [p]).contains(lastPositive),
          orElse: () => '',
        );
        final parts = _words(phrase);

        if (!_isNegatedAt(words, lastPositive, parts.length)) {
          events.add(entry.key);
        }
      }
    }

    // Olayların sözlük sırası yerine anlatıdaki sırasını koru.
    events.sort((a, b) {
      final aPositions = _findPhraseStarts(words, _eventPatterns[a] ?? []);
      final bPositions = _findPhraseStarts(words, _eventPatterns[b] ?? []);
      final aPos = aPositions.isEmpty ? 999999 : aPositions.first;
      final bPos = bPositions.isEmpty ? 999999 : bPositions.first;
      return aPos.compareTo(bPos);
    });

    return events;
  }

  // =========================================================
  // 5. DUYGU TESPİTİ
  // =========================================================

  static const Map<String, List<String>> _emotionPatterns = {
    'korku': [
      'korktum',
      'korkuyorum',
      'korkuyordum',
      'çok korktum',
      'çok korkuyordum',
      'dehşete düştüm',
      'panikledim',
      'ürktüm',
      'ödüm koptu',
      'endişelendim',
    ],
    'üzüntü': [
      'üzüldüm',
      'üzgündüm',
      'hüzünlendim',
      'çok ağladım',
      'içim acıdı',
      'kendimi kötü hissettim',
    ],
    'mutluluk': [
      'mutluydum',
      'çok mutlu oldum',
      'sevindim',
      'çok sevindim',
      'neşeliydim',
      'çok eğlendim',
    ],
    'huzur': [
      'huzurluydum',
      'rahatlamıştım',
      'kendimi güvende hissettim',
      'içim rahattı',
      'sakin hissediyordum',
    ],
    'şaşkınlık': [
      'şaşırdım',
      'çok şaşırdım',
      'hayrete düştüm',
      'inanamadım',
    ],
    'öfke': [
      'sinirlendim',
      'çok öfkeliydim',
      'kızgındım',
      'çok kızdım',
      'öfkelendim',
    ],
    'iğrenme': [
      'iğrendim',
      'midem bulandı',
      'tiksindim',
    ],
    'utanç': [
      'utandım',
      'mahcup oldum',
      'rezil oldum',
    ],
    'kafa_karisikligi': [
      'kafam karıştı',
      'ne olduğunu anlayamadım',
      'anlam veremedim',
    ],
  };

  static const Map<String, List<String>> _negativeEmotionPatterns = {
    'korku': [
      'korkmadım',
      'korkmuyordum',
      'korkmuyorum',
      'hiç korkmadım',
      'korkmuş değildim',
    ],
    'üzüntü': [
      'üzülmedim',
      'ağlamadım',
      'üzgün değildim',
    ],
    'mutluluk': [
      'mutlu değildim',
      'sevinmedim',
      'mutlu olmadım',
    ],
    'huzur': [
      'huzurlu değildim',
      'rahat değildim',
      'kendimi güvende hissetmedim',
    ],
    'öfke': [
      'sinirlenmedim',
      'kızmadım',
      'öfkeli değildim',
    ],
  };

  static List<String> _detectEmotions(
    List<String> words,
    String originalText,
  ) {
    final results = <String>[];
    final sentences = _sentences(originalText);

    for (final entry in _emotionPatterns.entries) {
      var positiveFound = false;
      var negativeFound = false;

      for (final sentence in sentences) {
        final sentenceWords = _words(sentence);
        final positive = _hasPhrase(sentenceWords, entry.value);
        final negative = _hasNegatedExpression(
          sentenceWords,
          _negativeEmotionPatterns[entry.key] ?? [],
        );

        if (positive) positiveFound = true;
        if (negative) negativeFound = true;

        // "Korkmadım ama sonra korktum" gibi karşıt ifadelerde
        // aynı cümledeki karşıtlık bağlacı sonraki duyguyu korur.
        if (positive &&
            negative &&
            _hasPhrase(sentenceWords, _contrastWords)) {
          final lastPositive =
              _findPhraseStarts(sentenceWords, entry.value).last;
          final lastNegative = _findPhraseStarts(
            sentenceWords,
            _negativeEmotionPatterns[entry.key] ?? [],
          ).last;

          if (lastPositive > lastNegative) {
            negativeFound = false;
          } else {
            positiveFound = false;
          }
        }
      }

      if (positiveFound && !negativeFound) {
        results.add(entry.key);
      } else if (positiveFound && negativeFound) {
        // Çelişkili duygular varsa tek bir duyguya zorlamıyoruz.
        results.add('${entry.key}_karisik');
      }
    }

    return results;
  }

  // =========================================================
  // 6. SEMBOL TESPİTİ
  // =========================================================

  static List<Ruyasembolu> _detectSymbols(List<String> words) {
    final results = <Ruyasembolu>[];
    final foundKeys = <String>{};

    for (final symbol in tumSemboller) {
      final candidates = [
        symbol.anahtar,
        ...symbol.eslesenKelimeler,
      ];

      var found = false;

      for (final candidate in candidates) {
        final normalized = _normalize(candidate);

        // "kör" ile "korktum" karışmasın.
        if (normalized == 'kor') {
          if (words.contains('kor')) found = true;
          continue;
        }

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
  // 7. OLAYLAR ARASI İLİŞKİLER
  // =========================================================

  static List<String> _analyzeContext({
    required List<String> events,
    required List<String> emotions,
    required List<Ruyasembolu> symbols,
  }) {
    final results = <String>[];
    final e = events.toSet();
    final m = emotions.toSet();

    if (e.contains('sac_yikama') && e.contains('sac_dokulmesi')) {
      results.add(
        'Saç yıkama ve saç dökülmesi birlikte anlatılıyor. '
        'Yenilenme ile kayıp hissi arasındaki ilişki, '
        'rüyayı gören kişinin deneyimine göre değerlendirilebilir.',
      );
    }

    if (e.contains('yilan_oldurme')) {
      results.add(
        'Yılanı öldürme olayı tespit edildi. Bu, yalnızca '
        'yılan görmekten farklı bir eylemdir; olayın sonucu '
        've rüyadaki duygu ayrıca önemlidir.',
      );
    } else if (e.contains('yilan_gorme')) {
      results.add(
        'Yılanla karşılaşma tespit edildi. Öldürme eylemi '
        'tespit edilmediği için böyle bir sonuç varsayılmıyor.',
      );
    }

    if (e.contains('kovalanma') && e.contains('kacma')) {
      results.add(
        'Kovalanma ve kaçma birlikte görülüyor. Baskı altında '
        'hissetme veya bir durumdan uzaklaşma teması olabilir.',
      );
    }

    if (e.contains('dusme') && m.contains('korku')) {
      results.add(
        'Düşme ve korku birlikte anlatılmış. Kontrolü kaybetme '
        'veya güvensizlik çağrışımı mümkün; kesin bir anlam değildir.',
      );
    }

    if (e.contains('suda_olma') && e.contains('bogulma')) {
      results.add(
        'Suda bulunma ile boğulma birlikte tespit edildi. '
        'Suya girmek ve nefessiz kalmak ayrı olaylardır; '
        'bu anlatıda boğulma teması da bulunuyor.',
      );
    }

    if (e.contains('yangin') && e.contains('kacma')) {
      results.add(
        'Yangın ve kaçma birlikte anlatılıyor. Tehlikeden '
        'uzaklaşma veya güvenli bir yer arama teması düşünülebilir.',
      );
    }

    if (e.contains('sinav') && m.contains('korku')) {
      results.add(
        'Sınav ve korku birlikte tespit edildi. Performans '
        'baskısı veya hazırlıksız yakalanma çağrışımı olabilir.',
      );
    }

    if (e.contains('kaybolma') && m.contains('korku')) {
      results.add(
        'Kaybolma ve korku birlikte bulunuyor. Belirsizlik '
        've yönünü bulamama hissi kişisel bağlamda anlamlı olabilir.',
      );
    }

    if (e.contains('kapali_yerde_kalma')) {
      results.add(
        'Kapalı kalma veya hareket edememe teması var. '
        'Kısıtlanma hissi olası bir çağrışımdır. Bu durum '
        'uykuya dalarken veya uyanırken yaşandıysa farklı '
        'bir uyku deneyimi de olabilir.',
      );
    }

    if (m.contains('korku') && m.contains('mutluluk')) {
      results.add(
        'Korku ve mutluluğa işaret eden ifadeler birlikte '
        'bulunuyor. Duygusal deneyim tek bir duyguya indirgenmemeli.',
      );
    }

    if (results.isEmpty && symbols.length >= 2) {
      results.add(
        'Birden fazla sembol tespit edildi; ancak kurallar '
        'bunlar arasında güvenilir bir ilişki belirleyemedi.',
      );
    }

    if (results.isEmpty) {
      results.add(
        'Mevcut kurallar belirgin bir olay ilişkisi bulamadı. '
        'Bu, rüyanın anlamsız olduğu anlamına gelmez.',
      );
    }

    return results;
  }

  // =========================================================
  // 8. ANA ANALİZ
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

    buffer.writeln('OLAY AKIŞI\n');

    if (events.isEmpty) {
      buffer.writeln(
        'Tanımlı olay kalıplarıyla olumlu eşleşme bulunamadı.',
      );
    } else {
      for (var i = 0; i < events.length; i++) {
        buffer.writeln('${i + 1}. ${_eventNames[events[i]] ?? events[i]}');
      }
    }

    buffer.writeln('\nDUYGUSAL ANALİZ\n');

    if (emotions.isEmpty) {
      buffer.writeln(
        'Açık bir duygu ifadesi tespit edilmedi. '
        'Belirtilmeyen bir duygu varsayılmıyor.',
      );
    } else {
      buffer.writeln(
        'Metindeki duygu ifadeleri: ${emotions.join(', ')}.',
      );
      buffer.writeln(
        'Bu sonuçlar yazılı ifadelerden çıkarılmıştır; '
        'kişinin gerçek duygusunu kesin olarak belirlemez.',
      );
    }

    buffer.writeln('\nSEMBOLLER\n');

    if (symbols.isEmpty) {
      buffer.writeln(
        'Sembol sözlüğünde eşleşme bulunamadı. '
        'Sözlüğe yeni semboller ve kelime biçimleri eklenebilir.',
      );
    } else {
      for (final symbol in symbols) {
        buffer.writeln('• ${symbol.anahtar.toUpperCase()}');
        buffer.writeln(symbol.yorum);
        buffer.writeln();
      }
    }

    buffer.writeln('OLAYLAR ARASINDAKİ İLİŞKİ\n');

    for (final item in context) {
      buffer.writeln('• $item\n');
    }

    buffer.writeln('KİŞİSEL DEĞERLENDİRME\n');

    buffer.writeln(
      'Rüyadaki olaylar gerçek yaşamındaki bir durumu, '
      'anı veya endişeyi çağrıştırıyor mu? Kişisel bağlam '
      'olmadan tek bir yorumu kesin kabul etme.',
    );

    buffer.writeln('\nÖNEMLİ NOT\n');

    buffer.writeln(
      'Bu uygulama kural tabanlı metin analizi yapar; '
      'serbest dil anlayan bir yapay zekâ değildir. '
      'Rüya yorumları kesin bilimsel sonuç veya geleceğe '
      'dair kanıt olarak değerlendirilmemelidir.',
    );

    return buffer.toString().trim();
  }
}
