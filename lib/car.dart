class Car {
  final String title;
  final String price;
  final String year;
  final String km;
  final String color;
  final String city;
  final String listingDate;
  final String description;
  final String detailUrl;

  Car({
    required this.title,
    required this.price,
    required this.year,
    required this.km,
    this.color = '',
    this.city = '',
    required this.listingDate,
    this.description = '',
    required this.detailUrl,
  });

  // Map'ten Car nesnesi oluşturan factory constructor
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      title: map['title'] ?? '',
      price: map['price'] ?? '',
      year: map['year'] ?? '',
      km: map['km'] ?? '',
      color: map['color'] ?? '',
      city: map['city'] ?? '',
      listingDate: map['listingDate'] ?? '',
      description: map['description'] ?? '',
      detailUrl: map['detailUrl'] ?? '',
    );
  }

  // Car nesnesini Map'e çeviren metod
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'year': year,
      'km': km,
      'color': color,
      'city': city,
      'listingDate': listingDate,
      'description': description,
      'detailUrl': detailUrl,
    };
  }
} 