import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'database_helper.dart';
import 'car.dart';
import 'recommended_cars_page.dart';
import 'test_page.dart';
import 'generate.dart';
import 'filter_drawer.dart';

class SubModel {
  final String name;
  final String url;
  final String count; // İlan sayısı

  SubModel({
    required this.name,
    required this.url,
    required this.count,
  });
}

class CarListPage extends StatefulWidget {
  final String title;
  final String baseUrl;

  const CarListPage({
    Key? key,
    required this.title,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _CarListPageState createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Car> cars = [];
  List<Car> filteredCars = [];
  bool isLoading = false;
  bool isAIAnalysisLoading = false;
  Set<int> expandedCards = {};
  Set<String> selectedCities = {};
  Set<String> availableCities = {};
  List<SubModel> subModels = [];
  final TextEditingController minKmController = TextEditingController();
  final TextEditingController maxKmController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  RangeValues? kmRange;
  RangeValues? priceRange;
  Map<String, bool> expandedModels = {}; // Alt modellerin açık/kapalı durumu

  @override
  void initState() {
    super.initState();
    fetchSubModels();
    fetchCarData();
  }

  @override
  void dispose() {
    minKmController.dispose();
    maxKmController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<void> fetchSubModels() async {
    try {
      final baseUrl = widget.baseUrl.startsWith('http')
          ? widget.baseUrl
          : 'https://www.arabam.com${widget.baseUrl}';

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = parse(response.body);
        List<SubModel> models = [];

        // Alt modelleri çek
        final modelElements = document
            .querySelectorAll('.category-list-wrapper .inner-list > li');
        for (var element in modelElements) {
          final linkElement = element.querySelector('a');
          if (linkElement != null) {
            final name =
                linkElement.querySelector('.list-name')?.text.trim() ?? '';
            final url = linkElement.attributes['href'] ?? '';
            final countText = linkElement.text.replaceAll(name, '').trim();
            final count = RegExp(r'\d+').firstMatch(countText)?.group(0) ?? '0';

            if (name.isNotEmpty && url.isNotEmpty) {
              models.add(SubModel(
                name: name,
                url: url,
                count: count,
              ));
            }
          }
        }

        setState(() {
          subModels = models;
        });
      }
    } catch (e) {
      print('Alt model çekme hatası: $e');
    }
  }

  Future<void> fetchCarData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = widget.baseUrl.startsWith('http')
          ? widget.baseUrl
          : 'https://www.arabam.com${widget.baseUrl}';

      print('Başlangıç URL: $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = parse(response.body);

        // Toplam ilan sayısını doğru selector ile al
        final countElement = document.querySelector('#js-hook-for-total-count');
        int totalAds = 0;
        if (countElement != null) {
          String countText = countElement.text.trim();
          totalAds =
              int.tryParse(countText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          print('Toplam ilan sayısı: $totalAds');
        } else {
          // Alternatif selector dene
          final altCountElement = document.querySelector('.listing-text span');
          if (altCountElement != null) {
            String countText = altCountElement.text.trim();
            totalAds =
                int.tryParse(countText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            print('Toplam ilan sayısı (alternatif): $totalAds');
          }
        }

        int totalPages = (totalAds / 50).ceil();
        print('Toplam sayfa sayısı: $totalPages');

        // En az 1 sayfa olmalı
        totalPages = totalPages > 0 ? totalPages : 1;

        List<Car> tempCars = [];

        for (int page = 1; page <= totalPages; page++) {
          final pageUrl = page == 1
              ? baseUrl
              : '$baseUrl${baseUrl.contains('?') ? '&' : '?'}page=$page';

          print('İşlenen sayfa $page URL: $pageUrl');

          final pageResponse = await http.get(
            Uri.parse(pageUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            },
          );

          if (pageResponse.statusCode == 200) {
            final pageDocument = parse(pageResponse.body);
            final carElements =
                pageDocument.querySelectorAll('.listing-list-item');
            print('Bulunan ilan sayısı: ${carElements.length}');

            for (var element in carElements) {
              try {
                final titleElement = element
                        .querySelector('.listing-text-new.listing-title-lines')
                        ?.text
                        .trim() ??
                    '';
                final priceElement =
                    element.querySelector('.listing-price')?.text.trim() ?? '';
                final yearElement = element
                        .querySelectorAll(
                            '.listing-text .fade-out-content-wrapper')[0]
                        ?.text
                        .trim() ??
                    '';
                final kmElement = element
                        .querySelectorAll(
                            '.listing-text .fade-out-content-wrapper')[1]
                        ?.text
                        .trim() ??
                    '';

                String colorElement = '';
                final colorElements = element.querySelectorAll(
                    '.listing-text .fade-out-content-wrapper');
                if (colorElements.length > 2) {
                  colorElement = colorElements[2].text.trim();
                }

                String cityElement = '';
                final citySpans = element.querySelectorAll('span[title]');
                if (citySpans.length >= 2) {
                  final city = citySpans[0].text.trim();
                  final district = citySpans[1].text.trim();
                  cityElement = '$city $district'.trim();
                }

                final listingDateElement = element
                        .querySelector(
                            '.listing-text.tac .fade-out-content-wrapper')
                        ?.text
                        .trim() ??
                    '';
                final detailUrl = element
                        .querySelector('a.link-overlay')
                        ?.attributes['href'] ??
                    '';

                String description = '';
                if (detailUrl.isNotEmpty) {
                  try {
                    description = await fetchCarDescription(
                        'https://www.arabam.com$detailUrl');
                  } catch (e) {
                    print('Detay bilgisi çekilirken hata: $e');
                  }
                }

                tempCars.add(Car(
                  title: titleElement,
                  price: priceElement,
                  year: yearElement,
                  km: kmElement,
                  color: colorElement,
                  city: cityElement,
                  listingDate: listingDateElement,
                  description: description,
                  detailUrl: detailUrl,
                ));
              } catch (e) {
                print('İlan işlenirken hata: $e');
              }
            }
          }

          if (page < totalPages) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        // Veritabanını güncelle
        await DatabaseHelper.instance.syncCars(tempCars);

        // Güncel verileri veritabanından çek
        final updatedCars = await DatabaseHelper.instance.getCars();
        setState(() {
          cars = updatedCars;
          updateAvailableCities();
          applyFilters();
        });
      }
    } catch (e) {
      print('Hata oluştu: $e');
      final dbCars = await DatabaseHelper.instance.getCars();
      setState(() {
        cars = dbCars;
        updateAvailableCities();
        applyFilters();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> fetchCarDescription(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);

        String mainDescription = '';
        final descriptionDiv = document.querySelector('#tab-description');
        if (descriptionDiv != null) {
          mainDescription = descriptionDiv.text.trim();
        }

        String expertInfo = '';
        final expertDiv =
            document.querySelector('.expert-information-container');
        if (expertDiv != null) {
          String expertText = expertDiv.text;

          if (expertText.isNotEmpty &&
              !expertText.contains('Ekspertiz bilgisi bulunamadı')) {
            final lines = expertText
                .split('\n')
                .map((line) => line.trim())
                .where((line) =>
                    line.isNotEmpty &&
                    !line.contains('arabam.com') &&
                    !line.contains('Ekspertiz') &&
                    !line.contains('Paketleri') &&
                    !line.contains('Şubeleri'))
                .toList();

            final uniqueLines = lines.toSet().toList();
            if (uniqueLines.isNotEmpty) {
              expertInfo = '\n\nBoya - Değişen:\n' + uniqueLines.join('\n');
            }
          }
        }

        return cleanText(mainDescription + expertInfo);
      }
      return '';
    } catch (e) {
      print('Açıklama çekilirken hata: $e');
      return '';
    }
  }

  String cleanText(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ZeroWidthSpace;', '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .trim();
  }

  void updateAvailableCities() {
    availableCities = cars.map((car) => car.city.split(' ')[0]).toSet();
  }

  void applyFilters() {
    setState(() {
      filteredCars = cars.where((car) {
        // KM filtreleme
        if (minKmController.text.isNotEmpty ||
            maxKmController.text.isNotEmpty) {
          final carKm = double.tryParse(car.km
                  .replaceAll('km', '')
                  .replaceAll('.', '')
                  .replaceAll(' ', '')
                  .trim()) ??
              0;

          if (minKmController.text.isNotEmpty) {
            final minKm = double.tryParse(minKmController.text) ?? 0;
            if (carKm < minKm) return false;
          }
          if (maxKmController.text.isNotEmpty) {
            final maxKm = double.tryParse(maxKmController.text) ?? 0;
            if (carKm > maxKm) return false;
          }
        }

        // Fiyat filtreleme
        if (minPriceController.text.isNotEmpty ||
            maxPriceController.text.isNotEmpty) {
          final carPrice = double.tryParse(car.price
                  .replaceAll('TL', '')
                  .replaceAll('.', '')
                  .replaceAll(' ', '')
                  .trim()) ??
              0;

          if (minPriceController.text.isNotEmpty) {
            final minPrice = double.tryParse(minPriceController.text) ?? 0;
            if (carPrice < minPrice) return false;
          }

          if (maxPriceController.text.isNotEmpty) {
            final maxPrice = double.tryParse(maxPriceController.text) ?? 0;
            if (carPrice > maxPrice) return false;
          }
        }

        // Şehir filtreleme
        if (selectedCities.isNotEmpty && !selectedCities.contains(car.city)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void onAIAnalysisPressed() async {
    setState(() {
      isLoading = true;
      isAIAnalysisLoading = true;
    });

    try {
      print('AI analizi başlatılıyor...');
      final analysis = await ModelFunction(filteredCars);
      print('AI analizi tamamlandı');

      if (analysis != null) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendedCarsPage(
              recommendedCars: filteredCars,
              aiAnalysis: analysis,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yapay zeka analizi alınamadı')),
        );
      }
    } catch (e) {
      print('AI analizi sırasında hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Yapay zeka analizi sırasında hata oluştu')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isAIAnalysisLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          tooltip: 'Ana Sayfa',
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            tooltip: 'Filtrele',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: isLoading ? null : onAIAnalysisPressed,
            tooltip: 'AI Analizi',
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: FilterDrawer(
        cars: cars,
        onFiltersChanged: (List<Car> newFilteredCars) {
          if (mounted) {
            setState(() {
              filteredCars = newFilteredCars;
            });
          }
        },
        selectedCities: selectedCities,
        minKmController: minKmController,
        maxKmController: maxKmController,
        minPriceController: minPriceController,
        maxPriceController: maxPriceController,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    isAIAnalysisLoading
                        ? "Yapay zeka değerlendiriyor..."
                        : "Araba verileri yükleniyor...",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredCars.length,
              itemBuilder: (context, index) {
                final car = filteredCars[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      car.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(car.year),
                            const Text(' | '),
                            Text(car.km),
                            const Text(' | '),
                            Text(car.city),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.price,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      if (car.color.isNotEmpty || car.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (car.color.isNotEmpty)
                                Text('Renk: ${car.color}'),
                              if (car.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(car.description),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Alt modelleri gösteren widget
  Widget _buildSubModels(String brandName, List<SubModel> models) {
    return ExpansionTile(
      title: Text(
        brandName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onExpansionChanged: (expanded) {
        setState(() {
          expandedModels[brandName] = expanded;
        });
      },
      children: models
          .map((model) => ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(model.name),
                    Text(
                      model.count,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarListPage(
                        title: '${widget.title} ${model.name}',
                        baseUrl: model.url,
                      ),
                    ),
                  );
                },
              ))
          .toList(),
    );
  }
}
