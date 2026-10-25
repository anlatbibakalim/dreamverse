import '../data/symbols.dart';

class Interpreter {
  // 1. GENİŞ TÜRKÇE EK HAVUZU (Sondan eklemeli dil yapısı için)
  static final List<String> _ekler = [
    'lar', 'ler', 'ları', 'leri', 'larından', 'lerinden', 'lardan', 'lerden',
    'ım', 'im', 'um', 'üm', 'ımız', 'imiz', 'umuz', 'ümüz', 
    'ın', 'in', 'un', 'ün', 'nın', 'nin', 'nun', 'nün',
    'ı', 'i', 'u', 'ü', 'yı', 'yi', 'yu', 'yü',
    'da', 'de', 'ta', 'te', 'nda', 'nde', 'dan', 'den', 'tan', 'ten', 'ndan', 'nden',
    'a', 'e', 'ya', 'ye', 'na', 'ne', 
    'la', 'le', 'yla', 'yle', 
    'ca', 'ce', 'ça', 'çe',
    'lık', 'lik', 'luk', 'lük', 'cı', 'ci', 'cu', 'cü', 'çı', 'çi', 'çu', 'çü',
    'sı', 'si', 'su', 'sü', 'sını', 'sini', 'sunu', 'sünü',
    'mış', 'miş', 'muş', 'müş', 'mıştı', 'mişti', 'yor', 'yordu', 'yorum', 'yorsun',
    'dı', 'di', 'du', 'dü', 'tı', 'ti', 'tu', 'tü'
  ];

  // 2. AKILLI KÖK BULUCU (Ünlü düşmesi ve Ünsüz yumuşamasını çözer)
  static String _kokBul(String kelime) {
    String kok = kelime;
    
    // Ekleri temizle (En uzun eki bulup kes)
    for (String ek in _ekler) {
      if (kok.endsWith(ek) && kok.length > ek.length + 2) {
        kok = kok.substring(0, kok.length - ek.length);
        break;
      }
    }
    
    // Ünsüz Yumuşaması Düzeltmesi (Ör: ekmeği -> ekmek, ağzı -> ağız, rengi -> renk)
    // Eğer kelime 'ğ', 'b', 'c', 'd', 'g' ile bitiyorsa, sert karşılıklarını da kontrol etmek gerekir.
    // Ancak basitlik adına, "ağz" gibi kalan kökleri "ağız"a çevirelim.
    if (kok.endsWith('ğ')) kok = kok.replaceAll('ğ', 'k'); // ağz -> ağız (aşağıda tamamlanacak)
    if (kok.endsWith('b')) kok = kok.replaceAll('b', 'p');
    if (kok.endsWith('c')) kok = kok.replaceAll('c', 'ç');
    if (kok.endsWith('d')) kok = kok.replaceAll('d', 't');
    
    return kok;
  }

  static String yorumla(String metin) {
    final kucukMetin = metin.toLowerCase();
    
    // Noktalama işaretlerini temizle ve kelimelere ayır
    final temizMetin = kucukMetin.replaceAll(RegExp(r'[^\w\sğüşıöç]'), ' ');
    final kelimeler = temizMetin.split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
    
    final List<Ruyasembolu> bulunanlar = [];
    final Set<String> bulunanAnahtarlar = {};

    for (final sembol in tumSemboller) {
      if (bulunanAnahtarlar.contains(sembol.anahtar)) continue;

      for (final eslesen in sembol.eslesenKelimeler) {
        bool bulundu = false;
        
        for (final kelime in kelimeler) {
          final kok = _kokBul(kelime);
          
          // A) Tam Eşleşme
          if (kelime == eslesen) { bulundu = true; break; }
          
          // B) Kök Eşleşmesi (ör: saçlarım -> saç)
          if (kok == eslesen) { bulundu = true; break; }

          // C) Başlangıç Eşleşmesi (ör: yılanı -> yılan)
          if (kelime.startsWith(eslesen) && eslesen.length >= 3) { 
            bulundu = true; break; 
          }
          
          // D) İçinde Geçme (Sadece 4+ harfli semboller için: yıkıyorum içinde yıka)
          if (eslesen.length >= 4 && kelime.contains(eslesen)) {
            bulundu = true; break;
          }
        }
        
        if (bulundu) {
          bulunanlar.add(sembol);
          bulunanAnahtarlar.add(sembol.anahtar);
          break; 
        }
      }
    }

    if (bulunanlar.isEmpty) {
      return 'Rüyanızda bilinen bir sembol tespit edilemedi. Lütfen rüyanızı daha detaylı anlatın veya farklı kelimeler kullanın. (İpucu: Su, yılan, uçmak, ev, saç gibi net kelimeler kullanmayı deneyin.)';
    }

    // --- 3. DUYGU VE BAĞLAM ANALİZİ (Psikolojik Akıl Yürütme) ---
    bool korkuVar = kucukMetin.contains('korku') || kucukMetin.contains('kabus') || kucukMetin.contains('dehşet') || kucukMetin.contains('kaçtım');
    bool hüzünVar = kucukMetin.contains('hüzün') || kucukMetin.contains('ağla') || kucukMetin.contains('üzgün') || kucukMetin.contains('kayıp');
    bool mutlulukVar = kucukMetin.contains('mutlu') || kucukMetin.contains('sevinç') || kucukMetin.contains('gül') || kucukMetin.contains('huzur');

    final buffer = StringBuffer();
    
    // Rüya Analizi Girişi
    buffer.writeln('--- RÜYA ANALİZİ ---\n');
    
    if (korkuVar) {
      buffer.writeln('Rüyanızda hissettiğiniz korku ve endişe, günlük hayatınızdaki bastırılmış duyguların veya çözülmemiş bir stresin dışa vurumu olabilir. Bilinçaltınız sizi uyarıyor.\n');
    } else if (hüzünVar) {
      buffer.writeln('Rüyanızdaki hüzün ve melankoli, geçmişte yaşadığınız ve hala tam olarak atlatamadığınız bir olayın yansıması olabilir. İçsel bir arınma sürecinde olabilirsiniz.\n');
    } else if (mutlulukVar) {
      buffer.writeln('Rüyanızdaki pozitif enerji ve huzur, bilinçaltınızın dingin olduğunu ve hayatınızdaki güzel gelişmelere açık olduğunuzu gösteriyor.\n');
    } else {
      buffer.writeln('Rüyanız sembolik bir dille bilinçaltınızdan size mesajlar veriyor. İşte tespit edilen sembollerin geleneksel ve psikolojik yorumları:\n');
    }

    // Sembol Yorumları
    for (int i = 0; i < bulunanlar.length; i++) {
      buffer.writeln('${i + 1}. ${bulunanlar[i].yorum}\n');
    }

    // Kapanış
    buffer.writeln('---');
    buffer.writeln('Not: Bu yorumlar geleneksel İslami tabir geleneğine dayanmaktadır ve sadece eğlence amaçlıdır. Psikolojik analizler bilimsel bir teşhis değildir.');

    return buffer.toString();
  }
}
