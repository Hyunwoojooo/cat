import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cat_project/models/food.dart';

class FoodDatabase {
  static final FoodDatabase instance = FoodDatabase._init();
  static Database? _database;

  // 데이터베이스 버전 관리
  static const int _databaseVersion = 3; // 버전 3으로 올림

  FoodDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('foods.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feedingSpotLocation TEXT,
        feedingMethod TEXT,
        cleanlinessRating TEXT,
        shelterCondition TEXT,
        specialNotes TEXT,
        image TEXT,
        discoveryTime TEXT,
        detailLocation TEXT,
        uniqueId TEXT,
        bowlCountFood TEXT,
        bowlCountWater TEXT,
        bowlSize TEXT,
        bowlCleanliness TEXT,
        foodRemain TEXT,
        waterRemain TEXT,
        foodType TEXT
      )
    ''');
  }

  // 데이터베이스 업그레이드 처리
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE foods ADD COLUMN detailLocation TEXT');
    }
    if (oldVersion < 3) {
      // 새로운 필드들 추가
      await db.execute('ALTER TABLE foods ADD COLUMN uniqueId TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN bowlCountFood TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN bowlCountWater TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN bowlSize TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN bowlCleanliness TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN foodRemain TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN waterRemain TEXT');
      await db.execute('ALTER TABLE foods ADD COLUMN foodType TEXT');
    }
  }

  Future<int> insertFood(Food food) async {
    final db = await instance.database;
    final map = food.toMap();
    // id 필드는 null이어야 함 (AUTOINCREMENT)
    map.remove('id');
    return await db.insert('foods', map);
  }

  Future<List<Food>> getAllFoods() async {
    final db = await instance.database;
    final result = await db.query('foods');
    return result.map((json) => Food.fromMap(json)).toList();
  }

  Future<int> updateFood(Food food) async {
    final db = await instance.database;
    final map = food.toMap();
    return await db.update(
      'foods',
      map,
      where: 'feedingSpotLocation = ?',
      whereArgs: [food.feedingSpotLocation],
    );
  }

  Future<int> deleteFood(String feedingSpotLocation) async {
    final db = await instance.database;
    return await db.delete(
      'foods',
      where: 'feedingSpotLocation = ?',
      whereArgs: [feedingSpotLocation],
    );
  }
}
