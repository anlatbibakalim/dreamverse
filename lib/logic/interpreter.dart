import '../data/symbols.dart';

// 1. ADIM: Duygu ve Yoğunluk Sözlükleri
final Map<String, double> korkuKelimeleri = {
  'korku': 2, 'korktum': 2, 'korkuyorum': 2, 'kabus': 3, 'dehşet': 3,
  'kaçtım': 2, 'kaçıyordum': 2, 'saldırdı': 3, 'tehlike': 2, 'ürktüm': 2
};

final Map<String, double> huzunKelimeleri = {
  'hüzün': 2, 'ağladım': 2, 'ağlıyordum': 2, 'üzgün': 2, 'kaybettim': 3, 'ayrılık': 2
};

final Map<String, double> mutlulukKelimeleri = {
  'mutlu': 2, 'sevinç': 2, 'güldüm': 2, 'huzur': 2, 'başarı': 2, 'sevdim': 1
};

final Map<String, double> yogunlukKelimeleri = {
  'çok': 1.5, 'çook': 2, 'aşırı': 2, 'dehşet': 2, 'biraz': 0.7, 'hafif': 0.6
};

final List<String> olumsuzluklar = [
  'değil', 'değildi', 'yok', 'yoktu', 'görmedim', 'olmadı', 'korkmuyorum', 'korkmadım', 'hiç'
];

// 2. ADIM: Eylem Sözlüğü
final Map<String, String> eylemYorumlari = {
  'kovalamak': 'Kaçınan veya yüzleşmekten çekindiğiniz bir konu sizi takip ediyor.',
  'kovaladı': 'Kaçınan veya yüzleşmekten çekindiğiniz bir konu sizi takip ediyor.',
  'kovalıyordu': 'Kaçınan veya yüzleşmekten çekindiğiniz bir konu sizi takip ediyor.',
  'ölmek': 'Bir dönemin, ilişkinin ya da alışkanlığın sona ermesi sembolize ediliyor.',
  'öldü': 'Bir dönemin, ilişkinin ya da alışkanlığın sona ermesi sembolize ediliyor.',
  'uçmak': 'Özgürlük, kontrol ve hedeflerinize ulaşma arzusu öne çıkıyor.',
  'uçtum': 'Özgürlük, kontrol ve hedeflerinize ulaşma arzusu öne çıkıyor.',
  'kaybetmek': 'Değer verdiğiniz bir şeyin kontrolünüzden çıktığı hissi var.',
  'kaybettim': 'Değer verdiğiniz bir şeyin kontrolünüzden çıktığı hissi var.',
  'ağlamak': 'Bastırılmış bir üzüntünün ifade bulmaya çalıştığını gösterir.',
  'ağladım': 'Bastırılmış bir üzüntünün ifade bulmaya çalıştığını gösterir.'
};

