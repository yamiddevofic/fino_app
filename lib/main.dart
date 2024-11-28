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
      child: fino_app(),
    ),
  );
}

class fino_app extends StatelessWidget {
  const fino_app({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fino App',
      home: const FinoApp(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Poppins',
      ),
    );
  }
}


class FinoApp extends StatelessWidget {
  const FinoApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colors = [
      0xFF009B17,
      0xFF1D8BEC,
      0xFFD40808,
      0xFF0015FF,
    ];
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fino App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontStyle: FontStyle.normal,color: Colors.white )),
          backgroundColor: const Color.fromARGB(255, 79, 147, 248),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              color: Color(0x38ffffff),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              
            ),
            tabs: [
              Tab(icon: Icon(Icons.home, color: Colors.white), text: 'Home'),
              Tab(icon: Icon(Icons.input_outlined, color: Colors.white), text: 'Incomes'),
              Tab(icon: Icon(Icons.output_outlined, color: Colors.white), text: 'Expenses'),
              Tab(icon: Icon(Icons.shopping_bag, color: Colors.white), text: 'Buys'),
            ],
          ),
          leading: const Icon(Icons.menu, color: Colors.white),
        ),
        body: TabBarView(
            children: [
              HomeScreen(colors: colors),
              IncomesScreen(colors: colors),
              ExpensesScreen(colors: colors),
              BuysScreen(colors: colors),
            ],
          ),
      )
    );
  }
}

