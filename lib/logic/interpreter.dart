import '../data/symbols.dart';

class Interpreter {
  static String yorumla(String metin) {
    final kucukMetin = metin.toLowerCase();
    final List<RüyaSembolü> bulunanlar = [];

    for (final sembol in tumSemboller) {
      for (final kelime in sembol.eslesenKelimeler) {
        if (kucukMetin.contains(kelime.toLowerCase())) {
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
