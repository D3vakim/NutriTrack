import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_drawer.dart';
import '../utils/calculadora_logic.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _history = [];
  String _selectedMonthYear = '';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadLocalHistory();
  }

  void _loadLocalHistory() {
    setState(() {
      _history = List.from(_supabaseService.imcHistory);
      _sortHistory();
    });
  }

  void _sortHistory() {
    _history.sort((a, b) {
      List<String> partsA = a['date'].toString().split('/');
      List<String> partsB = b['date'].toString().split('/');
      DateTime dA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
      DateTime dB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
      return dB.compareTo(dA);
    });
  }

  Future<void> _saveHistory() async {
    await _supabaseService.saveIMC(_history);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _processHistoryEntry(String date, double weight, double height) {
    int existingIndex = _history.indexWhere((h) => h['date'].toString() == date);
    double imc = weight / ((height / 100) * (height / 100));

    setState(() {
      if (existingIndex != -1) {
        _history[existingIndex] = {'date': date, 'weight': weight, 'height': height, 'imc': imc};
      } else {
        _history.add({'date': date, 'weight': weight, 'height': height, 'imc': imc});
      }
      _sortHistory();
    });
    _saveHistory();
  }

  void _deleteEntry(int index) {
    setState(() {
      _history.removeAt(index);
    });
    _saveHistory();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text("Deseja deletar este registro do histórico na nuvem?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), foregroundColor: Colors.green),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteEntry(index);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Deletar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showWeightHeightDialog(String dateStr) {
    TextEditingController weightCtrl = TextEditingController();
    TextEditingController heightCtrl = TextEditingController(text: _history.isNotEmpty ? _history.first['height'].toString() : '175');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Registro de Peso ($dateStr)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Peso (kg)")),
              TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Altura (cm)")),
            ],
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                double w = double.tryParse(weightCtrl.text) ?? 0;
                double h = double.tryParse(heightCtrl.text) ?? 0;
                if (w > 0 && h > 0) {
                  Navigator.pop(context);
                  _processHistoryEntry(dateStr, w, h);
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _showPastEntryDialog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) _showWeightHeightDialog(_formatDate(pickedDate));
  }

  List<FlSpot> _getChartSpots(int month, int year, int daysInMonth) {
    List<FlSpot> spots = [];
    for (int i = 1; i <= daysInMonth; i++) {
      String dateStr = "${i.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year";
      var dayData = _history.where((e) => e['date'].toString() == dateStr).toList();
      if (dayData.isNotEmpty) {
        spots.add(FlSpot(i.toDouble(), (dayData.first['weight'] ?? 0).toDouble()));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    int currentM = int.parse(_selectedMonthYear.split('/')[0]);
    int currentY = int.parse(_selectedMonthYear.split('/')[1]);
    int days = DateUtils.getDaysInMonth(currentY, currentM);
    List<FlSpot> spots = _getChartSpots(currentM, currentY, days);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Evolução'), centerTitle: true, backgroundColor: Colors.green),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: LineChart(LineChartData(
              minY: 0,
              lineBarsData: [LineChartBarData(spots: spots, isCurved: false, color: Colors.green, barWidth: 2)],
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            )),
          ),
          ElevatedButton.icon(onPressed: _showPastEntryDialog, icon: const Icon(Icons.calendar_month), label: const Text("Adicionar registro anterior")),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                final String status = calcularImc(item['weight'], item['height'] / 100).split(' (')[0];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text('${item['date']} - IMC: ${item['imc'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Peso: ${item['weight']}kg | Status: $status'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(index)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}