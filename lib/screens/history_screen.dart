import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
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
      DateTime dA = DateTime(int.parse(partsA[2]), int.parse(partsB[1]), int.parse(partsA[0]));
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
        _history[existingIndex] = {
          'date': date, 
          'weight': weight, 
          'height': height, 
          'imc': imc,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        _history.add({
          'date': date, 
          'weight': weight, 
          'height': height, 
          'imc': imc,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      _sortHistory();
    });
    _saveHistory();
  }

  void _deleteEntry(int indexInFullList) {
    setState(() {
      _history.removeAt(indexInFullList);
    });
    _saveHistory();
  }

  void _confirmDelete(int indexInFullList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text("Deseja deletar este registro do histórico?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteEntry(indexInFullList);
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

  void _showWeightHeightDialog(String dateStr, {double? initialWeight, double? initialHeight}) {
    TextEditingController weightCtrl = TextEditingController(text: initialWeight?.toString() ?? "");
    TextEditingController heightCtrl = TextEditingController(
      text: initialHeight?.toString() ?? (_history.isNotEmpty ? _history.first['height'].toString() : '175')
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initialWeight != null ? "Editar Registro ($dateStr)" : "Registro de Peso ($dateStr)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: "Peso (kg)", hintText: "Ex: 80.5")
              ),
              TextField(
                controller: heightCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: "Altura (cm)", hintText: "Ex: 175")
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar")
            ),
            ElevatedButton(
              onPressed: () {
                double w = double.tryParse(weightCtrl.text.replaceAll(',', '.')) ?? 0;
                double h = double.tryParse(heightCtrl.text.replaceAll(',', '.')) ?? 0;
                if (w > 0 && h > 0) {
                  Navigator.pop(context);
                  _processHistoryEntry(dateStr, w, h);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  List<String> _getAvailableMonths() {
    Set<String> months = {};
    DateTime now = DateTime.now();
    months.add('${now.month.toString().padLeft(2, '0')}/${now.year}');
    
    for (var item in _history) {
      List<String> parts = item['date'].split('/');
      if (parts.length == 3) {
        months.add('${parts[1]}/${parts[2]}');
      }
    }
    
    List<String> sorted = months.toList();
    sorted.sort((a, b) {
      int valA = int.parse(a.split('/')[1]) * 100 + int.parse(a.split('/')[0]);
      int valB = int.parse(b.split('/')[1]) * 100 + int.parse(b.split('/')[0]);
      return valB.compareTo(valA);
    });
    return sorted;
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
    List<String> availableMonths = _getAvailableMonths();
    if (!availableMonths.contains(_selectedMonthYear)) {
      _selectedMonthYear = availableMonths.first;
    }

    int currentM = int.parse(_selectedMonthYear.split('/')[0]);
    int currentY = int.parse(_selectedMonthYear.split('/')[1]);
    int daysInMonth = DateUtils.getDaysInMonth(currentY, currentM);
    
    List<FlSpot> spots = _getChartSpots(currentM, currentY, daysInMonth);
    
    List<dynamic> filteredHistory = _history.where((item) {
      List<String> parts = item['date'].split('/');
      return parts.length == 3 && parts[1] == currentM.toString().padLeft(2, '0') && parts[2] == currentY.toString();
    }).toList();

    double minY = 0;
    double maxY = 100;
    if (spots.isNotEmpty) {
      minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5;
      maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Evolução')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Evolução de Peso (kg)", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.primary
                      )
                    ),
                    DropdownButton<String>(
                      value: _selectedMonthYear,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.calendar_month),
                      style: TextStyle(
                        fontSize: 13, 
                        color: Theme.of(context).colorScheme.primary, 
                        fontWeight: FontWeight.w500
                      ),
                      dropdownColor: Colors.white,
                      items: availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) { if (val != null) setState(() { _selectedMonthYear = val; }); },
                    )
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: LineChart(LineChartData(
                    minY: minY < 0 ? 0 : minY,
                    maxY: maxY,
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots, 
                        isCurved: true, 
                        color: Colors.green, 
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1))
                      )
                    ],
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val % 5 == 0 || val == 1 || val == daysInMonth) {
                            return Text(val.toInt().toString(), style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox();
                        }
                      )),
                    ),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                  )),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) _showWeightHeightDialog(_formatDate(pickedDate));
              }, 
              icon: const Icon(Icons.add), 
              label: const Text("Novo Registro Manual"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
            ),
          ),
          
          const SizedBox(height: 10),
          const Divider(),
          
          Expanded(
            child: filteredHistory.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        "Nenhum registro neste mês",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Calcule seu IMC e salve para acompanhar sua evolução",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final item = filteredHistory[index];
                    int originalIndex = _history.indexOf(item);
                    final double imcValue = (item['imc'] as num).toDouble();
                    final String status = calcularImc(item['weight'], item['height'] / 100).split(' (')[0];
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: getImcBackgroundColor(imcValue),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                imcValue.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: getImcColor(imcValue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['date'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${item['weight']} kg · ${item['height']} cm",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: getImcColor(imcValue),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showWeightHeightDialog(
                                    item['date'], 
                                    initialWeight: (item['weight'] as num).toDouble(),
                                    initialHeight: (item['height'] as num).toDouble(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(originalIndex),
                                ),
                              ],
                            ),
                          ],
                        ),
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
