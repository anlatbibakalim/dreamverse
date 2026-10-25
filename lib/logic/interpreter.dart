import '../data/symbols.dart';

class Interpreter {
  // 1. DUYGU SÖZLÜKLERİ
  static final Map<String, double> korkuKelimeleri = {
    'korku': 2.0, 'korktum': 2.0, 'korkuyorum': 2.0, 'kabus': 3.0, 'dehşet': 3.0,
    'kaçtım': 2.0, 'kaçıyordum': 2.0, 'saldırdı': 3.0, 'tehlike': 2.0, 'ürktüm': 2.0, 'kan': 1.0
  };

  static final Map<String, double> huzunKelimeleri = {
    'hüzün': 2.0, 'ağladım': 2.0, 'ağlıyordum': 2.0, 'üzgün': 2.0, 'kaybettim': 3.0, 'ayrılık': 2.0, 'koptu': 1.5
  };

  static final Map<String, double> mutlulukKelimeleri = {
    'mutlu': 2.0, 'sevinç': 2.0, 'güldüm': 2.0, 'huzur': 2.0, 'başarı': 2.0, 'sevdim': 1.0
  };

  static final Map<String, double> yogunlukKelimeleri = {
    'çok': 1.5, 'çook': 2.0, 'aşırı': 2.0, 'dehşet': 2.0, 'biraz': 0.7, 'hafif': 0.6
  };

  static final List<String> olumsuzluklar = [
    'değil', 'değildi', 'yok', 'yoktu', 'görmedim', 'olmadı', 'korkmuyorum', 'korkmadım', 'hiç'
  ];

  // 2. EYLEM SÖZLÜĞÜ (Yorumu zenginleştirmek için)
  static final Map<String, String> eylemYorumlari = {
    'kovala': 'Kaçınan veya yüzleşmekten çekindiğiniz bir konunun sizi takip ettiğini görüyorum.',
    'öl': 'Bir dönemin, ilişkinin ya da alışkanlığın sona ermesi ve yenilenme ihtiyacı.',
    'uç': 'Özgürlük, kontrol ve hedeflerinize ulaşma arzusu öne çıkıyor.',
    'kaybet': 'Değer verdiğiniz bir şeyin kontrolünüzden çıktığı hissini taşıyorsunuz.',
    'ağla': 'Bastırılmış bir üzüntünün veya içsel boşalmanın ifade bulmaya çalıştığını gösterir.',
    'yıka': 'Geçmişten veya bir olaydan arınma, temizlenme ve yeniden başlama isteği.',
    'kop': 'Hayatınızdaki bir bağın zayıfladığını veya sizi yoran bir durumdan kurtulma isteğini simgeler.',
  };

  // 3. TÜRKÇE KÖK BULUCU (Ünlü düşmesi ve Ünsüz yumuşamasını tolere eder)
  static String _kokBul(String kelime) {
    if (kelime.length <= 3) return kelime;
    
    // Yaygın ekleri kes
    List<String> ekler = ['larından', 'lerinden', 'ları', 'leri', 'lar', 'ler', 'ım', 'im', 'um', 'üm', 'ın', 'in', 'un', 'ün', 'ı', 'i', 'u', 'ü', 'yı', 'yi', 'yu', 'yü', 'da', 'de', 'ta', 'te', 'dan', 'den', 'tan', 'ten', 'a', 'e', 'ya', 'ye', 'yor', 'yordu', 'yorum', 'dı', 'di', 'du', 'dü', 'mış', 'miş', 'muş', 'müş'];
    
    String kok = kelime;
    for (String ek in ekler) {
      if (kok.endsWith(ek) && kok.length > ek.length + 2) {
        kok = kok.substring(0, kok.length - ek.length);
        break;
      }
    }
    
    // Ünsüz yumuşaması (ağz -> ağız, ekmeğ -> ekmek)
    if (kok.endsWith('ğ')) kok = kok.replaceAll('ğ', 'k');
    if (kok.endsWith('b')) kok = kok.replaceAll('b', 'p');
    if (kok.endsWith('c')) kok = kok.replaceAll('c', 'ç');
    if (kok.endsWith('d')) kok = kok.replaceAll('d', 't');
    
    return kok;
  }

