import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_drawer.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _trainings = [];
  String _selectedMonthYear = '';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadLocalTrainings();
  }

  void _loadLocalTrainings() {
    setState(() {
      _trainings = List.from(_supabaseService.trainingHistory);
      _sortTrainings();
    });
  }

  void _sortTrainings() {
    _trainings.sort((a, b) {
      List<String> partsA = a['date'].split('/');
      List<String> partsB = b['date'].split('/');
      DateTime dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
      DateTime dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
      return dateB.compareTo(dateA);
    });
  }

  Future<void> _saveTrainings() async {
    await _supabaseService.saveTraining(_trainings);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _processTrainingEntry(String date, bool trained, int duration) {
    int existingIndex = _trainings.indexWhere((t) => t['date'] == date);

    if (existingIndex != -1) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Atenção"),
            content: Text("Você já tem um registro para o dia $date. Deseja substituir pelo novo registro?"),
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
                    _trainings[existingIndex] = {
                      'date': date,
                      'trained': trained,
                      'duration': duration,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    };
                    _sortTrainings();
                  });
                  _saveTrainings();
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
        _trainings.add({
          'date': date,
          'trained': trained,
          'duration': duration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _sortTrainings();
      });
      _saveTrainings();
    }
  }

  void _deleteTraining(int index) {
    setState(() {
      _trainings.removeAt(index);
    });
    _saveTrainings();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text("Tem certeza que deseja deletar este registro de treino da nuvem?"),
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
                _deleteTraining(index);
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

  void _showDurationDialog(String dateStr) {
    TextEditingController durationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Treino do dia $dateStr"),
          content: TextField(
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Duração (em minutos)",
              hintText: "Ex: 60",
            ),
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
                int mins = int.tryParse(durationCtrl.text) ?? 0;
                if (mins > 0) {
                  Navigator.pop(context);
                  _processTrainingEntry(dateStr, true, mins);
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

  void _showPastTrainingDialog() async {
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Registro do dia $dateStr"),
          content: const Text("Você treinou neste dia?"),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _processTrainingEntry(dateStr, false, 0);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                foregroundColor: Colors.blue,
              ),
              child: const Text("Foi Descanso"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDurationDialog(dateStr);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Sim, Treinei", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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

      var dayData = _trainings.where((e) => e['date'] == dateStr).toList();
      double duration = 0;

      if (dayData.isNotEmpty && dayData.first['trained'] == true) {
        duration = (dayData.first['duration'] ?? 0).toDouble();
      }

      spots.add(FlSpot(i.toDouble(), duration));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    String todayStr = _formatDate(DateTime.now());
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
    maxY = maxY < 60 ? 60 : maxY + 15;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Treinos"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      drawer: const CustomDrawer(),
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
                      "Minutos por Dia",
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
                                  'Dia ${spot.x.toInt()}\n${spot.y.toInt()} min',
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
                              interval: 15,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4,
                                  child: Text(
                                    '${value.toInt()}m',
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
                          horizontalInterval: 15,
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
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Registro Rápido ($todayStr)",
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _processTrainingEntry(todayStr, false, 0),
                        icon: const Icon(Icons.hotel, color: Colors.blue),
                        label: const Text("Descanso", style: TextStyle(color: Colors.blue)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDurationDialog(todayStr),
                        icon: const Icon(Icons.fitness_center, color: Colors.white),
                        label: const Text("Treinei", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _showPastTrainingDialog,
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
              itemCount: _trainings.length,
              itemBuilder: (context, index) {
                final item = _trainings[index];
                bool isTrained = item['trained'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTrained ? Colors.green : Colors.blue,
                      child: Icon(
                        isTrained ? Icons.fitness_center : Icons.hotel,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item['date'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isTrained ? 'Treino: ${item['duration']} minutos' : 'Dia de descanso',
                      style: TextStyle(color: isTrained ? Colors.green[700] : Colors.blue[700]),
                    ),
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