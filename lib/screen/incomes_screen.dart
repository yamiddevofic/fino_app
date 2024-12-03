import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class IncomesScreen extends StatefulWidget {
  final Color color;
  final Function(ThemeMode) cambiarTema;
  final ThemeMode modo;
  const IncomesScreen({super.key, required this.color, required this.cambiarTema, required this.modo});  
  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  bool get esOscuro => Theme.of(context).brightness == Brightness.dark;
  final _formKey = GlobalKey<FormState>();
  String _incomeName = '';
  double _incomeAmount = 0.0;

  /// Método para agregar un ingreso.
  void _addIncome() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Agregar ingreso al Provider
      Provider.of<IncomeProvider>(context, listen: false).addIncome(
        Income(name: _incomeName, amount: _incomeAmount),
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Ingreso agregado exitosamente',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );

      // Limpiar formulario
      _formKey.currentState!.reset();
      setState(() {
        _incomeName = '';
        _incomeAmount = 0.0;
      });
    }
  }

  /// Método para navegar a la lista de ingresos.
  void _navigateToList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncomesListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.modo == ThemeMode.dark ? const Color(0xFF070707) : widget.color,
      body: Center(
        //dar bordes que ocupe toda la screen
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.color,
              width: 2.0,
              style: BorderStyle.solid,
              //color: widget.modo == ThemeMode.light ? Colors.white : widget.color,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Agregar Ingreso',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, ingrese un nombre';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _incomeName = value!.trim();
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Monto'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null ||
                                double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Por favor, ingrese un monto válido';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _incomeAmount = double.parse(value!);
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: _addIncome,
                          child: const Text('Agregar Ingreso'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: _navigateToList,
                          child: const Text('Ver Ingresos'),
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

class IncomesListScreen extends StatelessWidget {
  const IncomesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incomes = Provider.of<IncomeProvider>(context).incomes;
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Ingresos'),
      ),
      body: incomes.isEmpty
          ? const Center(
              child: Text(
                'No hay ingresos registrados',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: incomes.length,
              itemBuilder: (context, index) {
                final income = incomes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(income.name),
                    subtitle: Text(
                      'Monto: \$${numberFormat.format(income.amount)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Eliminar Ingreso'),
                                content: const Text(
                                    '¿Estás seguro de que deseas eliminar este ingreso?'),
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
                                      Provider.of<IncomeProvider>(context,
                                              listen: false)
                                          .deleteIncome(index);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(
                                                'Ingreso eliminado exitosamente',
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
