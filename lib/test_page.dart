import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String resultText = '';
  bool isLoading = false;
  List<Map<String, String>> ilanlar = [];
  int toplamIlan = 0;
  int currentPage = 1;

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      resultText = 'Veriler çekiliyor...';
      ilanlar.clear();
    });

    try {
      // İlk sayfayı çek ve toplam ilan sayısını al
      final firstPageResponse = await http.get(
        Uri.parse('https://www.sahibinden.com/hyundai-accent-1-3-admire?take=50&page=1'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (firstPageResponse.statusCode == 200) {
        final document = parse(firstPageResponse.body);
        
        // Toplam ilan sayısını al
        final countElement = document.querySelector('.count');
        if (countElement != null) {
          toplamIlan = int.tryParse(countElement.text.trim()) ?? 0;
        }

        // Toplam sayfa sayısını hesapla (her sayfada 50 ilan)
        final totalPages = (toplamIlan / 50).ceil();

        setState(() {
          resultText = 'Toplam $toplamIlan ilan bulundu. Veriler çekiliyor...';
        });

        // Tüm sayfaları dolaş
        for (int page = 1; page <= totalPages; page++) {
          setState(() {
            resultText = 'Sayfa $page/$totalPages çekiliyor...';
            currentPage = page;
          });

          final pageResponse = await http.get(
            Uri.parse('https://www.sahibinden.com/hyundai-accent-1-3-admire?take=50&page=$page'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            },
          );

          if (pageResponse.statusCode == 200) {
            final pageDocument = parse(pageResponse.body);
            final ilanListesi = pageDocument.querySelectorAll('tr.searchResultsItem');

            for (var ilan in ilanListesi) {
              try {
                final baslik = ilan.querySelector('a.classifiedTitle')?.text.trim() ?? 'Başlık bulunamadı';
                final km = ilan.querySelectorAll('td.searchResultsAttributeValue')[1].text.trim();
                final fiyat = ilan.querySelector('td.searchResultsPriceValue span')?.text.trim() ?? 'Fiyat bulunamadı';

                ilanlar.add({
                  'baslik': baslik,
                  'km': km,
                  'fiyat': fiyat,
                });
              } catch (e) {
                print('İlan ayrıştırma hatası: $e');
              }
            }

            // Her sayfadan sonra sonuçları güncelle
            setState(() {
              resultText = 'Toplam ${ilanlar.length} ilan çekildi (Sayfa $page/$totalPages)\n\n' +
                ilanlar.map((ilan) =>
                  'Başlık: ${ilan['baslik']}\n'
                  'KM: ${ilan['km']}\n'
                  'Fiyat: ${ilan['fiyat']}\n'
                  '------------------------'
                ).join('\n');
            });

            // Sayfalar arası bekle
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      } else {
        setState(() {
          resultText = 'Hata: ${firstPageResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        resultText = 'Hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahibinden.com Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : fetchData,
                  child: Text(isLoading ? 'Yükleniyor...' : 'İlanları Çek'),
                ),
                if (isLoading) Text('Sayfa: $currentPage'),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text('${ilanlar.length} ilan çekildi'),
                ],
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    resultText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 