import '../data/symbols.dart';

class Interpreter {
  static final List<String> _ekler = [
    'larından', 'lerinden', 'larıyla', 'leriyle', 'lardan', 'lerden', 'lardaki', 'lerdeki',
    'mızdan', 'mizden', 'muzdan', 'müzden', 'ları', 'leri', 'lar', 'ler',
    'ımız', 'imiz', 'umuz', 'ümüz', 'ınız', 'iniz', 'unuz', 'ünüz',
    'ım', 'im', 'um', 'üm', 'ın', 'in', 'un', 'ün', 
    'nın', 'nin', 'nun', 'nün', 'ndan', 'nden', 'ntan', 'nten',
    'da', 'de', 'ta', 'te', 'dan', 'den', 'tan', 'ten', 'nda', 'nde',
    'a', 'e', 'ya', 'ye', 'na', 'ne', 'yı', 'yi', 'yu', 'yü',
    'ı', 'i', 'u', 'ü', 'yı', 'yi', 'yu', 'yü',
    'la', 'le', 'yla', 'yle', 'ca', 'ce', 'ça', 'çe',
    'lık', 'lik', 'luk', 'lük', 'cı', 'ci', 'cu', 'cü', 'çı', 'çi', 'çu', 'çü',
    'sı', 'si', 'su', 'sü', 'sını', 'sini', 'sunu', 'sünü',
    'mış', 'miş', 'muş', 'müş', 'mıştı', 'mişti', 'yor', 'yordu', 'yorum', 'yorsun', 'yorken',
    'yodu', 'yodum', 'yodun', 'caktı', 'cekti', 'acaktım', 'ecektim',
    'dı', 'di', 'du', 'dü', 'tı', 'ti', 'tu', 'tü', 'acak', 'ecek', 'acağım', 'eceğim'
  ];

  static String _kokBul(String kelime) {
    String kok = kelime;
    for (String ek in _ekler) {
      if (kok.endsWith(ek) && kok.length > ek.length + 2) {
        kok = kok.substring(0, kok.length - ek.length);
        break;
      }
    }
    if (kok.endsWith('yod')) kok = kok.replaceAll('yod', 'yor');
    if (kok.endsWith('cak')) kok = kok.replaceAll('cak', 'yacak');
    if (kok.endsWith('ğ')) kok = kok.replaceAll('ğ', 'k'); 
    if (kok.endsWith('b')) kok = kok.replaceAll('b', 'p');
    if (kok.endsWith('c')) kok = kok.replaceAll('c', 'ç');
    if (kok.endsWith('d')) kok = kok.replaceAll('d', 't');
    if (kok.endsWith('y') && kok.length > 3) kok = kok.substring(0, kok.length - 1);
    return kok;
  }

