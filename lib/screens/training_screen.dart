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

    setState(() {
      if (existingIndex != -1) {
        _trainings[existingIndex] = {
          'date': date,
          'trained': trained,
          'duration': duration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        _trainings.add({
          'date': date,
          'trained': trained,
          'duration': duration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      _sortTrainings();
    });
    _saveTrainings();
  }

  void _deleteTraining(int indexInFullList) {
    setState(() {
      _trainings.removeAt(indexInFullList);
    });
    _saveTrainings();
  }

  void _confirmDelete(int indexInFullList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text("Tem certeza que deseja deletar este registro de treino?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), foregroundColor: Colors.green),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTraining(indexInFullList);
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

  void _showDurationDialog(String dateStr, {int? initialDuration}) {
    TextEditingController durationCtrl = TextEditingController(text: initialDuration?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initialDuration != null ? "Editar Treino ($dateStr)" : "Treino do dia $dateStr"),
          content: TextField(
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Duração (em minutos)", hintText: "Ex: 60"),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context), 
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), foregroundColor: Colors.green),
              child: const Text("Cancelar")
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
    );
    if (pickedDate != null) {
      String dateStr = _formatDate(pickedDate);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Registro do dia $dateStr"),
          content: const Text("Você treinou neste dia?"),
          actions: [
            OutlinedButton(
              onPressed: () { Navigator.pop(context); _processTrainingEntry(dateStr, false, 0); }, 
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue), foregroundColor: Colors.blue),
              child: const Text("Descanso")
            ),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _showDurationDialog(dateStr); }, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Sim, Treinei", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  List<String> _getAvailableMonths() {
    Set<String> months = {};
    DateTime now = DateTime.now();
    months.add('${now.month.toString().padLeft(2, '0')}/${now.year}');
    for (var item in _trainings) {
      List<String> parts = item['date'].split('/');
      months.add('${parts[1]}/${parts[2]}');
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
      var dayData = _trainings.where((e) => e['date'] == dateStr).toList();
      double duration = (dayData.isNotEmpty && dayData.first['trained'] == true) 
          ? (dayData.first['duration'] ?? 0).toDouble() : 0;
      spots.add(FlSpot(i.toDouble(), duration));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    String todayStr = _formatDate(DateTime.now());
    List<String> availableMonths = _getAvailableMonths();
    if (!availableMonths.contains(_selectedMonthYear)) _selectedMonthYear = availableMonths.first;

    int currentM = int.parse(_selectedMonthYear.split('/')[0]);
    int currentY = int.parse(_selectedMonthYear.split('/')[1]);
    int daysInMonth = DateUtils.getDaysInMonth(currentY, currentM);

    List<FlSpot> spots = _getChartSpots(currentM, currentY, daysInMonth);
    List<dynamic> filteredTrainings = _trainings.where((item) {
      List<String> parts = item['date'].split('/');
      return parts[1] == currentM.toString().padLeft(2, '0') && parts[2] == currentY.toString();
    }).toList();

    double maxY = 60;
    for (var spot in spots) { if (spot.y > maxY) maxY = spot.y; }
    maxY += 15;

    return Scaffold(
      appBar: AppBar(title: const Text("Meus Treinos"), centerTitle: true, backgroundColor: Colors.green),
      drawer: const CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12.0), 
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tempo de Treino (min)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    DropdownButton<String>(
                      value: _selectedMonthYear,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.calendar_month, color: Colors.green),
                      items: availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) { if (val != null) setState(() { _selectedMonthYear = val; }); },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: LineChart(LineChartData(
                    minY: 0, 
                    maxY: maxY, 
                    minX: 1, 
                    maxX: daysInMonth.toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots, 
                        isCurved: true, // Agora curvo como no histórico
                        color: Colors.green, 
                        barWidth: 3, // Espessura idêntica
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
          
          if (_selectedMonthYear == availableMonths.first)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: ListTile(
                  title: Text("Registrar Hoje ($todayStr)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.hotel, color: Colors.blue), onPressed: () => _processTrainingEntry(todayStr, false, 0)),
                      IconButton(icon: const Icon(Icons.fitness_center, color: Colors.green), onPressed: () => _showDurationDialog(todayStr)),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _showPastTrainingDialog, 
              icon: const Icon(Icons.calendar_month), 
              label: const Text("Novo Registro Manual"), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45))
            ),
          ),
          
          const Divider(),
          Expanded(
            child: filteredTrainings.isEmpty 
              ? const Center(child: Text("Nenhum registro neste mês."))
              : ListView.builder(
                  itemCount: filteredTrainings.length,
                  itemBuilder: (context, index) {
                    final item = filteredTrainings[index];
                    int originalIndex = _trainings.indexOf(item);
                    bool isTrained = item['trained'];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(isTrained ? Icons.fitness_center : Icons.hotel, color: isTrained ? Colors.green : Colors.blue),
                        title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isTrained ? '${item['duration']} minutos' : 'Descanso'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => isTrained ? _showDurationDialog(item['date'], initialDuration: item['duration']) : _showPastTrainingDialog()),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _confirmDelete(originalIndex)),
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
