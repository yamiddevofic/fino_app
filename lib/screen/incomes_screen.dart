import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key, required this.colors});
  final List<int> colors;

  @override
  _IncomesScreenState createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _incomeName = '';
  double _incomeAmount = 0.0;

  void sendIncomes() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Provider.of<IncomeProvider>(context, listen: false).addIncome(
        Income(name: _incomeName, amount:  _incomeAmount,),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Ingreso agregado exitosamente',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );

      // Limpiar los campos de entrada
      _formKey.currentState!.reset();
      setState(() {
        _incomeName = '';
        _incomeAmount = 0.0;
      });
    } else {
      // Mostrar mensaje de error si es necesario
    }
  }

  void viewIncomes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomesListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(widget.colors[1]),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 300,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Agregar Ingreso',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese un nombre';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _incomeName = value!;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                          ),
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
                            _incomeAmount = double.parse(value!);
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: sendIncomes,
                          child: const Text('Agregar Ingreso'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: viewIncomes,
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
  Widget build(BuildContext context, ) {
    final incomes = Provider.of<IncomeProvider>(context).incomes;
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Ingresos'),
      ),
      body: ListView.builder(
        itemCount: incomes.length,
        itemBuilder: (context, index) {
          final income = incomes[index];
          return Card(
            child: ListTile(
              title: Text(income.name),
              subtitle: Text(
                'Monto: \$${numberFormat.format(income.amount)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
        },
      ),
    );
  }
}