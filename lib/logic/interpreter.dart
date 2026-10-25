import '../data/symbols.dart';

class Interpreter {
  static String yorumla(String metin) {
    final kucukMetin = metin.toLowerCase();
    
    // Noktalama işaretlerini boşlukla değiştirip kelimelere ayırıyoruz
    final temizMetin = kucukMetin.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final kelimeler = temizMetin.split(RegExp(r'\s+'));
    
    final List<Ruyasembolu> bulunanlar = [];

    for (final sembol in tumSemboller) {
      for (final eslesen in sembol.eslesenKelimeler) {
        bool bulundu = false;
        
        for (final kelime in kelimeler) {
          if (kelime.isEmpty) continue;
          
          // Eğer aranan kelime (ör: 'uç'), cümledeki kelimenin başındaysa (ör: 'uçmak', 'uçtu') eşleştir.
          // Ayrıca tam eşleşme varsa da eşleştir.
          if (kelime == eslesen || kelime.startsWith(eslesen)) {
            bulundu = true;
            break;
          }
        }
        
        if (bulundu) {
          if (!bulunanlar.contains(sembol)) {
            bulunanlar.add(sembol);
          }
          break;
        }
      }
    }

    if (bulunanlar.isEmpty) {
      return 'Rüyanızda bilinen bir sembol tespit edilemedi. Lütfen rüyanızı daha detaylı anlatın veya farklı kelimeler kullanın.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Rüyanızda şu semboller tespit edildi:\n');

    for (int i = 0; i < bulunanlar.length; i++) {
      buffer.writeln('${i + 1}. ${bulunanlar[i].yorum}\n');
    }

    buffer.writeln('---');
    buffer.writeln('Not: Bu yorumlar geleneksel İslami tabir geleneğine dayanmaktadır ve sadece eğlence amaçlıdır. Gerçek bir fal değildir.');

    return buffer.toString();
  }
}
