import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  final Color color;
  final Function(ThemeMode) changeTheme;
  final ThemeMode modo;
  const ExpensesScreen({super.key, required this.color, required this.changeTheme, required this.modo});  

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  String _expenseName = '';
  double _expenseAmount = 0.0;

  void sendExpense() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Provider.of<ExpenseProvider>(context, listen: false).addExpense(
        Expense(name: _expenseName, amount: _expenseAmount),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gasto agregado exitosamente',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _expenseName = '';
        _expenseAmount = 0.0;
      });
    }
  }

  void viewExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpensesListScreen(),
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
                          'Agregar Gasto',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextFormField(
                          // colocar color de texto en el labelText
                          decoration: const InputDecoration(labelText: 'Nombre'
                          ,),

                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese un nombre';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _expenseName = value!;
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
                            _expenseAmount = double.parse(value!);
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: sendExpense,
                          child: const Text('Agregar Gasto'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: viewExpenses,
                          child: const Text('Ver Gastos'),
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

class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = Provider.of<ExpenseProvider>(context).expenses;
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Gastos'),
      ),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Card(
            child: ListTile(
              title: Text(expense.name),
              subtitle: Text(
                'Monto: \$${numberFormat.format(expense.amount)}',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Eliminar Gasto'),
                        content: const Text(
                            '¿Estás seguro de que deseas eliminar este gasto?'),
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
                              Provider.of<ExpenseProvider>(context,
                                      listen: false)
                                  .deleteExpense(index);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Gasto eliminado exitosamente',
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
