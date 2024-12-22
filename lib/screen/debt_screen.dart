import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DebtsScreen extends StatefulWidget {
  final Color color;
  final Function(ThemeMode) changeTheme;
  final ThemeMode modo;
  const DebtsScreen({super.key, required this.color, required this.changeTheme, required this.modo});
  @override
  _DebtsScreenState createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _debtName = '';
  double _debtAmount = 0.0;

  void sendDebt() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Provider.of<DebtProvider>(context, listen: false).addDebt(
        Debt(name: _debtName, amount: _debtAmount),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Deuda agregada exitosamente',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _debtName = '';
        _debtAmount = 0.0;
      });
    }
  }

  void viewDebts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebtsListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.modo == ThemeMode.dark ? const Color(0xFF070707) : widget.color,
      body: Container(
        width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: widget.color,
              width: 8.0,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Card(
                elevation: 4,
                color: widget.modo == ThemeMode.dark ? const Color(0xFF070707) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: widget.color,
                    width: 2.0,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Agregar Deuda',
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
                            _debtName = value!;
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
                            _debtAmount = double.parse(value!);
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF6BC714),
                          ),
                          onPressed: sendDebt,
                          child: const Text('Agregar Deuda'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: viewDebts,
                          child: const Text('Ver Deudas'),
                        ),
                      ],
                    ),
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

class DebtsListScreen extends StatelessWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debts = Provider.of<DebtProvider>(context).debts;
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas pendientes'),
      ),
      body: ListView.builder(
        itemCount: debts.length,
        itemBuilder: (context, index) {
          final debt = debts[index];
          return Card(
            child: ListTile(
              title: Text(debt.name),
              subtitle: Text(
                'Monto: \$${numberFormat.format(debt.amount)}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Eliminar Deuda'),
                        content: const Text(
                            '¿Estás seguro de que deseas eliminar esta deuda?'),
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
                              Provider.of<DebtProvider>(context,
                                      listen: false)
                                  .deleteDebt(index);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Deuda eliminada exitosamente',
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
