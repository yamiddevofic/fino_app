import 'dart:convert';

import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/record_provider.dart';

/// Identifica un archivo de respaldo de Fino y la versión de su formato.
const backupApp = 'fino';
const backupVersion = 1;

/// Respaldo no válido. [message] se puede mostrar al usuario.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// Contenido de un respaldo ya validado, listo para restaurarse.
class Backup {
  const Backup({
    required this.incomes,
    required this.expenses,
    required this.debts,
    required this.buys,
    required this.categories,
    this.exportedAt,
  });

  final Map<int, Income> incomes;
  final Map<int, Expense> expenses;
  final Map<int, Debt> debts;
  final Map<int, Buy> buys;

  /// Categorías creadas por el usuario en cada sección.
  final Map<RecordKind, List<String>> categories;
  final DateTime? exportedAt;

  int get recordCount =>
      incomes.length + expenses.length + debts.length + buys.length;

  int get categoryCount =>
      categories.values.fold(0, (sum, list) => sum + list.length);
}

/// Los providers que guardan los datos de la app.
class BackupSources {
  const BackupSources({
    required this.incomes,
    required this.expenses,
    required this.debts,
    required this.buys,
    required this.categories,
  });

  final RecordProvider<Income> incomes;
  final RecordProvider<Expense> expenses;
  final RecordProvider<Debt> debts;
  final RecordProvider<Buy> buys;
  final CategoryProvider categories;

  int get recordCount =>
      incomes.entries.length +
      expenses.entries.length +
      debts.entries.length +
      buys.entries.length;

  /// Todos los registros y categorías propias como JSON legible.
  ///
  /// Cada registro conserva su clave para que, al restaurar, las deudas y
  /// compras pagadas sigan enlazadas con el gasto que generaron.
  String export({DateTime? now}) {
    Map<String, Object?> recordJson(int key, FinanceRecord r) => {
      'key': key,
      'name': r.name,
      'amount': r.amount,
      'date': r.date?.toIso8601String(),
      'category': r.category,
      'note': r.note,
      'done': r.done,
      'pricePending': r.pricePending,
      'expenseKey': r.expenseKey,
    };
    List<Object?> section(RecordProvider provider) => [
      for (final MapEntry(:key, :value) in provider.entries.entries)
        recordJson(key, value),
    ];

    return const JsonEncoder.withIndent('  ').convert({
      'app': backupApp,
      'version': backupVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'categories': {
        for (final kind in RecordKind.values)
          kind.name: categories.custom(kind),
      },
      'records': {
        RecordKind.income.name: section(incomes),
        RecordKind.expense.name: section(expenses),
        RecordKind.debt.name: section(debts),
        RecordKind.buy.name: section(buys),
      },
    });
  }

  /// Sustituye todos los datos actuales por los de [backup].
  Future<void> restore(Backup backup) async {
    await incomes.replaceAll(backup.incomes);
    await expenses.replaceAll(backup.expenses);
    await debts.replaceAll(backup.debts);
    await buys.replaceAll(backup.buys);
    await categories.replaceAll(backup.categories);
  }
}

/// Resultado de combinar un respaldo con los datos actuales.
class MergeResult {
  const MergeResult({
    required this.added,
    required this.skipped,
    required this.categoriesAdded,
  });

  /// Registros nuevos guardados.
  final int added;

  /// Registros omitidos porque ya existían.
  final int skipped;
  final int categoriesAdded;
}

/// Contenido de un registro, sin su clave. Dos registros con la misma huella
/// se consideran el mismo al combinar.
typedef _Fingerprint = (
  String,
  double,
  DateTime?,
  String?,
  String?,
  bool,
  bool,
);

_Fingerprint _fingerprint(FinanceRecord r) =>
    (r.name, r.amount, r.date, r.category, r.note, r.done, r.pricePending);

