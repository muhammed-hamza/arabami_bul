import 'package:google_generative_ai/google_generative_ai.dart';
import 'main.dart';
import 'dart:convert';  
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'araba_verileri.dart';
import 'package:arabami_bul/car.dart'; 

const String GEMINI_API_KEY = "AIzaSyDAnlpGN6L0WSrhdLzfe7q8TPYpWVAtk1g";
Future<String?> ModelFunction(List<Car> cars) async {
  try {
    print('Yapay zeka analizi başlıyor...');
    print('Toplam analiz edilecek ilan sayısı: ${cars.length}');

    String carDetails = cars.map((car) => '''
      İlan: ${car.title}
      Fiyat: ${car.price}
      Yıl: ${car.year}
      KM: ${car.km}
      Renk: ${car.color}
      Şehir: ${car.city}
      Açıklama: ${car.description}
    ''').join('\n---\n');

    print('İlanlar birleştirildi, API\'ye gönderiliyor...');

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [{
          'parts': [{
            'text': '''
              Sen bir araç alım-satım uzmanısın. Verilen araç ilanlarını detaylı bir şekilde analiz et ve alıcılar için kapsamlı bir rapor hazırla.
              
              Şu başlıklar altında değerlendirme yap:
              
              1. GENEL PAZAR ANALİZİ
              - İlanların genel fiyat aralığı
              - Ortalama model yılı ve kilometre
              - Fiyat/performans değerlendirmesi
              
              2. ÖNE ÇIKAN İLANLAR
              - En iyi fiyat/performans oranına sahip 2-3 ilan
              - Bu ilanların neden öne çıktığına dair açıklama
              
              3. DİKKAT EDİLMESİ GEREKEN NOKTALAR
              - Boya/değişen durumları
              - Kilometre analizi
              - Fiyat sapmaları
              
              4. TAVSİYELER
              - Hangi ilanların değerlendirmeye alınması gerektiği
              - Pazarlık payı ve dikkat edilmesi gereken noktalar
              - Alım için en uygun zamanla ilgili öneriler

              5. SENİN ÖNERDİĞİN ARABALARI SIRALA
              
              İşte analiz edilecek ilanlar:
              
              $carDetails
            '''
          }]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2000,
        },
      }),
    );

    print('API yanıtı alındı. Status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final analysis = data['candidates'][0]['content']['parts'][0]['text'];
      
      print('YAPAY ZEKA ANALİZİ:');
      print('------------------');
      print(analysis);
      print('------------------');
      
      return analysis;
    } else {
      print('API hatası: ${response.statusCode}');
      print('Hata detayı: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Generate hatası: $e');
    return null;
  }
}
Future<String> fetchUrlContent(String url) async {
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };
  
  final res = await http.get(Uri.parse(url));
  final body = res.body;
  final document = parser.parse(body);
  var response = document.getElementsByClassName("listing-table-wrapper")[0].getElementsByClassName("listing-list-item should-hover bg-white")[1].
  attributes["listing-price"];
  var priceElement = document.querySelector(".listing-price");
  print("araba verileri: ${response.toString()}");

  if (res.statusCode == 200) {
    return res.toString(); // HTML içeriği
  } else {
    throw Exception('Failed to load content: ${res.statusCode}');
  }
}
