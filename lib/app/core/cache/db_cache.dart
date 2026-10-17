import 'dart:convert';

import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

/// لایه کش L3 — sqflite `cache.db` (دکترین §2.4 پلن).
/// جداول: catalog_items / orders / wallet_tx — هر ردیف json + updated_at.
/// کلید نسخه‌دار برای invalidation ساختاری (مهاجرت با onUpgrade).
class DbCache extends GetxService {
  static const int _dbVersion = 1;
  static const String _fileName = 'cache.db';

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/$_fileName',
      version: _dbVersion,
      onUpgrade: _onUpgrade,
      onCreate: (d, v) => _createAll(d),
    );
  }

  Future<void> _createAll(Database d) async {
    await d.execute('''
      CREATE TABLE catalog_items (
        kind TEXT NOT NULL, id TEXT NOT NULL, json TEXT NOT NULL,
        updated_at INTEGER NOT NULL, PRIMARY KEY (kind, id))
    ''');
    await d.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)
    ''');
    await d.execute('''
      CREATE TABLE wallet_tx (
        id TEXT PRIMARY KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)
    ''');
    await d.execute('''
      CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)
    ''');
  }

  Future<void> _onUpgrade(Database d, int oldV, int newV) async {
    // نسخه‌های بعدی: rebuild ساده جداول — کش است و بازسازی از شبکه بی‌هزینه است.
    if (oldV < 2) {
      await _createAll(d);
    }
  }

  String _stamp() => DateTime.now().millisecondsSinceEpoch.toString();

  // ── Catalog (kind = 'category' | 'service') ──
  Future<void> upsertCatalog(String kind, List<dynamic> items) async {
    final d = await db;
    final batch = d.batch();
    final now = _stamp();
    for (final it in items) {
      batch.insert(
        'catalog_items',
        {'kind': kind, 'id': '${it['id']}', 'json': jsonEncode(it), 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<dynamic>> catalog(String kind) async {
    final d = await db;
    final rows = await d.query('catalog_items',
        where: 'kind = ?', whereArgs: [kind], orderBy: 'updated_at DESC');
    return rows
        .map((r) => jsonDecode(r['json'] as String) as dynamic)
        .toList();
  }

  Future<void> clearCatalog() async {
    final d = await db;
    await d.delete('catalog_items');
  }

  // ── Orders ──
  Future<void> upsertOrders(List<dynamic> orders) async {
    final d = await db;
    final batch = d.batch();
    final now = _stamp();
    for (final o in orders) {
      batch.insert(
        'orders',
        {'id': '${o['id']}', 'json': jsonEncode(o), 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertOrder(dynamic order) => upsertOrders([order]);

  Future<List<dynamic>> orders() async {
    final d = await db;
    final rows = await d.query('orders', orderBy: 'updated_at DESC');
    return rows.map((r) => jsonDecode(r['json'] as String) as dynamic).toList();
  }

  Future<dynamic> orderById(String id) async {
    final d = await db;
    final rows = await d.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['json'] as String) as dynamic;
  }

  Future<void> deleteOrder(String id) async {
    final d = await db;
    await d.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // ── Wallet transactions ──
  Future<void> upsertWalletTxs(List<dynamic> txs) async {
    final d = await db;
    final batch = d.batch();
    final now = _stamp();
    for (final t in txs) {
      batch.insert(
        'wallet_tx',
        {'id': '${t['id']}', 'json': jsonEncode(t), 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<dynamic>> walletTxs() async {
    final d = await db;
    final rows = await d.query('wallet_tx', orderBy: 'updated_at DESC');
    return rows.map((r) => jsonDecode(r['json'] as String) as dynamic).toList();
  }

  Future<void> clearWalletTxs() async {
    final d = await db;
    await d.delete('wallet_tx');
  }

  // ── Meta (کلید نسخه) ──
  Future<String?> meta(String key) async {
    final d = await db;
    final rows = await d.query('meta', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final d = await db;
    await d.insert('meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  void onClose() {
    _db?.close();
    super.onClose();
  }
}
