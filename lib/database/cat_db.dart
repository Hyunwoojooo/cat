import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cat_project/models/cat.dart';

class CatDatabase {
  static final CatDatabase instance = CatDatabase._init();
  static Database? _database;

  // 데이터베이스 버전 관리
  static const int _databaseVersion = 7;

  CatDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cats.db');
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
      CREATE TABLE cats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        catId TEXT,
        keyDiscoveryTime TEXT,
        location TEXT,
        detailLocation TEXT,
        furColor TEXT,
        age TEXT,
        isNeutered INTEGER,
        specialNotes TEXT,
        image TEXT,
        pattern TEXT,
        eyeColor TEXT,
        isDuplicate INTEGER,
        uniqueId TEXT
      )
    ''');
  }

  // 데이터베이스 업그레이드 처리
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // 버전 6으로 업그레이드 - 테이블을 완전히 재생성
      print('데이터베이스 버전 6으로 업그레이드 중...');

      // 기존 테이블 삭제
      await db.execute('DROP TABLE IF EXISTS cats');
      await db.execute('DROP TABLE IF EXISTS cats_old');

      // 새 테이블 생성
      await _createDB(db, newVersion);
      print('데이터베이스 테이블 재생성 완료');
    }

    if (oldVersion < 7) {
      // 버전 7로 업그레이드 - uniqueId 컬럼 추가
      print('데이터베이스 버전 7로 업그레이드 중...');

      try {
        // uniqueId 컬럼 추가
        await db.execute('ALTER TABLE cats ADD COLUMN uniqueId TEXT');
        print('uniqueId 컬럼 추가 완료');

        // 기존 데이터에 uniqueId 값 설정
        final cats = await db.query('cats');
        for (int i = 0; i < cats.length; i++) {
          final cat = cats[i];
          final uniqueId = '${cat['catId']}_$i';
          await db.update(
            'cats',
            {'uniqueId': uniqueId},
            where: 'id = ?',
            whereArgs: [cat['id']],
          );
        }
        print('기존 데이터에 uniqueId 설정 완료');
      } catch (e) {
        print('uniqueId 컬럼 추가 중 오류: $e');
        // 컬럼이 이미 존재하는 경우 무시
      }
    }
  }

  Future<int> insertCat(Cat cat) async {
    try {
      final db = await instance.database;
      final map = cat.toMap();
      map['isNeutered'] = cat.isNeutered ? 1 : 0;
      map['isDuplicate'] = cat.isDuplicate;

      print('=== 데이터베이스 저장 시작 ===');
      print('저장할 Cat 객체: ${cat.catId}, ${cat.location}, ${cat.furColor}');
      print('변환된 Map: $map');

      final result = await db.insert('cats', map);
      print('데이터베이스 저장 성공, ID: $result');

      // 저장 후 즉시 확인
      final savedCats = await db.query('cats');
      print('저장 후 전체 고양이 수: ${savedCats.length}');
      print('=== 데이터베이스 저장 완료 ===');

      return result;
    } catch (e, stackTrace) {
      print('=== 데이터베이스 저장 오류 ===');
      print('오류: $e');
      print('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  // 데이터베이스 테이블 구조 확인
  Future<void> _checkTableStructure() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery("PRAGMA table_info(cats)");
      print('=== 테이블 구조 확인 ===');
      for (var column in result) {
        print('컬럼: ${column['name']} - 타입: ${column['type']}');
      }
    } catch (e) {
      print('테이블 구조 확인 오류: $e');
    }
  }

  Future<List<Cat>> getAllCats() async {
    try {
      final db = await instance.database;
      print('=== 데이터베이스 조회 시작 ===');

      // 테이블 구조 확인
      await _checkTableStructure();

      final result = await db.query('cats');
      print('데이터베이스에서 조회된 행 수: ${result.length}');

      if (result.isEmpty) {
        print('데이터베이스에 고양이 데이터가 없습니다.');
        return [];
      }

      final cats = result.map((json) {
        print('원본 데이터: $json');
        // 새로운 Map을 생성하여 데이터 변환
        final Map<String, dynamic> convertedJson = Map<String, dynamic>.from(
          json,
        );
        convertedJson['isNeutered'] = json['isNeutered'] == 1;
        convertedJson['isDuplicate'] = json['isDuplicate']; // int로 유지
        print('변환된 데이터: $convertedJson');
        final cat = Cat.fromMap(convertedJson);
        print('생성된 Cat 객체: ${cat.catId}, ${cat.location}');
        return cat;
      }).toList();

      print('=== 데이터베이스 조회 완료 ===');
      print('최종 반환할 고양이 수: ${cats.length}');
      for (var cat in cats) {
        print('반환할 고양이: ${cat.catId} - ${cat.location}');
      }
      return cats;
    } catch (e, stackTrace) {
      print('=== getAllCats 오류 ===');
      print('오류: $e');
      print('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateCat(Cat cat) async {
    final db = await instance.database;
    final map = cat.toMap();
    map['isNeutered'] = cat.isNeutered ? 1 : 0;
    map['isDuplicate'] = cat.isDuplicate;
    return await db.update(
      'cats',
      map,
      where: 'catId = ?',
      whereArgs: [cat.catId],
    );
  }

  Future<int> deleteCat(String catId) async {
    final db = await instance.database;
    return await db.delete(
      'cats',
      where: 'catId = ?',
      whereArgs: [catId],
    );
  }
}
