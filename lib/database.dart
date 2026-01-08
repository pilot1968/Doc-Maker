import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:noteapp/document.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create table
        await db.execute('''
          CREATE TABLE documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Save new document
  Future<int> saveDocument(Document doc) async {
    final db = await database;
    return await db.insert('documents', doc.toMap());
  }

  // Get all documents
  Future<List<Document>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Document.fromMap(map)).toList();
  }

  // Get single document
  Future<Document?> getDocument(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Document.fromMap(maps.first);
    }
    return null;
  }

  // Update document
  Future<int> updateDocument(Document doc) async {
    final db = await database;
    return await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  // Delete document
  Future<int> deleteDocument(int id) async {
    final db = await database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search documents by title or content
  Future<List<Document>> searchDocuments(String searchText) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$searchText%', '%$searchText%'],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Document.fromMap(map)).toList();
  }
}
