import 'dart:async';

import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:fino_app/provider/sync_outbox.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const syncStateBoxName = 'syncState';

enum SyncStatus { idle, syncing, synced, offline, error }

/// Sincroniza los datos del dispositivo con Supabase, la fuente de verdad
/// compartida entre el celular y el navegador.
///
/// La app sigue guardando primero en Hive, así que funciona sin internet.
/// Cada cambio local queda en [SyncOutbox]; al sincronizar se suben esos
/// cambios y luego se bajan los que hizo otro dispositivo desde la última
/// vez. Si el mismo registro cambió en los dos lados, gana el último que se
/// sube.
class SyncService with ChangeNotifier {
  SyncService({
    required this.client,
    required this.incomes,
    required this.expenses,
    required this.debts,
    required this.buys,
    required this.categories,
  }) : _outbox = SyncOutbox(),
       _state = Hive.box<String>(syncStateBoxName);

  final SupabaseClient client;
  final RecordProvider<Income> incomes;
  final RecordProvider<Expense> expenses;
  final RecordProvider<Debt> debts;
  final RecordProvider<Buy> buys;
  final CategoryProvider categories;

  final SyncOutbox _outbox;
  final Box<String> _state;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  String? _error;

  /// Último error, para mostrarlo al usuario.
  String? get error => _error;

  DateTime? get lastSync => switch (_state.get('lastSync')) {
    final String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };

  /// Cambios locales que aún no se han subido.
  int get pendingCount => _outbox.length;

  User? get user => client.auth.currentUser;

