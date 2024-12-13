import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'car.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cars.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        price TEXT NOT NULL,
        year TEXT NOT NULL,
        km TEXT NOT NULL,
        color TEXT,
        city TEXT,
        listingDate TEXT NOT NULL,
        description TEXT,
        detailUrl TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertCar(Car car) async {
    final db = await instance.database;
    await db.insert(
      'cars',
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Car>> getCars() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('cars');
    return List.generate(maps.length, (i) => Car.fromMap(maps[i]));
  }

  Future<void> syncCars(List<Car> cars) async {
    final db = await instance.database;
    await db.delete('cars');
    for (var car in cars) {
      await insertCar(car);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}