  static String yorumla(String metin) {
    final kucukMetin = metin.toLowerCase();
    final temizMetin = kucukMetin.replaceAll(RegExp(r'[^\w\sğüşıöç]'), ' ');
    final kelimeler = temizMetin.split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
    
    final List<Ruyasembolu> bulunanlar = [];
    final Set<String> bulunanAnahtarlar = {};

    // Geniş Arama Motoru
    for (final sembol in tumSemboller) {
      if (bulunanAnahtarlar.contains(sembol.anahtar)) continue;

      for (final eslesen in sembol.eslesenKelimeler) {
        bool bulundu = false;
        final eslesenKok = _kokBul(eslesen);

        for (final kelime in kelimeler) {
          final kelimeKok = _kokBul(kelime);
          
          if (kelime == eslesen) { bulundu = true; break; }
          if (kelimeKok == eslesenKok && kelimeKok.length >= 2) { bulundu = true; break; }
          if (kelime.startsWith(eslesen) && eslesen.length >= 3) { bulundu = true; break; }
          if (eslesenKok.length >= 4 && kelime.contains(eslesenKok)) { bulundu = true; break; }
        }
        
        if (bulundu) {
          bulunanlar.add(sembol);
          bulunanAnahtarlar.add(sembol.anahtar);
          break; 
        }
      }
    }

    if (bulunanlar.isEmpty) {
      return 'Rüyanızda bilinen belirgin bir sembol tespit edilemedi. Ancak bilinçaltınız size bir mesaj vermeye çalışıyor olabilir. Lütfen rüyanızı daha detaylı anlatın veya farklı kelimeler kullanın. (İpucu: Su, yılan, uçmak, ev, saç gibi net semboller kullanmayı deneyin.)';
    }

    // --- AKIL YÜRÜTME VE BAĞLAM ANALİZİ ---
    bool hasFear = kucukMetin.contains('korku') || kucukMetin.contains('kabus') || kucukMetin.contains('dehşet') || kucukMetin.contains('kaçtım') || kucukMetin.contains('saldırdı');
    bool hasSadness = kucukMetin.contains('hüzün') || kucukMetin.contains('ağla') || kucukMetin.contains('üzgün') || kucukMetin.contains('kayıp') || kucukMetin.contains('ayrılık');
    bool hasJoy = kucukMetin.contains('mutlu') || kucukMetin.contains('sevinç') || kucukMetin.contains('gül') || kucukMetin.contains('huzur') || kucukMetin.contains('başarı');

    final buffer = StringBuffer();
    
    // 1. GİRİŞ PARAGRAFI (Ruh Hali Analizi)
    buffer.writeln('Merhaba. Rüyanızın sembolik dilini ve bilinçaltınızın size fısıldadıklarını inceledim.\n');
    
    if (hasFear) {
      buffer.writeln('Rüyanızın genel atmosferinde belirgin bir kaygı, korku veya kaçış hissi hakim. Bu durum, günlük hayatınızda henüz yüzleşmediğiniz, sizi içten içe rahatsız eden bir stres kaynağına işaret ediyor. Bilinçaltınız, uyanıkken bastırdığınız bu duyguları size bir uyarı olarak gösteriyor. İçinizdeki bu fırtınayı dinlemenin vakti gelmiş olabilir.\n');
    } else if (hasSadness) {
      buffer.writeln('Rüyanızda derin bir hüzün, melankoli veya bir kayıp hissi seziliyor. Bu, geçmişte yaşadığınız ve hala tam olarak üstesinden gelemediğiniz bir olayın, zihninizin derinliklerinde yankılandığını gösterir. Bilinçaltınız sizi iyileştirmeye, geçmişi geride bırakıp içsel bir arınma yaşamaya davet ediyor.\n');
    } else if (hasJoy) {
      buffer.writeln('Rüyanızın enerjisi oldukça pozitif, huzurlu ve aydınlık. Bu durum, bilinçaltınızın dingin olduğunu, ruhsal olarak rahat bir dönemden geçtiğinizi ve hayatınızdaki güzel gelişmelere açık olduğunuzu müjdeliyor. İçsel huzurunuz, dış dünyanıza da yansımaya hazırlanıyor.\n');
    } else {
      buffer.writeln('Rüyanız, bilinçaltınızın size gönderdiği gizemli ve sembolik bir mektup gibidir. Ruh haliniz şu an nötr görünse de, zihninizin derinliklerinde işlenen bazı süreçler var. Gelin bu sembollerin anlamlarına birlikte bakalım.\n');
    }

    // 2. SEMBOL YORUMLARI (Uzun ve Detaylı)
    buffer.writeln('--- RÜYANIZDAKİ SEMBOLLERİN DETAYLI ANALİZİ ---\n');
    
    for (int i = 0; i < bulunanlar.length; i++) {
      buffer.writeln('${i + 1}. Sembol:');
      // Sembolün adını büyük harfle yazdıralım
      buffer.writeln('${bulunanlar[i].anahtar.toUpperCase()}\n');
      
      // Yorumu genişletelim
      String genisYorum = bulunanlar[i].yorum;
      genisYorum += ' Bu sembol size, hayatınızın mevcut gidişatı hakkında önemli ipuçları veriyor. Bilinçaltınız bu görüntüyle, hem geçmiş deneyimlerinizden ders almanızı hem de geleceğe daha hazırlıklı bakmanızı sağlamaya çalışıyor.';
      
      if (hasFear) {
        genisYorum += ' Rüyanızdaki korkuyla birleştiğinde, bu sembolün sizi bir tehlikeye karşı uyardığını söyleyebiliriz.';
      } else if (hasJoy) {
        genisYorum += ' Rüyanızdaki olumlu havayla birleştiğinde, bu sembolün yakın zamanda size güzel kapılar açacağını müjdeliyor.';
      }
      
      buffer.writeln('$genisYorum\n');
    }

    // 3. KAPANIŞ VE TAVSİYE (Usta Yorumu)
    buffer.writeln('--- GENEL DEĞERLENDİRME VE TAVSİYE ---\n');
    buffer.writeln('Rüyalar, ruhumuzun aynasıdır. Size tavsiyem, bu yorumları birer kesin kehanet olarak görmek yerine, kendi içinize dönüp düşünmeniz için bir fırsat bilmenizdir. Bilinçaltınız size ne anlatmaya çalışıyor? Hangi duygularınızı bastırıyorsunuz veya hangi fırsatları görmezden geliyorsunuz? Unutmayın, rüyaların asıl gücü, size kendinizi hatırlatmasıdır.\n');
    
    buffer.writeln('---');
    buffer.writeln('Not: Bu yorumlar geleneksel İslami tabir geleneği ve temel psikolojik sembolizm esas alınarak hazırlanmıştır. Sadece eğlence ve farkındalık amaçlıdır. Bilimsel veya tıbbi bir teşhis niteliği taşımaz.');

    return buffer.toString();
  }
}
