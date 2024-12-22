import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/screen/buys_screen.dart';
import 'package:fino_app/screen/debt_screen.dart';
import 'package:fino_app/screen/expenses_screen.dart';
import 'package:fino_app/screen/home_screen.dart';
import 'package:fino_app/screen/incomes_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:provider/provider.dart';

// Otras importaciones se mantienen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive y registra adaptadores
  await Hive.initFlutter();
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BuyAdapter());
  Hive.registerAdapter(DebtAdapter());

  // Abre las cajas necesarias
  await Hive.openBox<Income>('incomesBox');
  await Hive.openBox<Expense>('expensesBox');
  await Hive.openBox<Buy>('buysBox');
  await Hive.openBox<Debt>('debtBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BuyProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
      ],
      child: finoApp(),
    ),
  );
}

class finoApp extends StatefulWidget {
  const finoApp({super.key});

  @override
  _FinoAppState createState() => _FinoAppState();
}

class _FinoAppState extends State<finoApp> with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controlador para el TabBar
  Color backgroundColor = Color(0xFFADADAD);
  late PageController _pageController;
  ThemeMode _modoTema = ThemeMode.light;

  bool get esOscuro => _modoTema == ThemeMode.dark;
  List<Color> get currentColors => esOscuro ? colorsDark : colorsLight;

  // Colores para el modo claro
  final List<Color> colorsLight = [
    const Color(0xFF36A0DD), // HomeScreen
    const Color(0xFF28A745), // IncomesScreen
    const Color(0xFFE70000), // ExpensesScreen
    const Color(0xFFEC9128), // BuysScreen
    const Color(0xFF2C89DB), // DebtScreen
  ];

// Colores para el modo oscuro
  final List<Color> colorsDark = [
    const Color(0xFFC2C2C2), // HomeScreen
    const Color(0xFF86FF05), // IncomesScreen
    const Color(0xFFE70000), // ExpensesScreen
    const Color(0xFFFFD900), // BuysScreen
    const Color(0xFF00C8FF), // BuysScreen

  ];

  final ThemeData temaClaro = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      hintColor: Colors.blue,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
      ),
      tabBarTheme: TabBarTheme(
          labelColor: Color(0xFFFFFEFE),
          unselectedLabelColor: Color(0xFF161616)),
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      cardColor: Colors.white,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: const Color(0xFF131212)),
      ));

  final ThemeData temaOscuro = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      hintColor: Colors.blueAccent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
      ),
      tabBarTheme: TabBarTheme(
          labelColor: const Color(0xFF000000),
          unselectedLabelColor: Colors.white),
      iconTheme: IconThemeData(
        color: const Color(0xFF000000),
      ),
      cardColor: Color(0xFF070707),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
      ));

  void _changeTheme(ThemeMode modo) {
    setState(() {
      _modoTema = modo;
      backgroundColor = currentColors[_tabController.index];
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pageController = PageController(initialPage: _tabController.index);

    // Asegura que el color de fondo esté sincronizado al iniciar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBackgroundColor(_tabController.index);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Usa jumpToPage directamente para asegurar movimiento inmediato.
        _pageController.jumpToPage(_tabController.index);
        _updateBackgroundColor(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateBackgroundColor(int index) {
    setState(() {
      backgroundColor = currentColors[index];
    });
  }

  @override
  Widget build(BuildContext contex) {
    return MaterialApp(
      title: 'Fino App',
      home: Builder(
          builder: (context) => DefaultTabController(
              length: 5,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Fino App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.normal,
                      color: currentColors[_tabController.index],
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  centerTitle: true,
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: _tabController.index == 0 && esOscuro
                        ? Colors.white
                        : Theme.of(context).tabBarTheme.labelColor,
                    unselectedLabelColor:
                        Theme.of(context).tabBarTheme.unselectedLabelColor,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(
                      color: _tabController.index == 0 && esOscuro
                          ? const Color.fromARGB(255, 124, 124, 124)
                          : backgroundColor,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                    ),
                    indicatorPadding: EdgeInsets.only(left: -4, right: -4),
                    tabs: [
                      Tab(
                        icon: Icon(
                          Icons.home,
                          color: _tabController.index == 0
                              ? (esOscuro
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 255, 255, 255))
                              : (esOscuro
                                  ? const Color(0xFFBDBDBD)
                                  : const Color(0xFF7E7E7E)),
                        ),
                        text: 'Home',
                        iconMargin: const EdgeInsets.only(left: 10, right: 10),
                        key: const ValueKey('home'),
                      ),
                      Tab(
                        icon: Icon(
                          Icons.input_outlined,
                          color: _tabController.index == 1
                              ? (esOscuro
                                  ? const Color(0xFF000000)
                                  : const Color(0xFFFFFFFF))
                              : (esOscuro
                                  ? const Color(0xFFF0F0F0)
                                  : const Color(0xFF7E7E7E)),
                        ),
                        text: 'Ingresos',
                        key: const ValueKey('incomes'),
                      ),
                      Tab(
                        icon: Icon(
                          Icons.output_outlined,
                          color: _tabController.index == 2
                              ? (esOscuro
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255))
                              : (esOscuro
                                  ? const Color(0xFFBDBDBD)
                                  : const Color(0xFF7E7E7E)),
                        ),
                        text: 'Gastos',
                        key: ValueKey('expenses'),
                      ),
                      Tab(
                        icon: Icon(
                          Icons.warning_outlined,
                          color: _tabController.index == 3
                              ? (esOscuro
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255))
                              : (esOscuro
                                  ? const Color(0xFFBDBDBD)
                                  : const Color(0xFF7E7E7E)),
                        ),
                        text: 'Deudas',
                        iconMargin: EdgeInsets.all(5),
                        key: ValueKey('debts'),
                      ),
                      Tab(
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          color: _tabController.index == 4
                              ? (esOscuro
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : const Color.fromARGB(255, 255, 255, 255))
                              : (esOscuro
                                  ? const Color(0xFFBDBDBD)
                                  : const Color(0xFF7E7E7E)),
                        ),
                        text: 'Compras',
                        iconMargin: EdgeInsets.all(5),
                        key: ValueKey('buys'),
                      ),
                    ],
                  ),
                  actions: [
                    Switch(
                      value: esOscuro,
                      onChanged: (bool valor) {
                        _changeTheme(valor ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF181818),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                    ),
                  ],
                ),
                body: PageView(
                  controller: _pageController,
                  children: [
                    HomeScreen(
                        color: currentColors[0],
                        colors: currentColors,
                        changeTheme: _changeTheme,
                        modo: _modoTema),
                    IncomesScreen(
                        color: currentColors[1],
                        changeTheme: _changeTheme,
                        modo: _modoTema),
                    ExpensesScreen(
                        color: currentColors[2],
                        changeTheme: _changeTheme,
                        modo: _modoTema),
                    DebtsScreen(
                        color: currentColors[3],
                        changeTheme: _changeTheme,
                        modo: _modoTema),
                    BuysScreen(
                        color: currentColors[4],
                        changeTheme: _changeTheme,
                        modo: _modoTema),
                  ],
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                    _updateBackgroundColor(index);
                  },
                ),
              ))),
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      darkTheme: temaOscuro,
      themeMode: _modoTema,
    );
  }
}