  bool _running = false;
  bool _again = false;
  Timer? _debounce;
  Timer? _periodic;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Sincroniza al iniciar sesión, poco después de cada cambio local y cada
  /// pocos minutos mientras la app está abierta.
  void start() {
    _subscriptions
      ..add(
        _outbox.watch().listen((event) {
          notifyListeners();
          // Solo un cambio nuevo pide sincronizar; los borrados son la
          // bandeja vaciándose tras subir.
          if (event.deleted) return;
          _debounce?.cancel();
          _debounce = Timer(const Duration(seconds: 2), sync);
        }),
      )
      ..add(
        client.auth.onAuthStateChange.listen((state) {
          if (state.event == AuthChangeEvent.signedIn) unawaited(sync());
          notifyListeners();
        }),
      );
    _periodic = Timer.periodic(const Duration(minutes: 3), (_) => sync());
    unawaited(sync());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _periodic?.cancel();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  Map<RecordKind, RecordProvider> get _providers => {
    RecordKind.income: incomes,
    RecordKind.expense: expenses,
    RecordKind.debt: debts,
    RecordKind.buy: buys,
  };

  /// Sube y baja los cambios. Si ya hay una sincronización en curso, se
  /// repite al terminar.
  Future<void> sync() async {
    final user = this.user;
    if (user == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _status = SyncStatus.syncing;
    notifyListeners();
    try {
      if (_state.get('user') != user.id) await _startAccount(user.id);
      await _pushRecords(user.id);
      await _pushCategories(user.id);
      await _pullRecords();
      await _pullCategories();
      await _state.put('lastSync', DateTime.now().toUtc().toIso8601String());
      _status = SyncStatus.synced;
      _error = null;
    } on AuthRetryableFetchException {
      _status = SyncStatus.offline;
      _error = null;
    } on AuthException catch (e) {
      _status = SyncStatus.error;
      _error = e.message;
    } on PostgrestException catch (e) {
      _status = SyncStatus.error;
      _error = e.message;
    } on Exception {
      // Sin red o servidor caído: los cambios siguen en la bandeja.
      _status = SyncStatus.offline;
      _error = null;
    } finally {
      _running = false;
      notifyListeners();
    }
    if (_again) {
      _again = false;
      await sync();
    }
  }

  /// Primera sincronización de una cuenta en este dispositivo: sube todo lo
  /// local y baja todo lo de la cuenta.
  Future<void> _startAccount(String userId) async {
    for (final provider in _providers.values) {
      await provider.ensureIds();
      await _outbox.recordsChanged([
        for (final r in provider.entries.values) ?r.id,
      ], PendingChange.upsert);
    }
    await categories.markAllPending();
    await _state.deleteAll(['recordsCursor', 'categoriesCursor']);
    await _state.put('user', userId);
  }

  Future<void> _pushRecords(String userId) async {
    final pending = _outbox.records;
    if (pending.isEmpty) return;

    final local = <String, (RecordKind, FinanceRecord)>{
      for (final MapEntry(key: kind, value: provider) in _providers.entries)
        for (final r in provider.entries.values) ?r.id: (kind, r),
    };
    final expenseIds = {
      for (final MapEntry(:key, :value) in expenses.entries.entries)
        key: value.id,
    };

    final rows = <Map<String, Object?>>[];
    final deleted = <String>[];
    for (final MapEntry(key: id, value: change) in pending.entries) {
      final entry = local[id];
      if (change == PendingChange.delete || entry == null) {
        deleted.add(id);
        continue;
      }
      final (kind, r) = entry;
      rows.add({
        'id': id,
        'user_id': userId,
        'kind': kind.name,
        'name': r.name,
        'amount': r.amount,
        'date': _formatDate(r.date),
        'category': r.category,
        'note': r.note,
        'done': r.done,
        'price_pending': r.pricePending,
        'expense_id': expenseIds[r.expenseKey],
        'deleted_at': null,
      });
    }

    for (var i = 0; i < rows.length; i += 500) {
      await client
          .from('records')
          .upsert(rows.sublist(i, (i + 500).clamp(0, rows.length)));
    }
    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < deleted.length; i += 200) {
      await client
          .from('records')
          .update({'deleted_at': now})
          .inFilter(
            'id',
            deleted.sublist(i, (i + 200).clamp(0, deleted.length)),
          );
    }
    await _outbox.clearRecords(pending);
  }

  Future<void> _pushCategories(String userId) async {
    final pending = _outbox.categories;
    if (pending.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = [
      for (final (kind, name, change) in pending)
        if (categories.custom(kind).indexOf(name) case final position)
          {
            'user_id': userId,
            'kind': kind.name,
            'name': name,
            'position': position < 0 ? 0 : position,
            'deleted_at': change == PendingChange.delete || position < 0
                ? now
                : null,
          },
    ];
    await client
        .from('categories')
        .upsert(rows, onConflict: 'user_id,kind,name');
    await _outbox.clearCategories(pending);
  }

  /// Baja en páginas todo lo que cambió desde [cursorKey] y devuelve las
  /// filas en orden de modificación.
  Future<List<Map<String, dynamic>>> _changesSince(
    String table,
    String cursorKey,
  ) async {
    final cursor = _state.get(cursorKey);
    const page = 1000;
    final rows = <Map<String, dynamic>>[];
    while (true) {
      var query = client.from(table).select();
      if (cursor != null) query = query.gt('updated_at', cursor);
      final batch = await query
          .order('updated_at')
          .range(rows.length, rows.length + page - 1);
      rows.addAll(batch);
      if (batch.length < page) break;
    }
    return rows;
  }

  /// Avanza el cursor solo después de aplicar los cambios, para no perderlos
  /// si algo falla a mitad de camino.
  Future<void> _saveCursor(String key, List<Map<String, dynamic>> rows) =>
      _state.put(key, rows.last['updated_at'] as String);

  Future<void> _pullRecords() async {
    final rows = await _changesSince('records', 'recordsCursor');
    if (rows.isEmpty) return;

    final byKind = <RecordKind, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      // Un cambio local más nuevo todavía sin subir gana sobre el remoto.
      if (_outbox.hasRecord(row['id'] as String)) continue;
      final kind = RecordKind.values.asNameMap()[row['kind']];
      if (kind != null) byKind.putIfAbsent(kind, () => []).add(row);
    }

    Future<void> apply<T extends FinanceRecord>(
      RecordKind kind,
      RecordProvider<T> provider,
    ) async {
      final expenseKeys = {
        for (final MapEntry(:key, :value) in expenses.entries.entries)
          ?value.id: key,
      };
      await provider.applyRemote({
        for (final row in byKind[kind] ?? const <Map<String, dynamic>>[])
          row['id'] as String: row['deleted_at'] != null
              ? null
              : provider.builder(
                  id: row['id'] as String,
                  name: row['name'] as String,
                  amount: (row['amount'] as num).toDouble(),
                  date: switch (row['date']) {
                    final String s => DateTime.tryParse(s),
                    _ => null,
                  },
                  category: row['category'] as String?,
                  note: row['note'] as String?,
                  done: row['done'] as bool? ?? false,
                  pricePending: row['price_pending'] as bool? ?? false,
                  expenseKey: expenseKeys[row['expense_id']],
                ),
      });
    }

    // Los gastos primero, para enlazar después las deudas y compras pagadas.
    await apply(RecordKind.expense, expenses);
    await apply(RecordKind.income, incomes);
    await apply(RecordKind.debt, debts);
    await apply(RecordKind.buy, buys);
    await _saveCursor('recordsCursor', rows);
  }

  Future<void> _pullCategories() async {
    final rows = await _changesSince('categories', 'categoriesCursor');
    if (rows.isEmpty) return;
    final pending = {
      for (final (kind, name, _) in _outbox.categories) (kind, name),
    };
    final remote = <RecordKind, Map<String, bool>>{};
    for (final row in rows) {
      final kind = RecordKind.values.asNameMap()[row['kind']];
      final name = row['name'] as String;
      if (kind == null || pending.contains((kind, name))) continue;
      remote.putIfAbsent(kind, () => {})[name] = row['deleted_at'] != null;
    }
    await categories.applyRemote(remote);
    await _saveCursor('categoriesCursor', rows);
  }

  /// Cierra la sesión. Los datos se quedan en el dispositivo.
  Future<void> signOut() async {
    await client.auth.signOut();
    notifyListeners();
  }
}

String? _formatDate(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
