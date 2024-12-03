import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/screen/buys_screen.dart';
import 'package:fino_app/screen/expenses_screen.dart';
import 'package:fino_app/screen/home_screen.dart';
import 'package:fino_app/screen/incomes_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:provider/provider.dart';

// Otras importaciones se mantienen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive y registra adaptadores
  await Hive.initFlutter();
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BuyAdapter());

  // Abre las cajas necesarias
  await Hive.openBox<Income>('incomesBox');
  await Hive.openBox<Expense>('expensesBox');
  await Hive.openBox<Buy>('buysBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BuyProvider()),
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

  final List<Color> colors = [
    const Color(0xFFFFFFFF), // Verde
    const Color(0xFF28A745), // Azul
    const Color(0xFFFF5733), // Rojo
    const Color.fromARGB(255, 237, 179, 4),
  ];

  final ThemeData temaClaro = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    hintColor: Colors.blue,
    // Otros ajustes
  );

  final ThemeData temaOscuro = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    hintColor: Colors.blueAccent,
    // Otros ajustes
  );


  void _cambiarTema(ThemeMode modo) {
    setState(() {
      _modoTema = modo;
    });
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      backgroundColor = colors[index];
    });
  }



  @override
  Widget build(BuildContext contex) {
    return MaterialApp(
      title: 'Fino App',
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Fino App',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.normal,
                    color: Color(0xFF28A745)
                  ),
            ),
            backgroundColor: Colors.white,
            centerTitle: true,
            bottom:  TabBar(
              controller: _tabController,
              labelColor: _tabController.index == 0 ? const Color(0xFF171717) : const Color(0xFFFFFFFF),
              unselectedLabelColor: Color(0xFF161616),
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                color: _tabController.index == 0 ? const Color.fromARGB(255, 194, 200, 232) : backgroundColor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              ),
              indicatorPadding: EdgeInsets.only(left: -4, right: -4),
              tabs: [
                Tab(
                  icon: Icon(Icons.home, color: _tabController.index == 0 ? const Color(0xFF171717) : const Color(0xFF151515)),
                  text: 'Home',
                  iconMargin: const EdgeInsets.only(left: 10, right: 10),
                  key: const ValueKey('home'),
                ),
                Tab(
                  icon: Icon(Icons.input_outlined, color: _tabController.index == 1 ? Colors.white : const Color(0xFF151515)),
                  text: 'Ingresos',
                  key: const ValueKey('incomes'),
                ),
                Tab(
                  icon: Icon(Icons.output_outlined, color: _tabController.index == 2 ? Colors.white : const Color(0xFF151515)),
                  text: 'Gastos',
                  key: ValueKey('expenses'),
                ),
                Tab(
                  icon: Icon(Icons.shopping_bag, color: _tabController.index == 3 ? Colors.white : const Color(0xFF151515)),
                  text: 'Compras',
                  iconMargin: EdgeInsets.all(5),
                  key: ValueKey('buys'),
                ),
              ],
            ),
            leading:
                const Icon(Icons.menu, color: Color(0xFF1A1A1A)),
            actions: [
              Switch(
              value: esOscuro,
              onChanged: (bool valor) {
                _cambiarTema(valor ? ThemeMode.dark : ThemeMode.light);
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
              HomeScreen(color: colors[0], colors: colors, cambiarTema: _cambiarTema),
              IncomesScreen(color: colors[1], cambiarTema: _cambiarTema),
              ExpensesScreen(color: colors[2], cambiarTema: _cambiarTema),
              BuysScreen(color: colors[3], cambiarTema: _cambiarTema),
            ],
            onPageChanged: (index) {
              _tabController.animateTo(index);
              _updateBackgroundColor(index);
            },
          ),

        )),
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      darkTheme: temaOscuro,
      themeMode: _modoTema,
    );
  }
}


