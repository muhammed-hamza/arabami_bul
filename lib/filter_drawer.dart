import 'package:flutter/material.dart';
import 'car.dart';

class FilterDrawer extends StatefulWidget {
  final List<Car> cars;
  final Function(List<Car>) onFiltersChanged;
  final Set<String> selectedCities;
  final TextEditingController minKmController;
  final TextEditingController maxKmController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;

  const FilterDrawer({
    Key? key,
    required this.cars,
    required this.onFiltersChanged,
    required this.selectedCities,
    required this.minKmController,
    required this.maxKmController,
    required this.minPriceController,
    required this.maxPriceController,
  }) : super(key: key);

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  void applyFilters() {
    final filteredCars = widget.cars.where((car) {
      // KM filtreleme
      if (widget.minKmController.text.isNotEmpty ||
          widget.maxKmController.text.isNotEmpty) {
        // Arabanın km değerini temizle ve sayıya çevir
        final carKm = double.tryParse(car.km
                .replaceAll('km', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim()) ??
            0;

        // Minimum km kontrolü
        if (widget.minKmController.text.isNotEmpty) {
          final minKm = double.tryParse(
                  widget.minKmController.text.replaceAll('.', '')) ??
              0;
          if (carKm < minKm) return false;
        }

        // Maximum km kontrolü
        if (widget.maxKmController.text.isNotEmpty) {
          final maxKm = double.tryParse(
                  widget.maxKmController.text.replaceAll('.', '')) ??
              0;
          if (carKm > maxKm) return false;
        }
      }

      // Şehir filtreleme
      if (widget.selectedCities.isNotEmpty &&
          !widget.selectedCities.contains(car.city)) {
        return false;
      }

      // Fiyat filtreleme
      if (widget.minPriceController.text.isNotEmpty ||
          widget.maxPriceController.text.isNotEmpty) {
        final carPrice = double.tryParse(car.price
                .replaceAll('TL', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim()) ??
            0;

        if (widget.minPriceController.text.isNotEmpty) {
          final minPrice = double.tryParse(
                  widget.minPriceController.text.replaceAll('.', '')) ??
              0;
          if (carPrice < minPrice) return false;
        }

        if (widget.maxPriceController.text.isNotEmpty) {
          final maxPrice = double.tryParse(
                  widget.maxPriceController.text.replaceAll('.', '')) ??
              0;
          if (carPrice > maxPrice) return false;
        }
      }

      return true;
    }).toList();

    widget.onFiltersChanged(filteredCars);
  }

  void _formatInput(TextEditingController controller) {
    String text = controller.text.replaceAll('.', '');
    if (text.isEmpty) {
      return;
    }

    // Format the number with thousand separators
    String newText = '';
    while (text.length > 3) {
      newText = '.${text.substring(text.length - 3)}$newText';
      text = text.substring(0, text.length - 3);
    }
    newText = text + newText;

    // Update the controller and cursor position
    if (newText != controller.text) {
      final selection = controller.selection;
      final newPosition =
          selection.baseOffset + (newText.length - controller.text.length);
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Filtreler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          // Kilometre Filtresi
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Kilometre Aralığı'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.minKmController,
                    decoration: const InputDecoration(
                      labelText: 'Min KM',
                      hintText: 'Örn: 50000',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _formatInput(widget.minKmController);
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: widget.maxKmController,
                    decoration: const InputDecoration(
                      labelText: 'Max KM',
                      hintText: 'Örn: 150000',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _formatInput(widget.maxKmController);
                      applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Fiyat Filtresi
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Fiyat Aralığı'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.minPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Min Fiyat',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _formatInput(widget.minPriceController);
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: widget.maxPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Max Fiyat',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _formatInput(widget.maxPriceController);
                      applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Şehir Filtresi
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Şehirler'),
          ),
          ...widget.cars
              .map((car) => car.city)
              .toSet()
              .map((city) => CheckboxListTile(
                    title: Text(city),
                    value: widget.selectedCities.contains(city),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          widget.selectedCities.add(city);
                        } else {
                          widget.selectedCities.remove(city);
                        }
                      });
                      applyFilters();
                    },
                  )),
        ],
      ),
    );
  }
}
