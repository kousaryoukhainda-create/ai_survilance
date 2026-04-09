import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movement_event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movements.db');
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
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
    CREATE TABLE movement_events (
      id $idType,
      timestamp $textType,
      snapshotPath $textType,
      videoPath TEXT,
      confidence $realType,
      description $textType,
      detectedType TEXT,
      identityName TEXT,
      identityConfidence REAL,
      isFaceMatched INTEGER DEFAULT 0,
      objectsDetected TEXT,
      personCount INTEGER
    )
    ''');
    
    // Known persons table for face recognition
    await db.execute('''
    CREATE TABLE known_persons (
      id $idType,
      name $textType,
      faceEncoding $textType,
      photoPath $textType,
      createdAt $textType,
      lastSeen TEXT,
      detectionCount INTEGER DEFAULT 0,
      notes TEXT
    )
    ''');
  }

  Future<MovementEvent> create(MovementEvent event) async {
    final db = await instance.database;
    final id = await db.insert('movement_events', event.toMap());
    return event.copyWith(id: id);
  }

  Future<MovementEvent?> read(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'movement_events',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MovementEvent.fromMap(maps.first);
    }
    return null;
  }

  Future<List<MovementEvent>> readAll({int limit = 50}) async {
    final db = await instance.database;
    final result = await db.query(
      'movement_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((json) => MovementEvent.fromMap(json)).toList();
  }

  Future<List<MovementEvent>> readByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'movement_events',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => MovementEvent.fromMap(json)).toList();
  }

  Future<int> update(MovementEvent event) async {
    final db = await instance.database;
    return db.update(
      'movement_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'movement_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('movement_events');
  }

  // Known Persons CRUD operations
  Future<int> addPerson({
    required String name,
    required String faceEncoding,
    required String photoPath,
    String? notes,
  }) async {
    final db = await instance.database;
    return await db.insert('known_persons', {
      'name': name,
      'faceEncoding': faceEncoding,
      'photoPath': photoPath,
      'createdAt': DateTime.now().toIso8601String(),
      'notes': notes,
      'detectionCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getAllPersons() async {
    final db = await instance.database;
    return await db.query(
      'known_persons',
      orderBy: 'detectionCount DESC, name ASC',
    );
  }

  Future<Map<String, dynamic>?> getPerson(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'known_persons',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updatePersonLastSeen(int id) async {
    final db = await instance.database;
    return await db.update(
      'known_persons',
      {
        'lastSeen': DateTime.now().toIso8601String(),
        'detectionCount': await _getDetectionCount(db, id) + 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> _getDetectionCount(Database db, int id) async {
    final result = await db.rawQuery(
      'SELECT detectionCount FROM known_persons WHERE id = ?',
      [id],
    );
    return result.isNotEmpty ? result.first['detectionCount'] as int : 0;
  }

  Future<int> deletePerson(int id) async {
    final db = await instance.database;
    return await db.delete(
      'known_persons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
