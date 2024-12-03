import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BuysScreen extends StatefulWidget {
  final Color color;
  final Function(ThemeMode) cambiarTema;
  const BuysScreen({super.key, required this.color, required this.cambiarTema});

  @override
  _BuysScreenState createState() => _BuysScreenState();
}

class _BuysScreenState extends State<BuysScreen> {
  final _formKey = GlobalKey<FormState>();
  String _buyName = '';
  double _buyAmount = 0.0;

  void sendBuy() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Provider.of<BuyProvider>(context, listen: false).addBuy(
        Buy(name: _buyName, amount: _buyAmount),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Compra agregada exitosamente',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _buyName = '';
        _buyAmount = 0.0;
      });
    }
  }

  void viewBuys() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuysListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Agregar Compra',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingrese un nombre';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _buyName = value!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Por favor, ingrese un monto válido';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _buyAmount = double.parse(value!);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF6BC714),
                        ),
                        onPressed: sendBuy,
                        child: const Text('Agregar Compra'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: viewBuys,
                        child: const Text('Ver Compras'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BuysListScreen extends StatelessWidget {
  const BuysListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buys = Provider.of<BuyProvider>(context).buys;
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
      ),
      body: ListView.builder(
        itemCount: buys.length,
        itemBuilder: (context, index) {
          final buy = buys[index];
          return Card(
            child: ListTile(
              title: Text(buy.name),
              subtitle: Text(
                'Monto: \$${numberFormat.format(buy.amount)}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Eliminar Compra'),
                        content: const Text(
                            '¿Estás seguro de que deseas eliminar este compra?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Provider.of<BuyProvider>(context,
                                      listen: false)
                                  .deleteBuy(index);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Compra eliminado exitosamente',
                                      )));
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
