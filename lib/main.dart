import 'dart:ui' show ImageFilter;

import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/models/settings_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:fino_app/screen/buys_screen.dart';
import 'package:fino_app/screen/debt_screen.dart';
import 'package:fino_app/screen/expenses_screen.dart';
import 'package:fino_app/screen/home_screen.dart';
import 'package:fino_app/screen/incomes_screen.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await initializeDateFormatting('es_CO');

  await Hive.initFlutter();
  registerAdapters();
  await openBoxes();

  runApp(const AppProviders(child: FinoApp()));
}

void registerAdapters() {
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BuyAdapter());
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(SettingsAdapter());
}

Future<void> openBoxes() async {
  await Hive.openBox<Income>(RecordKind.income.boxName);
  await Hive.openBox<Expense>(RecordKind.expense.boxName);
  await Hive.openBox<Buy>(RecordKind.buy.boxName);
  await Hive.openBox<Debt>(RecordKind.debt.boxName);
  await Hive.openBox<Settings>(settingsBoxName);
  await Hive.openBox<List<dynamic>>(categoriesBoxName);
}

/// Registra un provider por tipo de registro. Las cajas de Hive deben estar
/// abiertas antes.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<RecordProvider<Income>>(
        create: (_) => IncomeProvider(),
      ),
      ChangeNotifierProvider<RecordProvider<Expense>>(
        create: (_) => ExpenseProvider(),
      ),
      ChangeNotifierProvider<RecordProvider<Buy>>(create: (_) => BuyProvider()),
      ChangeNotifierProvider<RecordProvider<Debt>>(
        create: (_) => DebtProvider(),
      ),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => CategoryProvider()),
    ],
    child: child,
  );
}

class FinoApp extends StatelessWidget {
  const FinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Fino',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(onToggleTheme: (isDark) => settings.setDarkMode(!isDark)),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.kind);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final RecordKind? kind;
}

const _destinations = [
  _Destination(
    'Inicio',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
    null,
  ),
  _Destination(
    'Ingresos',
    Icons.south_west_rounded,
    Icons.south_west_rounded,
    RecordKind.income,
  ),
  _Destination(
    'Gastos',
    Icons.north_east_rounded,
    Icons.north_east_rounded,
    RecordKind.expense,
  ),
  _Destination(
    'Deudas',
    Icons.account_balance_outlined,
    Icons.account_balance_rounded,
    RecordKind.debt,
  ),
  _Destination(
    'Compras',
    Icons.shopping_bag_outlined,
    Icons.shopping_bag_rounded,
    RecordKind.buy,
  ),
];

/// Estructura principal: barra superior, fondo animado, contenido de la
/// pestaña activa y navegación inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onToggleTheme});

  /// Recibe si el tema actual es oscuro.
  final ValueChanged<bool> onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = _destinations[_index].kind;
    final accent = kind?.accent(context) ?? tokens.brand;

    final pages = [
      HomeScreen(
        onOpenSection: (k) =>
            _select(_destinations.indexWhere((d) => d.kind == k)),
      ),
      const IncomesScreen(),
      const ExpensesScreen(),
      const DebtsScreen(),
      const BuysScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedBackground(
        accent: accent,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                title: kind?.title ?? 'Resumen',
                isDark: isDark,
                onToggleTheme: () => widget.onToggleTheme(isDark),
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_index),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: IndexedStack(index: _index, children: pages),
                ),
              ),
            ],
          ),
        ),
      ),
      // Barra translúcida con desenfoque: el contenido se intuye por debajo
      // sin competir con la navegación.
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              indicatorColor: accent.withValues(alpha: 0.16),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon, color: tokens.textMuted),
                    selectedIcon: Icon(d.selectedIcon, color: accent),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isDark,
    required this.onToggleTheme,
  });

  final String title;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/svg/logo.svg',
            width: 32,
            height: 32,
            theme: SvgTheme(currentColor: tokens.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                title,
                key: ValueKey(title),
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onPressed: onToggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(isDark),
                color: tokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
