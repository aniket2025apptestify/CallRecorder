import 'package:sqflite/sqflite.dart';
import '../models/recording.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/call_recordings.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL,
            file_name TEXT NOT NULL,
            phone_number TEXT NOT NULL,
            call_type TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            audio_source TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertRecording(Recording recording) async {
    final db = await database;
    return await db.insert('recordings', recording.toMap());
  }

  Future<List<Recording>> getRecordings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Recording.fromMap(maps[i]));
  }

  Future<int> deleteRecording(int id) async {
    final db = await database;
    return await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recording>> searchRecordings(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      where: 'phone_number LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Recording.fromMap(maps[i]));
  }

  Future<Recording?> getRecordingByPath(String filePath) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recordings',
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Recording.fromMap(maps.first);
    }
    return null;
  }
}
