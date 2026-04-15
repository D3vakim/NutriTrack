import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/custom_drawer.dart';
import '../utils/calculadora_logic.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  String _selectedMonthYear = '';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadHistory();
  }

  void _sortHistory() {
    _history.sort((a, b) {
      String dateA = a['date'].toString().substring(0, 10);
      String dateB = b['date'].toString().substring(0, 10);
      List<String> partsA = dateA.split('/');
      List<String> partsB = dateB.split('/');
      DateTime dA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
      DateTime dB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
      return dB.compareTo(dA);
    });
  }

  // --- MUDANÇA AQUI: Nova forma de carregar o histórico de IMC ---
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('imc_history');

      if (jsonString != null) {
        setState(() {
          _history = jsonDecode(jsonString);
          _sortHistory();
        });
      }
    } catch (e) {
      setState(() {
        _history = [];
      });
    }
  }

  // --- MUDANÇA AQUI: Nova forma de salvar o histórico de IMC ---
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imc_history', jsonEncode(_history));
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _processHistoryEntry(String date, double weight, double height) {
    int existingIndex = _history.indexWhere((h) => h['date'].toString().substring(0, 10) == date);
    double imc = weight / ((height / 100) * (height / 100));

    if (existingIndex != -1) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Atenção"),
            content: Text("Você já tem um registro para o dia $date. Deseja substituir pelo novo peso?"),
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
                onPressed: () {
                  setState(() {
                    _history[existingIndex] = {
                      'date': date,
                      'weight': weight,
                      'height': height,
                      'imc': imc,
                    };
                    _sortHistory();
                  });
                  _saveHistory();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Substituir", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _history.add({
          'date': date,
          'weight': weight,
          'height': height,
          'imc': imc,
        });
        _sortHistory();
      });
      _saveHistory();
    }
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
          content: const Text("Tem certeza que deseja deletar este registro do seu histórico?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                foregroundColor: Colors.green,
              ),
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
    String defaultHeight = '175';
    if (_history.isNotEmpty) {
      defaultHeight = _history.first['height'].toString();
    }

    TextEditingController weightCtrl = TextEditingController();
    TextEditingController heightCtrl = TextEditingController(text: defaultHeight);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Registro de Peso ($dateStr)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Peso (kg)"),
              ),
              TextField(
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Altura (cm)"),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                foregroundColor: Colors.green,
              ),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                double w = double.tryParse(weightCtrl.text) ?? 0;
                double h = double.tryParse(heightCtrl.text) ?? 0;
                if (w > 0 && h > 0) {
                  Navigator.pop(context);
                  _processHistoryEntry(dateStr, w, h);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    String dateStr = _formatDate(pickedDate);
    if (!mounted) return;
    _showWeightHeightDialog(dateStr);
  }

  List<String> _getAvailableMonths() {
    int currentYear = DateTime.now().year;
    List<String> months = [];
    for (int y = currentYear - 1; y <= currentYear + 1; y++) {
      for (int m = 1; m <= 12; m++) {
        months.add('${m.toString().padLeft(2, '0')}/$y');
      }
    }
    months.sort((a, b) {
      int valA = int.parse(a.split('/')[1]) * 100 + int.parse(a.split('/')[0]);
      int valB = int.parse(b.split('/')[1]) * 100 + int.parse(b.split('/')[0]);
      return valB.compareTo(valA);
    });
    return months;
  }

  List<FlSpot> _getChartSpots(int month, int year, int daysInMonth) {
    List<FlSpot> spots = [];

    for (int i = 1; i <= daysInMonth; i++) {
      String dateStr = "${i.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year";

      var dayData = _history.where((e) => e['date'].toString().substring(0, 10) == dateStr).toList();
      double weight = 0;

      if (dayData.isNotEmpty) {
        weight = (dayData.first['weight'] ?? 0).toDouble();
      }

      spots.add(FlSpot(i.toDouble(), weight));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    List<String> availableMonths = _getAvailableMonths();

    if (!availableMonths.contains(_selectedMonthYear)) {
      _selectedMonthYear = availableMonths.first;
    }

    int currentFilterMonth = int.parse(_selectedMonthYear.split('/')[0]);
    int currentFilterYear = int.parse(_selectedMonthYear.split('/')[1]);
    int daysInMonth = DateUtils.getDaysInMonth(currentFilterYear, currentFilterMonth);

    List<FlSpot> spots = _getChartSpots(currentFilterMonth, currentFilterYear, daysInMonth);

    double maxY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY == 0 ? 100 : maxY + 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Evolução'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      drawer: CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            height: 300,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 16.0, 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Peso por Dia (kg)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                    DropdownButton<String>(
                      value: _selectedMonthYear,
                      items: availableMonths.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMonthYear = newValue;
                          });
                        }
                      },
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        minX: 1,
                        maxX: daysInMonth.toDouble(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  'Dia ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)} kg',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            color: Colors.green,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: Colors.green,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.15),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 || value > daysInMonth) return const SizedBox.shrink();
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4,
                                  child: Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 9, color: Colors.black87),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4,
                                  child: Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 20,
                          getDrawingHorizontalLine: (value) {
                            return const FlLine(color: Colors.black12, strokeWidth: 1);
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _showPastEntryDialog,
              icon: const Icon(Icons.calendar_month),
              label: const Text("Adicionar registro anterior"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                String displayDate = item['date'].toString().substring(0, 10);
                final String status = calcularImc(item['weight'], item['height'] / 100).split(' (')[0];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: ListTile(
                    title: Text(
                      '$displayDate - IMC: ${item['imc'].toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Peso: ${item['weight']}kg | Altura: ${item['height']}cm\nStatus: $status'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(index),
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