/// Cuántas veces aparece cada huella en [records].
Map<_Fingerprint, int> _counts(Iterable<FinanceRecord> records) {
  final counts = <_Fingerprint, int>{};
  for (final r in records) {
    counts.update(_fingerprint(r), (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// Consume una aparición de [record] en [counts]. Devuelve `true` si ya
/// existía, de modo que importar dos veces el mismo respaldo no duplica nada.
bool _consume(Map<_Fingerprint, int> counts, FinanceRecord record) {
  final key = _fingerprint(record);
  final n = counts[key] ?? 0;
  if (n == 0) return false;
  counts[key] = n - 1;
  return true;
}

extension BackupMerge on BackupSources {
  /// Agrega a los datos actuales los registros y categorías de [backup] que
  /// todavía no existen.
  ///
  /// Una deuda o compra pagada y el gasto que generó se tratan juntos: si la
  /// deuda ya existía se omite también su gasto, y si es nueva su gasto se
  /// guarda aunque coincida con otro, para que cada una tenga el suyo.
  Future<MergeResult> merge(Backup backup) async {
    var added = 0, skipped = 0;

    Future<void> mergeSimple<T extends FinanceRecord>(
      RecordProvider<T> provider,
      Map<int, T> incoming,
    ) async {
      final counts = _counts(provider.records);
      final fresh = <T>[];
      for (final r in incoming.values) {
        _consume(counts, r) ? skipped++ : fresh.add(r);
      }
      if (fresh.isNotEmpty) await provider.addAll(fresh);
      added += fresh.length;
    }

    // Deudas y compras nuevas, y qué gastos del respaldo van con cada una.
    final linkedExpenses = <int>{};
    final skippedExpenses = <int>{};
    List<T> pendingLinked<T extends FinanceRecord>(
      RecordProvider<T> provider,
      Map<int, T> incoming,
    ) {
      final counts = _counts(provider.records);
      final fresh = <T>[];
      for (final r in incoming.values) {
        final key = r.expenseKey;
        if (_consume(counts, r)) {
          skipped++;
          if (key != null) skippedExpenses.add(key);
        } else {
          fresh.add(r);
          if (key != null) linkedExpenses.add(key);
        }
      }
      return fresh;
    }

    final freshDebts = pendingLinked(debts, backup.debts);
    final freshBuys = pendingLinked(buys, backup.buys);

    await mergeSimple(incomes, backup.incomes);

    // Gastos: los enlazados a una deuda o compra nueva siempre se guardan;
    // los de una ya existente se omiten; el resto se compara por contenido.
    final counts = _counts(expenses.records);
    final oldKeys = <int>[];
    final fresh = <Expense>[];
    for (final MapEntry(:key, :value) in backup.expenses.entries) {
      final isNew = linkedExpenses.contains(key);
      if (!isNew &&
          (skippedExpenses.contains(key) || _consume(counts, value))) {
        skipped++;
        continue;
      }
      oldKeys.add(key);
      fresh.add(value);
    }
    final newKeys = fresh.isEmpty
        ? const <int>[]
        : await expenses.addAll(fresh);
    added += fresh.length;
    final keyMap = Map.fromIterables(oldKeys, newKeys);

    Future<void> addLinked<T extends FinanceRecord>(
      RecordProvider<T> provider,
      List<T> records,
    ) async {
      if (records.isEmpty) return;
      await provider.addAll([
        for (final r in records)
          copyRecord(provider.builder, r, expenseKey: keyMap[r.expenseKey]),
      ]);
      added += records.length;
    }

    await addLinked(debts, freshDebts);
    await addLinked(buys, freshBuys);

    return MergeResult(
      added: added,
      skipped: skipped,
      categoriesAdded: await categories.addAll(backup.categories),
    );
  }
}

/// Lee y valida un respaldo completo antes de tocar ningún dato. Lanza
/// [BackupException] si el contenido no es un respaldo de Fino válido.
Backup parseBackup(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException {
    throw const BackupException('El archivo no es un respaldo válido.');
  }
  if (json is! Map<String, Object?> || json['app'] != backupApp) {
    throw const BackupException('El archivo no es un respaldo de Fino.');
  }
  final version = json['version'];
  if (version is! int || version > backupVersion) {
    throw const BackupException(
      'El respaldo es de una versión más reciente de Fino. Actualiza la app.',
    );
  }

  final records = json['records'];
  if (records is! Map<String, Object?>) {
    throw const BackupException('El respaldo no contiene registros.');
  }

  final expenses = _parseSection(records, RecordKind.expense, Expense.new);
  return Backup(
    incomes: _parseSection(records, RecordKind.income, Income.new),
    expenses: expenses,
    debts: _parseSection(records, RecordKind.debt, Debt.new, expenses),
    buys: _parseSection(records, RecordKind.buy, Buy.new, expenses),
    categories: _parseCategories(json['categories']),
    exportedAt: switch (json['exportedAt']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    },
  );
}

/// Claves válidas en una caja de Hive.
const _maxKey = 0xFFFFFFFF;

Map<int, T> _parseSection<T extends FinanceRecord>(
  Map<String, Object?> records,
  RecordKind kind,
  RecordBuilder<T> builder, [
  Map<int, Expense>? expenses,
]) {
  final list = records[kind.name] ?? const [];
  if (list is! List<Object?>) {
    throw BackupException('La sección ${kind.title} no es válida.');
  }

  final result = <int, T>{};
  var nextKey = 0;
  for (final (index, item) in list.indexed) {
    BackupException invalid(String detail) => BackupException(
      'El registro ${index + 1} de ${kind.title} no es válido: $detail.',
    );
    if (item is! Map<String, Object?>) throw invalid('formato desconocido');

    final name = item['name'];
    final amount = item['amount'];
    if (name is! String) throw invalid('falta el nombre');
    if (amount is! num || !amount.isFinite) throw invalid('falta el monto');

    final key = switch (item['key']) {
      final int k when k >= 0 && k <= _maxKey => k,
      null => nextKey,
      _ => throw invalid('clave incorrecta'),
    };
    if (result.containsKey(key)) throw invalid('clave repetida');
    nextKey = (key + 1 > nextKey) ? key + 1 : nextKey;

    final date = item['date'];
    final parsedDate = date is String ? DateTime.tryParse(date) : null;
    if (date != null && parsedDate == null) throw invalid('fecha incorrecta');

    // Un enlace a un gasto que no viene en el respaldo se descarta para no
    // borrar un gasto ajeno al desmarcar la deuda o la compra.
    final expenseKey = switch (item['expenseKey']) {
      final int k when expenses?.containsKey(k) ?? false => k,
      _ => null,
    };

    result[key] = builder(
      name: name,
      amount: amount.toDouble(),
      date: parsedDate,
      category: _optionalString(item['category']),
      note: _optionalString(item['note']),
      done: kind.canMarkDone && item['done'] == true,
      pricePending: kind.allowsPendingPrice && item['pricePending'] == true,
      expenseKey: expenseKey,
    );
  }
  return result;
}

Map<RecordKind, List<String>> _parseCategories(Object? json) {
  if (json is! Map<String, Object?>) return const {};
  final result = <RecordKind, List<String>>{};
  for (final kind in RecordKind.values) {
    final list = json[kind.name];
    if (list is! List<Object?>) continue;
    final seen = {for (final c in kind.categories) c.toLowerCase()};
    final names = <String>[
      for (final item in list)
        if (item is String)
          if (item.trim() case final name
              when name.isNotEmpty &&
                  name.length <= maxCategoryLength &&
                  seen.add(name.toLowerCase()))
            name,
    ];
    if (names.isNotEmpty) result[kind] = names;
  }
  return result;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