  // 4. ANA YORUMLAMA MOTORU
  static String yorumla(String metin) {
    // Metni cümlelere ayır (Nokta, ünlem, soru işareti)
    final cumleler = metin.toLowerCase().split(RegExp(r'[.!?]')).where((c) => c.trim().isNotEmpty).toList();
    
    final List<Ruyasembolu> bulunanSemboller = [];
    final Set<String> bulunanAnahtarlar = {};
    final List<String> tespitEdilenEylemler = [];

    // Cümle cümle analiz et
    for (String cumle in cumleler) {
      // Cümleyi kelimelere ayır
      final kelimeler = cumle.replaceAll(RegExp(r'[^\w\sğüşıöç]'), ' ').split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
      
      for (int i = 0; i < kelimeler.length; i++) {
        final kelime = kelimeler[i];
        final kok = _kokBul(kelime);

        // A) EYLEM TESPİTİ (Cümle içindeki eylemleri bul)
        for (final eylemKey in eylemYorumlari.keys) {
          if (kelime.contains(eylemKey) || kok.contains(eylemKey)) {
            if (!tespitEdilenEylemler.contains(eylemYorumlari[eylemKey])) {
              tespitEdilenEylemler.add(eylemYorumlari[eylemKey]!);
            }
          }
        }

        // B) SEMBOL TESPİTİ
        for (final sembol in tumSemboller) {
          if (bulunanAnahtarlar.contains(sembol.anahtar)) continue; // Zaten bulunduysa geç

          for (final eslesen in sembol.eslesenKelimeler) {
            // Eşleşme Kontrolü (Tam eşleşme veya Kök eşleşmesi)
            if (kelime == eslesen || kok == eslesen || (eslesen.length >= 4 && kelime.contains(eslesen))) {
              
              // OLUMSUZLUK PENCERESİ KONTROLÜ (Bu cümlenin içinde olumsuzluk var mı?)
              // Sembolün bulunduğu yerin 4 kelime öncesi ve 2 kelime sonrasına bak
              final baslangic = (i - 4).clamp(0, kelimeler.length);
              final bitis = (i + 3).clamp(0, kelimeler.length);
              final pencere = kelimeler.sublist(baslangic, bitis).join(' ');
              
              bool olumsuzMu = olumsuzluklar.any((o) => pencere.contains(o));

              if (!olumsuzMu) {
                bulunanSemboller.add(sembol);
                bulunanAnahtarlar.add(sembol.anahtar);
              }
            }
          }
        }
      }
    }

    // Bilinmeyen sembol durumu
    if (bulunanSemboller.isEmpty) {
      return 'Rüyanızda tanıdığım belirgin bir sembol tespit edemedim. Ancak bu, rüyanızın anlamsız olduğu anlamına gelmez. Rüyanızı daha net hatırladığınız detaylarla (örneğin; neredeydiniz, kim vardı, ne yapıyordunuz?) tekrar anlatırsanız sizi daha iyi anlayabilirim.';
    }

    // DUYGU SKORLAMASI
    double korkuSkor = 0, huzunSkor = 0, mutlulukSkor = 0;
    final tumKelimeler = metin.toLowerCase().split(RegExp(r'\s+'));
    
    for (final kelime in tumKelimeler) {
      if (korkuKelimeleri.containsKey(kelime)) korkuSkor += korkuKelimeleri[kelime]!;
      if (huzunKelimeleri.containsKey(kelime)) huzunSkor += huzunKelimeleri[kelime]!;
      if (mutlulukKelimeleri.containsKey(kelime)) mutlulukSkor += mutlulukKelimeleri[kelime]!;
    }

    for (final kelime in tumKelimeler) {
      if (yogunlukKelimeleri.containsKey(kelime)) {
        if (korkuSkor > 0) korkuSkor *= yogunlukKelimeleri[kelime]!;
        if (mutlulukSkor > 0) mutlulukSkor *= yogunlukKelimeleri[kelime]!;
      }
    }

    // YORUM METNİNİ OLUŞTURMA (Dinamik ve Akıcı)
    final buffer = StringBuffer();
    
    // 1. Giriş (Duygu Durumu)
    if (korkuSkor >= 3) {
      buffer.writeln('Rüyanızın genel atmosferinde belirgin bir kaygı ve tehdit hissi hakim. Bilinçaltınız sizi güçlü bir şekilde uyarıyor.\n');
    } else if (huzunSkor >= 2 && huzunSkor > mutlulukSkor) {
      buffer.writeln('Rüyanızda derin bir hüzün veya kayıp hissi öne çıkıyor. Geçmişten gelen bazı duyguların açığa çıkmaya çalıştığını görüyorum.\n');
    } else if (mutlulukSkor >= 2 && mutlulukSkor > korkuSkor) {
      buffer.writeln('Rüyanızın enerjisi oldukça pozitif ve huzurlu. İçsel dinginliğiniz rüyanıza yansımış durumda.\n');
    } else {
      buffer.writeln('Rüyanız sembolik bir dille bilinçaltınızdan size mesajlar veriyor. Olayları ve sembolleri bir bütün olarak incelediğimde şunları görüyorum:\n');
    }

    // 2. Sembollerin ve Eylemlerin Harmanlanması
    buffer.writeln('--- SEMBOLİK ANALİZ ---\n');
    
    for (int i = 0; i < bulunanSemboller.length; i++) {
      final sembol = bulunanSemboller[i];
      buffer.writeln('• ${sembol.anahtar.toUpperCase()}');
      
      // Sembolün temel yorumu
      buffer.writeln('${sembol.yorum}');
      
      // Eğer bu rüyada tespit edilen eylemler varsa, ilk sembolün altına akıcı bir şekilde bağla
      if (i == 0 && tespitEdilenEylemler.isNotEmpty) {
        buffer.writeln('\nRüyanızdaki eylemlerin analizi:');
        for (var eylem in tespitEdilenEylemler) {
          buffer.writeln('- $eylem');
        }
      }
      buffer.writeln();
    }

    // 3. Kapanış (Usta Yorumu)
    buffer.writeln('--- GENEL DEĞERLENDİRME ---');
    buffer.writeln('Unutmayın, rüyalar birer kehanet değil, ruhumuzun aynasıdır. Size tavsiyem, bu yorumları birer kesin gerçek olarak görmek yerine, kendi içinize dönüp düşünmeniz için bir fırsat bilmenizdir. Bilinçaltınız size ne anlatmaya çalışıyor? Hangi duygularınızı bastırıyorsunuz?');
    buffer.writeln('\nNot: Bu yorumlar geleneksel İslami tabirler ve temel psikolojik sembolizm esas alınarak, tamamen yerel (cihaz içi) bir analiz motoruyla hazırlanmıştır. Dini kesin hükümler veya tıbbi teşhisler içermez.');

    return buffer.toString();
  }
}
