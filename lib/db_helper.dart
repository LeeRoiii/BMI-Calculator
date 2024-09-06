import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'bmi.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bmi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            height REAL,
            weight REAL,
            bmi REAL,
            date TEXT
          )
        ''');
      },
    );
  }


  Future<void> insertBMI(double height, double weight, double bmi) async {
    final db = await database;
    await db.insert(
      'bmi',
      {'height': height, 'weight': weight, 'bmi': bmi},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBMIRecords() async {
    final db = await database;
    return await db.query('bmi');
  }
}
