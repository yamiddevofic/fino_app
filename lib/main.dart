import 'package:fino_app/app_colors.dart';
import 'package:fino_app/app_theme.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/settings_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/screen/buys_screen.dart';
import 'package:fino_app/screen/debt_screen.dart';
import 'package:fino_app/screen/expenses_screen.dart';
import 'package:fino_app/screen/home_screen.dart';
import 'package:fino_app/screen/incomes_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);

  await Hive.initFlutter();
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BuyAdapter());
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox<Income>('incomesBox');
  await Hive.openBox<Expense>('expensesBox');
  await Hive.openBox<Buy>('buysBox');
  await Hive.openBox<Debt>('debtBox');
  final settingsBox = await Hive.openBox<Settings>('settingsBox');
  final savedSettings =
      settingsBox.get('settings', defaultValue: Settings()) ?? Settings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BuyProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..load(),
        ),
      ],
      child: FinoApp(initialDarkMode: savedSettings.isDarkMode),
    ),
  );
}

class FinoApp extends StatelessWidget {
  final bool initialDarkMode;
  const FinoApp({super.key, this.initialDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final isDark = settingsProvider.isDarkMode;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final colors =
            AppColors.accents(isDark ? Brightness.dark : Brightness.light);

        return MaterialApp(
          title: 'Fino App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: _AppShell(colors: colors, isDark: isDark),
        );
      },
    );
  }
}

class _AppShell extends StatefulWidget {
  final List<Color> colors;
  final bool isDark;
  const _AppShell({required this.colors, required this.isDark});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const _sectionNames = [
    'Resumen',
    'Ingresos',
    'Gastos',
    'Deudas',
    'Compras',
  ];

  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSection(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleTheme() {
    context.read<SettingsProvider>().toggleTheme(isDark: !widget.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.isDark
        ? AppTheme.dark.colorScheme.onSurfaceVariant
        : AppTheme.light.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fino App'),
            const SizedBox(height: 2),
            Text(
              _sectionNames[_selectedIndex],
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Usar tema claro' : 'Usar tema oscuro',
            onPressed: _toggleTheme,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          HomeScreen(),
          IncomesScreen(),
          ExpensesScreen(),
          DebtsScreen(),
          BuysScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: widget.colors[_selectedIndex].withValues(alpha: .14),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? widget.colors[_selectedIndex] : muted,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? widget.colors[_selectedIndex] : muted,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectSection,
          destinations: const [
            NavigationDestination(
              key: ValueKey('home'),
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              key: ValueKey('incomes'),
              icon: Icon(Icons.south_west_rounded),
              selectedIcon: Icon(Icons.south_west_rounded),
              label: 'Ingresos',
            ),
            NavigationDestination(
              key: ValueKey('expenses'),
              icon: Icon(Icons.north_east_rounded),
              selectedIcon: Icon(Icons.north_east_rounded),
              label: 'Gastos',
            ),
            NavigationDestination(
              key: ValueKey('debts'),
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Deudas',
            ),
            NavigationDestination(
              key: ValueKey('buys'),
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Compras',
            ),
          ],
        ),
      ),
    );
  }
}
