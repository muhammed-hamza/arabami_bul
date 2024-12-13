import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'car_list_page.dart'; // mevcut car_list_page'inizi import edin
import 'main.dart';

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

  @override
  void initState() {
    super.initState();
    fetchBrands();
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

        // HTML içeriğini kontrol et
        print(
            'HTML içeriği: ${document.body?.text.substring(0, 1000)}'); // İlk 1000 karakteri göster

        // Farklı selector'ler deneyelim
        final facetContainer = document.querySelector('.facet-container');
        final categoryFacet = document.querySelector('.category-facet');
        final innerList = document.querySelector('.inner-list');

        print('Facet Container bulundu: ${facetContainer != null}');
        print('Category Facet bulundu: ${categoryFacet != null}');
        print('Inner List bulundu: ${innerList != null}');

        // Tüm olası selector'leri dene
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
            print('- HTML: ${element.outerHtml}');
            print('- İsim: $name');
            print('- URL: $url');
            print('- Sayı (ham): $countText');

            // Sayıyı temizle ve parse et
            final count =
                int.tryParse(countText.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

            print('- Sayı (parse edilmiş): $count');

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarListPage(
                                title: '${brand.name} İlanları',
                                baseUrl: 'https://www.arabam.com${brand.url}',
                              ),
                            ),
                          );
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