class Interpreter {
  static String yorumla(String metin) {
    final kucukMetin = metin.toLowerCase();
    final temizMetin = kucukMetin.replaceAll(RegExp(r'[^\w\sğüşıöç]'), ' ');
    final kelimeler = temizMetin.split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
    
    final List<Ruyasembolu> bulunanlar = [];
    final Set<String> bulunanAnahtarlar = {};
    final List<String> bulunanEylemler = [];

    // 3. ADIM: Kök Bulucu (Önceki dersteki gibi geniş)
    String kokBul(String k) {
      if (k.length <= 3) return k;
      if (k.endsWith('ğı') || k.endsWith('ği')) return k.substring(0, k.length - 2) + 'k';
      if (k.endsWith('lar') || k.endsWith('ler')) return k.substring(0, k.length - 3);
      if (k.endsWith('ı') || k.endsWith('i') || k.endsWith('u') || k.endsWith('ü')) return k.substring(0, k.length - 1);
      if (k.endsWith('yor') || k.endsWith('yordu') || k.endsWith('yorum')) return k.substring(0, k.length - 4);
      if (k.endsWith('dı') || k.endsWith('di')) return k.substring(0, k.length - 2);
      return k;
    }

    // 4. ADIM: Sembolleri ve Eylemleri Bul
    for (final sembol in tumSemboller) {
      for (final eslesen in sembol.eslesenKelimeler) {
        bool bulundu = false;
        for (int i = 0; i < kelimeler.length; i++) {
          final kelime = kelimeler[i];
          final kok = kokBul(kelime);

          if (kelime == eslesen || kok == eslesen || (eslesen.length >= 4 && kelime.contains(eslesen))) {
            
            // Olumsuzluk Penceresi Kontrolü
            final baslangic = (i - 4).clamp(0, kelimeler.length);
            final pencere = kelimeler.sublist(baslangic, (i + 2).clamp(0, kelimeler.length)).join(' ');
            bool olumsuzMu = olumsuzluklar.any((o) => pencere.contains(o));

            if (!olumsuzMu) {
              if (!bulunanAnahtarlar.contains(sembol.anahtar)) {
                bulunanlar.add(sembol);
                bulunanAnahtarlar.add(sembol.anahtar);
              }
              
              // Eylem var mı bak (sembolün etrafındaki kelimelerde)
              for (int j = (i - 2).clamp(0, kelimeler.length); j < (i + 3).clamp(0, kelimeler.length); j++) {
                final eylem = eylemYorumlari.keys.firstWhere((e) => kelimeler[j].contains(e), orElse: () => '');
                if (eylem.isNotEmpty && !bulunanEylemler.contains(eylemYorumlari[eylem]!)) {
                  bulunanEylemler.add(eylemYorumlari[eylem]!);
                }
              }
            }
            bulundu = true;
            break;
          }
        }
        if (bulundu) break;
      }
    }

    if (bulunanlar.isEmpty) {
      return 'Rüyanızda bilinen belirgin bir sembol tespit edilemedi. Ancak bilinçaltınız size bir mesaj vermeye çalışıyor olabilir. Lütfen rüyanızı daha detaylı anlatın veya farklı kelimeler kullanın. (İpucu: Su, yılan, uçmak, ev, saç gibi net semboller kullanmayı deneyin.)';
    }

    // 5. ADIM: Duygu Puanlaması
    double korkuSkor = 0, huzunSkor = 0, mutlulukSkor = 0;
    for (final kelime in kelimeler) {
      if (korkuKelimeleri.containsKey(kelime)) korkuSkor += korkuKelimeleri[kelime]!;
      if (huzunKelimeleri.containsKey(kelime)) huzunSkor += huzunKelimeleri[kelime]!;
      if (mutlulukKelimeleri.containsKey(kelime)) mutlulukSkor += mutlulukKelimeleri[kelime]!;
    }

    // Yoğunluk çarpanı
    for (final kelime in kelimeler) {
      if (yogunlukKelimeleri.containsKey(kelime)) {
        if (korkuSkor > 0) korkuSkor *= yogunlukKelimeleri[kelime]!;
        if (mutlulukSkor > 0) mutlulukSkor *= yogunlukKelimeleri[kelime]!;
      }
    }

    // 6. ADIM: Metni İnşa Et
    final buffer = StringBuffer();
    
    // Giriş
    if (korkuSkor >= 4) {
      buffer.writeln('Rüyanız belirgin bir tehdit ya da kontrol kaybı hissi taşıyor. Bilinçaltınız sizi güçlü bir şekilde uyarıyor.\n');
    } else if (korkuSkor >= 2) {
      buffer.writeln('Rüyanızda hafif bir endişe ve tedirginlik seziliyor. İçsel bir huzursuzluk yaşıyorsunuz.\n');
    } else if (mutlulukSkor > korkuSkor) {
      buffer.writeln('Rüyanızın genel tonu huzurlu ve umut verici. Pozitif enerjiniz dikkat çekiyor.\n');
    } else {
      buffer.writeln('Rüyanız daha çok sembolik ve düşündürücü bir atmosfer taşıyor. Bilinçaltınız size mesajlar veriyor.\n');
    }

    // Semboller
    for (int i = 0; i < bulunanlar.length; i++) {
      buffer.writeln('${i + 1}. ${bulunanlar[i].anahtar.toUpperCase()}');
      buffer.writeln('${bulunanlar[i].yorum}');
      
      if (bulunanEylemler.isNotEmpty && i == 0) {
        // Eylemleri ilk sembole bağlayalım
        buffer.writeln('\nRüyanızdaki eylemlerin analizi: ${bulunanEylemler.join(' ')}');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('Usta Yorumu: Rüyalar, ruhumuzun aynasıdır. Size tavsiyem, bu yorumları birer kesin kehanet olarak görmek yerine, kendi içinize dönüp düşünmeniz için bir fırsat bilmenizdir. Bilinçaltınız size ne anlatmaya çalışıyor? Hangi duygularınızı bastırıyorsunuz veya hangi fırsatları görmezden geliyorsunuz? Unutmayın, rüyaların asıl gücü, size kendinizi hatırlatmasıdır.');
    buffer.writeln('\nNot: Bu yorumlar geleneksel İslami tabir geleneği ve temel psikolojik sembolizm esas alınarak hazırlanmıştır. Sadece eğlence ve farkındalık amaçlıdır. Bilimsel veya tıbbi bir teşhis niteliği taşımaz.');

    return buffer.toString();
  }
}
