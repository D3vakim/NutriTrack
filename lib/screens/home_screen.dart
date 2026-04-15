import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/calculadora_logic.dart';
import '../widgets/custom_drawer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _infoText = "Informe seus dados!";

  void _resetFields() {
    weightController.text = "";
    heightController.text = "";
    setState(() {
      _infoText = "Informe seus dados!";
      _formKey = GlobalKey<FormState>();
    });
  }

  // --- MUDANÇA AQUI: Nova forma de salvar no histórico compartilhando a mesma chave ---
  Future<void> _saveToHistory(double weight, double height, double imc) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('imc_history');
    List<dynamic> history = [];

    if (jsonString != null) {
      try {
        history = jsonDecode(jsonString);
      } catch (e) {
        history = [];
      }
    }

    final now = DateTime.now();
    final String formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    int existingIndex = history.indexWhere((h) => h['date'].toString().substring(0, 10) == formattedDate);

    if (existingIndex != -1) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Atenção"),
            content: Text("Você já salvou uma medida hoje ($formattedDate). Deseja substituir os dados anteriores?"),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  foregroundColor: Colors.green,
                ),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  history[existingIndex] = {
                    'date': formattedDate,
                    'weight': weight,
                    'height': height,
                    'imc': imc,
                  };

                  await prefs.setString('imc_history', jsonEncode(history));

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medida atualizada com sucesso!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Substituir", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } else {
      history.insert(0, {
        'date': formattedDate,
        'weight': weight,
        'height': height,
        'imc': imc,
      });

      await prefs.setString('imc_history', jsonEncode(history));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvo no seu histórico de acompanhamento!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _performCalculation(double weight, double height) {
    setState(() {
      double heightInMeters = height / 100;
      double imc = weight / (heightInMeters * heightInMeters);

      _infoText = calcularImc(weight, heightInMeters);
      _saveToHistory(weight, height, imc);
    });
  }

  void _showWarningDialog(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Atenção"),
          content: Text(message),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                foregroundColor: Colors.green,
              ),
              child: const Text("Corrigir"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _validateAndCalculate() {
    double weight = double.parse(weightController.text);
    double height = double.parse(heightController.text);

    bool heightWarning = height > 251 || height < 54;
    bool weightWarning = weight > 650;

    if (heightWarning) {
      _showWarningDialog(
        "A medida está em centímetros. Você tem certeza que essa é sua real altura?",
            () {
          if (weightWarning) {
            _showWarningDialog(
              "Você tem certeza que o peso está correto?",
                  () => _performCalculation(weight, height),
            );
          } else {
            _performCalculation(weight, height);
          }
        },
      );
    } else if (weightWarning) {
      _showWarningDialog(
        "Você tem certeza que o peso está correto?",
            () => _performCalculation(weight, height),
      );
    } else {
      _performCalculation(weight, height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculadora de IMC"),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFields,
          )
        ],
      ),
      drawer: CustomDrawer(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.person_outline, size: 120.0, color: Colors.green),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Peso (kg)",
                    labelStyle: TextStyle(color: Colors.green)),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontSize: 25.0),
                controller: weightController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Insira seu Peso!";
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Altura (cm)",
                    labelStyle: TextStyle(color: Colors.green)),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontSize: 25.0),
                controller: heightController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Insira sua Altura!";
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: SizedBox(
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _validateAndCalculate();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Calcular",
                      style: TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
              ),
              Text(
                _infoText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontSize: 25.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}