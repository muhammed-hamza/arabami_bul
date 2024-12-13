import 'package:flutter/material.dart';

class FilterDrawer extends StatelessWidget {
  final TextEditingController minKmController;
  final TextEditingController maxKmController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final Function(TextEditingController, String, Function(double)) updateTextFieldValue;
  final Function() applyFilters;
  final Function(double) onMinKmChanged;
  final Function(double) onMaxKmChanged;
  final Function(double) onMinPriceChanged;
  final Function(double) onMaxPriceChanged;
  final Set<String> selectedCities;
  final Set<String> availableCities;
  final Function(Set<String>) onCitiesChanged;

  // Türkiye'nin illeri
  static const List<String> turkiyeIlleri = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
    'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
    'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
    'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
    'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkâri',
    'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş',
    'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis',
    'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya',
    'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya',
    'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop', 'Sivas', 'Şırnak',
    'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van',
    'Yalova', 'Yozgat', 'Zonguldak'
  ];

  const FilterDrawer({
    Key? key,
    required this.minKmController,
    required this.maxKmController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.updateTextFieldValue,
    required this.applyFilters,
    required this.onMinKmChanged,
    required this.onMaxKmChanged,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    required this.selectedCities,
    required this.availableCities,
    required this.onCitiesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: const Center(
              child: Text(
                'Filtreleme Seçenekleri',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Kilometre Aralığı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minKmController,
                  decoration: const InputDecoration(
                    labelText: 'Min KM',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    updateTextFieldValue(
                      minKmController,
                      value,
                      onMinKmChanged,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxKmController,
                  decoration: const InputDecoration(
                    labelText: 'Max KM',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    updateTextFieldValue(
                      maxKmController,
                      value,
                      onMaxKmChanged,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fiyat Aralığı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Min Fiyat',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    updateTextFieldValue(
                      minPriceController,
                      value,
                      onMinPriceChanged,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Max Fiyat',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    updateTextFieldValue(
                      maxPriceController,
                      value,
                      onMaxPriceChanged,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'İller',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Set<String> tempSelection = Set.from(selectedCities);
                    String searchQuery = ''; // Arama metni için değişken

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            // Arama sorgusuna göre illeri filtrele
                            List<String> filteredCities = turkiyeIlleri.where((city) {
                              return city
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                            }).toList();

                            return AlertDialog(
                              title: Column(
                                children: [
                                  const Text('İl Seçimi'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'İl Ara...',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        searchQuery = value; // Arama metnini güncelle
                                      });
                                    },
                                  ),
                                ],
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 300,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredCities.length, // Filtrelenmiş listeyi kullan
                                  itemBuilder: (context, index) {
                                    final city = filteredCities[index]; // Filtrelenmiş listeden al
                                    final isSelected = tempSelection.contains(city);
                                    return CheckboxListTile(
                                      title: Text(city),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            tempSelection.add(city);
                                          } else {
                                            tempSelection.remove(city);
                                          }
                                        });
                                        onCitiesChanged(tempSelection);
                                        applyFilters();
                                      },
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    tempSelection.clear();
                                    onCitiesChanged(tempSelection);
                                    applyFilters();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Temizle'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Tamam'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCities.isEmpty 
                              ? 'İl Seçin' 
                              : selectedCities.length == 1 
                                  ? selectedCities.first 
                                  : '${selectedCities.length} il seçildi',
                          style: TextStyle(
                            color: selectedCities.isEmpty 
                                ? Colors.grey 
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                if (selectedCities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: selectedCities.map((city) {
                        return Chip(
                          label: Text(city),
                          onDeleted: () {
                            Set<String> newSelection = Set.from(selectedCities);
                            newSelection.remove(city);
                            onCitiesChanged(newSelection);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Filtreleri sıfırla
                    minKmController.clear();
                    maxKmController.clear();
                    minPriceController.clear();
                    maxPriceController.clear();
                    
                    onMinKmChanged(0);
                    onMaxKmChanged(500000);
                    onMinPriceChanged(0);
                    onMaxPriceChanged(1000000);
                    onCitiesChanged({}); // İl filtrelerini temizle
                    
                    applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Filtreleri Sıfırla'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}