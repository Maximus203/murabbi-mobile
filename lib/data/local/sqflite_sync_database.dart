import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';
import 'package:murabbi_mobile/data/local/sync_database.dart';
import 'package:sqflite/sqflite.dart';

/// Implémentation sqflite de [SyncDatabase] (M2 — issue #200).
///
/// La base de données réside dans le répertoire de données de l'app
/// (chemin fourni par `getDatabasesPath()` + [_dbName]).
/// L'instance in-memory (via le chemin spécial sqflite) est utilisée
/// en test (cf. [SqfliteSyncDatabase.inMemory]).
///
/// **Table `pending_sync_items`** :
/// | Colonne       | Type    | Contrainte            |
/// |---------------|---------|-----------------------|
/// | id            | TEXT    | PRIMARY KEY           |
/// | type          | TEXT    | NOT NULL              |
/// | payload       | TEXT    | NOT NULL (JSON)       |
/// | created_at    | TEXT    | NOT NULL (ISO-8601)   |
/// | retry_count   | INTEGER | NOT NULL DEFAULT 0    |
/// | status        | TEXT    | NOT NULL DEFAULT 'pending' |
///
/// Le schéma est versionné (`_schemaVersion = 1`). Les migrations futures
/// incrémentent ce numéro et ajoutent une branche dans `onUpgrade`.
class SqfliteSyncDatabase implements SyncDatabase {
  static const String _dbName = 'murabbi_sync.db';
  static const String _tableName = 'pending_sync_items';
  static const int _schemaVersion = 1;

  /// Chemin utilisé pour ouvrir la DB. Si `null`, utilise [_dbName] dans
  /// `getDatabasesPath()`. Si `:memory:`, ouvre une DB en mémoire (test).
  final String? dbPath;

  Database? _db;

  SqfliteSyncDatabase({this.dbPath});

  /// Constructeur factory pour les tests in-memory.
  factory SqfliteSyncDatabase.inMemory() {
    return SqfliteSyncDatabase(dbPath: inMemoryDatabasePath);
  }

  @override
  Future<void> init() async {
    final path = dbPath ?? '${await getDatabasesPath()}/$_dbName';
    _db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    appLog.d('SqfliteSyncDatabase: opened at $path');
  }

  @override
  Future<void> insert(PendingSyncItem item) async {
    await _database.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    appLog.d('SqfliteSyncDatabase: inserted ${item.id}');
  }

  @override
  Future<List<PendingSyncItem>> getPendingItems() async {
    final rows = await _database.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [SyncItemStatus.pending.name],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingSyncItem.fromMap).toList();
  }

  /// Retourne tous les items (pending + failed) — utile pour les tests
  /// et la vue de diagnostic.
  Future<List<PendingSyncItem>> getAllItems() async {
    final rows = await _database.query(_tableName, orderBy: 'created_at ASC');
    return rows.map(PendingSyncItem.fromMap).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    appLog.d('SqfliteSyncDatabase: deleted $id');
  }

  @override
  Future<void> update(PendingSyncItem item) async {
    await _database.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    appLog.d(
      'SqfliteSyncDatabase: updated ${item.id} '
      '(retryCount=${item.retryCount}, status=${item.status.name})',
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ── Privé ──────────────────────────────────────────────────────────────────

  Database get _database {
    assert(_db != null, 'SqfliteSyncDatabase.init() doit être appelé avant usage.');
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id          TEXT    PRIMARY KEY,
        type        TEXT    NOT NULL,
        payload     TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        status      TEXT    NOT NULL DEFAULT 'pending'
      )
    ''');
    appLog.d('SqfliteSyncDatabase: table $_tableName créée (schema v$version)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Placeholder pour les migrations futures.
    appLog.i('SqfliteSyncDatabase: migration $oldVersion → $newVersion');
  }
}
