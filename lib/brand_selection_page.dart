import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'car_list_page.dart'; // mevcut car_list_page'inizi import edin

// Marka modeli
class Brand {
  final String name;
  final String url;
  final int count;

  Brand({
    required this.name,
    required this.url,
    required this.count,
  });
}

class BrandSelectionPage extends StatefulWidget {
  @override
  _BrandSelectionPageState createState() => _BrandSelectionPageState();
}

class _BrandSelectionPageState extends State<BrandSelectionPage> {
  bool isLoading = true;
  List<Brand> brands = [];
  String searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBrands() async {
    try {
      print('Markalar çekiliyor...'); // Debug için başlangıç mesajı

      final response = await http.get(
        Uri.parse('https://www.arabam.com/ikinci-el/otomobil?take=50'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        print('Sayfa başarıyla yüklendi'); // Debug için

        final document = parse(response.body);

        // Marka ve alt marka elementlerini seç
        final brandElements = document.querySelectorAll('li a.list-item');
        print('Bulunan marka elementleri: ${brandElements.length}');

        List<Brand> tempBrands = [];
        for (var element in brandElements) {
          try {
            final name = element.querySelector('.list-name')?.text.trim() ??
                element.text.trim().split(RegExp(r'\s+'))[0];
            final url = element.attributes['href'] ?? '';
            final countText = element.querySelector('.count')?.text.trim() ??
                element.text.trim().split(RegExp(r'\s+'))?.last ??
                '0';

            print('İşlenen element:');
            print('- İsim: $name');
            print('- URL: $url');
            print('- Sayı (ham): $countText');

            // Sayıyı temizle ve parse et
            final count =
                int.tryParse(countText.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

            if (name.isNotEmpty &&
                url.isNotEmpty &&
                !url.contains('javascript') &&
                count > 0) {
              tempBrands.add(Brand(
                name: name,
                url: url,
                count: count,
              ));
              print('Marka eklendi: $name ($count)');

              // Alt markaları çek
              await fetchSubModels(url);
            }
          } catch (e) {
            print('Element işlenirken hata: $e');
          }
        }

        setState(() {
          brands = tempBrands;
          isLoading = false;
        });

        print('İşlem tamamlandı. Toplam marka sayısı: ${brands.length}');
      } else {
        print('Sayfa yüklenemedi. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Genel hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Brand> get filteredBrands {
    if (searchQuery.isEmpty) {
      return brands;
    }
    return brands
        .where((brand) =>
            brand.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> fetchSubModels(String url) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.arabam.com${url}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = parse(response.body);

        // Alt modelleri seçmek için doğru CSS seçiciyi kullanın
        final subModelElements = document.querySelectorAll(
            '.category-list-wrapper .inner-list > li > a.list-item');

        if (subModelElements.isEmpty) {
          // Alternatif bir seçici deneyin
          final alternativeElements = document.querySelectorAll(
              'div[ss-container="true"] .inner-list > li > a.list-item');

          print('\nAlt Modeller (Alternatif):');
          for (var element in alternativeElements) {
            final name = element.querySelector('.list-name')?.text.trim() ?? '';
            final modelUrl = element.attributes['href'] ?? '';
            final countText =
                element.querySelector('.count')?.text.trim() ?? '0';
            final count =
                int.tryParse(countText.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

            if (name.isNotEmpty) {
              print('Model: $name - İlan Sayısı: $count - URL: $modelUrl');
            }
          }
        } else {
          print('\nAlt Modeller:');
          for (var element in subModelElements) {
            final name = element.querySelector('.list-name')?.text.trim() ?? '';
            final modelUrl = element.attributes['href'] ?? '';
            final countText =
                element.querySelector('.count')?.text.trim() ?? '0';
            final count =
                int.tryParse(countText.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

            if (name.isNotEmpty) {
              print('Model: $name - İlan Sayısı: $count - URL: $modelUrl');
            }
          }
        }
      } else {
        print('HTTP isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Alt modeller çekilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araba Markası Seçin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Marka Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredBrands.length,
                    itemBuilder: (context, index) {
                      final brand = filteredBrands[index];
                      return ListTile(
                        title: Text(brand.name),
                        trailing: Text(
                          '${brand.count} ilan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          // Önce alt modelleri çek ve yazdır
                          await fetchSubModels(brand.url);

                          // Sonra CarListPage'e git ve geri dönülmesini bekle
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarListPage(
                                title: '${brand.name} İlanları',
                                baseUrl: 'https://www.arabam.com${brand.url}',
                              ),
                            ),
                          );

                          // Geri dönüldüğünde arama alanını temizle
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
