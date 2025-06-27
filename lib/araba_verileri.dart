import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

import 'generate.dart';
import 'recommended_cars_page.dart';
import 'database_helper.dart';
import 'filter_drawer.dart';
import 'test_page.dart';
import 'car.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Araba Sayısı:'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Car> cars = []; // Araç verilerini tutacak liste
  List<Car> filteredCars = []; // Filtrelenmiş araçlar
  bool isLoading = false;
  Set<int> expandedCards = {};

  // Filtre değerleri
  double minKm = 0;
  double maxKm = 500000;
  double minPrice = 0;
  double maxPrice = 1000000;

  // TextEditingController'lar
  final TextEditingController minKmController = TextEditingController();
  final TextEditingController maxKmController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // İl filtreleme için değişkenler
  Set<String> selectedCities = {}; // Seçili iller
  Set<String> availableCities = {}; // Mevcut tüm iller

  @override
  void initState() {
    super.initState();
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

  void applyFilters() {
    setState(() {
      filteredCars = cars.where((car) {
        final kmInRange =
            (double.tryParse(car.km.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) >=
                    minKm &&
                (double.tryParse(car.km.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0) <=
                    maxKm;

        final priceInRange =
            (double.tryParse(car.price.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0) >=
                    minPrice &&
                (double.tryParse(car.price.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0) <=
                    maxPrice;

        // İl filtresi ekle
        final cityMatch = selectedCities.isEmpty ||
            selectedCities.contains(car.city.split(' ')[0]);

        return kmInRange && priceInRange && cityMatch;
      }).toList();
    });
  }

  // Mevcut illeri güncelle
  void updateAvailableCities() {
    availableCities = cars.map((car) => car.city.split(' ')[0]).toSet();
  }

  Future<void> fetchCarData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Önce veritabanından mevcut verileri yükle
      final dbCars = await DatabaseHelper.instance.getCars();
      setState(() {
        cars = dbCars;
        updateAvailableCities();
        applyFilters();
      });

      final baseUrl =
          'https://www.arabam.com/ikinci-el/otomobil/hyundai-accent-1-3-admire?take=50';
      final firstResponse = await http.get(Uri.parse(baseUrl));

      if (firstResponse.statusCode == 200) {
        final document = parse(firstResponse.body);

        // Toplam ilan sayısını doğru selector ile al
        final countElement =
            document.querySelector('#js-hook-for-advert-count');
        int totalAds = 0;
        if (countElement != null) {
          String countText = countElement.text.trim();
          totalAds = int.tryParse(countText) ?? 0;
          print('Toplam ilan sayısı: $totalAds');
        }

        int totalPages = (totalAds / 50).ceil();
        print('Toplam sayfa sayısı: $totalPages');
        List<Car> tempCars = [];

        for (int page = 1; page <= totalPages; page++) {
          print('Sayfa $page çekiliyor...');
          final pageUrl = page == 1 ? baseUrl : '$baseUrl&page=$page';
          final response = await http.get(Uri.parse(pageUrl));

          if (response.statusCode == 200) {
            final pageDocument = parse(response.body);
            final carElements =
                pageDocument.querySelectorAll('tr.listing-list-item');

            for (var element in carElements) {
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
              final colorElements = element
                  .querySelectorAll('.listing-text .fade-out-content-wrapper');
              if (colorElements.length > 2) {
                colorElement = colorElements[2].text.trim();
              }

              String cityElement = '';
              try {
                final citySpans = element.querySelectorAll('span[title]');
                if (citySpans.length >= 2) {
                  final city = citySpans[0].text.trim();
                  final district = citySpans[1].text.trim();
                  cityElement = '$city $district'.trim();
                }
              } catch (e) {
                print('İl bilgisi çekilirken hata: $e');
              }

              final listingDateElement = element
                      .querySelector(
                          '.listing-text.tac .fade-out-content-wrapper')
                      ?.text
                      .trim() ??
                  '';

              final detailUrl =
                  element.querySelector('a.link-overlay')?.attributes['href'] ??
                      '';

              String description = '';
              if (detailUrl.isNotEmpty) {
                try {
                  description = await fetchCarDescription(
                      'https://www.arabam.com$detailUrl', {});
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
            }
          }

          if (page < totalPages) {
            await Future.delayed(Duration(seconds: 1));
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

  // Detay sayfasından açıklama çeken yeni fonksiyon
  Future<String> fetchCarDescription(
      String url, Map<String, String> headers) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);

        // Ana açıklama metnini al
        String mainDescription = '';
        final descriptionDiv = document.querySelector('#tab-description');
        if (descriptionDiv != null) {
          mainDescription = descriptionDiv.text.trim();
          // "Paketleri ve Şubeleri Gör" metnini ve benzeri metinleri temizle
          mainDescription = mainDescription
              .replaceAll('Paketleri ve Şubeleri Gör', '')
              .replaceAll('Paketleri Gör', '')
              .replaceAll('Şubeleri Gör', '')
              .trim();
        }

        // Boya ve değişen bilgilerini al
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

        // Bilgileri birleştir
        String fullDescription = mainDescription + expertInfo;

        return cleanText(fullDescription);
      }
      return '';
    } catch (e) {
      print('Açıklama çekilirken hata: $e');
      return '';
    }
  }

  // Metni temizleyen yardımcı fonksiyon
  String cleanText(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ZeroWidthSpace;', '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll('..', '.')
//        .replaceAll('Orijinal Boyal Orijinal Boyalı', 'Orijinal Boyalı')
        //      .replaceAll('Lokal Boyalı Lokal Boyalı', 'Lokal Boyalı')
        //    .replaceAll('Boyalı Boyalı', 'Boyalı')
        //  .replaceAll('Değişmiş Değişmiş', 'Değişmiş')
        //.replaceAll('Boya - Degisen:', '')
        //.replaceAll(RegExp(r'Boya - Değişen:.*$', multiLine: true), '')
        .trim();
  }

  // Binlik ayırıcı formatlama fonksiyonu
  String formatNumber(String value) {
    if (value.isEmpty) return '';

    // Sadece sayıları al
    value = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Sayıyı parse et
    int? number = int.tryParse(value);
    if (number == null) return '';

    // Binlik ayırıcıları ekle
    final parts = [];
    while (value.length > 3) {
      parts.insert(0, value.substring(value.length - 3));
      value = value.substring(0, value.length - 3);
    }
    if (value.isNotEmpty) {
      parts.insert(0, value);
    }

    return parts.join('.');
  }

  // TextField değer güncelleme fonksiyonu
  void updateTextFieldValue(TextEditingController controller, String newValue,
      Function(double) onUpdate) {
    final cleanValue = newValue.replaceAll('.', '');
    final formattedValue = formatNumber(cleanValue);

    // Cursor pozisyonunu hesapla
    final cursorPosition = controller.selection.start ?? 0;
    final dotCount = '.'.allMatches(controller.text).length;
    final newDotCount = '.'.allMatches(formattedValue).length;
    final offset = newDotCount - dotCount;

    controller.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(
        offset: cursorPosition + offset,
      ),
    );

    // Değeri güncelle
    onUpdate(double.tryParse(cleanValue) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title + "  " + filteredCars.length.toString()),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () async {
              if (filteredCars.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Filtrelenmiş araç bulunamadı!')),
                );
                return;
              }

              setState(() {
                isLoading = true;
              });

              try {
                final result = await ModelFunction(filteredCars);
                if (result != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecommendedCarsPage(
                        recommendedCars: filteredCars,
                        aiAnalysis: result,
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata oluştu: $e')),
                );
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestPage()),
              );
            },
            tooltip: 'Test Sayfası',
          ),
        ],
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
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchCarData();
        },
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Araba modelleri yükleniyor...",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredCars.length,
                itemBuilder: (context, index) {
                  final car = filteredCars[index];
                  final isExpanded = expandedCards.contains(index);

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            expandedCards.remove(index);
                          } else {
                            expandedCards.add(index);
                          }
                        });
                      },
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              car.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${car.year} | ${car.km}'),
                                    Text(
                                      car.price,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (car.color.isNotEmpty)
                                      Text(
                                        car.color,
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    if (car.color.isNotEmpty &&
                                        car.city.isNotEmpty)
                                      const Text(' | ',
                                          style: TextStyle(color: Colors.grey)),
                                    if (car.city.isNotEmpty)
                                      Text(
                                        car.city,
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  car.listingDate,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ),
                          if (isExpanded && car.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(car.description),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
