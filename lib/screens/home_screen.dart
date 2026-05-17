import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/calculadora_logic.dart';
import 'splash_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _supabaseService = SupabaseService();
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String? _resultText;
  double? _lastWeight;
  double? _lastHeight;
  double? _lastImc;

  void _resetFields() {
    weightController.text = "";
    heightController.text = "";
    setState(() {
      _resultText = null;
      _lastWeight = null;
      _lastHeight = null;
      _lastImc = null;
      _formKey = GlobalKey<FormState>();
    });
  }

  Future<void> _saveToHistory() async {
    if (_lastWeight == null || _lastHeight == null || _lastImc == null) return;

    List<dynamic> history = List.from(_supabaseService.imcHistory);
    final now = DateTime.now();
    final String formattedDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    int existingIndex = history.indexWhere((h) => h['date'].toString() == formattedDate);

    if (existingIndex != -1) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Atenção"),
            content: Text("Você já tem uma medida salva hoje ($formattedDate). Deseja substituir pelos dados atuais?"),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  history[existingIndex] = {
                    'date': formattedDate,
                    'weight': _lastWeight,
                    'height': _lastHeight,
                    'imc': _lastImc,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  };
                  await _supabaseService.saveIMC(history);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Evolução atualizada!'), backgroundColor: Colors.green),
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
        'weight': _lastWeight,
        'height': _lastHeight,
        'imc': _lastImc,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await _supabaseService.saveIMC(history);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvo no seu histórico de evolução!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _performCalculation(double weight, double height) {
    setState(() {
      double heightInMeters = height / 100;
      _lastWeight = weight;
      _lastHeight = height;
      _lastImc = weight / (heightInMeters * heightInMeters);
      _resultText = calcularImc(weight, heightInMeters);
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
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), foregroundColor: Colors.green),
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
    double weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0;
    double height = double.tryParse(heightController.text.replaceAll(',', '.')) ?? 0;

    if (weight == 0 || height == 0) return;

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
    final Color resultColor = _lastImc != null ? getImcColor(_lastImc!) : Theme.of(context).primaryColor;
    final Color resultBgColor = _lastImc != null ? getImcBackgroundColor(_lastImc!) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora IMC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair da Conta',
            onPressed: () async {
              await SupabaseService().signOut();
              if (mounted) {
                // Ao deslogar, empurra o usuário de volta para o Splash Screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()), // <-- Retiramos o 'const' daqui
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2E7D32), size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Calculadora de IMC",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Insira seus dados abaixo",
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Peso (kg)", 
                ),
                textAlign: TextAlign.center,
                controller: weightController,
                validator: (value) => (value == null || value.isEmpty) ? "Insira seu Peso!" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Altura (cm)", 
                ),
                textAlign: TextAlign.center,
                controller: heightController,
                validator: (value) => (value == null || value.isEmpty) ? "Insira sua Altura!" : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56.0,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _validateAndCalculate();
                    }
                  },
                  style: ElevatedButton.styleFrom(),
                  child: const Text("CALCULAR IMC", style: TextStyle(fontSize: 18.0, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 32),
              
              if (_resultText != null) 
                Card(
                  elevation: 0,
                  color: resultBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: resultColor.withOpacity(0.4), width: 0.5)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(getImcIcon(_lastImc!), color: getImcColor(_lastImc!), size: 28),
                            const SizedBox(width: 10),
                            const Text(
                              "Resultado do Cálculo", 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _resultText!, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: getImcColor(_lastImc!), fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        const Divider(height: 30),
                        const Text(
                          "Deseja salvar esta medida na sua evolução pessoal?", 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontSize: 14, color: Colors.black54)
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _saveToHistory,
                          icon: const Icon(Icons.history, color: Colors.white),
                          label: const Text("Salvar no meu Histórico", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getImcColor(_lastImc!), 
                            minimumSize: const Size(double.infinity, 45)
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
