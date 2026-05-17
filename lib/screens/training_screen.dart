import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';

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

    _supabaseService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _supabaseService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _trainings = List.from(_supabaseService.trainingHistory);
        _sortTrainings();
      });
    }
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

  // ✅ LOGICA CORRIGIDA: forceOverride ignora o alerta apenas quando clicamos no lápis de "Editar"
  void _processTrainingEntry(String date, bool trained, int duration, {bool forceOverride = false}) {
    int existingIndex = _trainings.indexWhere((t) => t['date'] == date);

    if (existingIndex != -1 && !forceOverride) {
      // Exibe a mensagem de segurança ao tentar sobrepor um dia existente
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Atenção"),
            content: Text("Você já tem um registro para o dia $date. Deseja substituir pelo novo registro?"),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
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
      // Adiciona normalmente ou substitui silenciosamente se for uma Edição (forceOverride)
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

  void _showDurationDialog(String dateStr, {int? initialDuration, bool forceOverride = false}) {
    TextEditingController durationCtrl = TextEditingController(text: initialDuration?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initialDuration != null || forceOverride ? "Editar Treino ($dateStr)" : "Treino do dia $dateStr"),
          content: TextField(
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Duração (em minutos)", hintText: "Ex: 60"),
          ),
          actions: [
            OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar")
            ),
            ElevatedButton(
              onPressed: () {
                int mins = int.tryParse(durationCtrl.text) ?? 0;
                if (mins > 0) {
                  Navigator.pop(context);
                  // Passa a variável de controle para evitar alertas duplos
                  _processTrainingEntry(dateStr, true, mins, forceOverride: forceOverride || initialDuration != null);
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
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
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
      return parts.length == 3 && parts[1] == currentM.toString().padLeft(2, '0') && parts[2] == currentY.toString();
    }).toList();

    double maxY = 60;
    for (var spot in spots) { if (spot.y > maxY) maxY = spot.y; }
    maxY += 15;

    return Scaffold(
      appBar: AppBar(title: const Text("Meus Treinos")),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))
                ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tempo de Treino (min)", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    DropdownButton<String>(
                      value: _selectedMonthYear,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.calendar_month),
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                      dropdownColor: Colors.white,
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
                            if (val % 5 == 0 || val == 1 || val == daysInMonth) return Text(val.toInt().toString(), style: const TextStyle(fontSize: 10));
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
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200, width: 1)),
                child: ListTile(
                  title: Text("Registrar Hoje ($todayStr)", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: "Registrar descanso",
                        child: IconButton(
                            icon: const Icon(Icons.hotel, color: Colors.blue),
                            onPressed: () => _processTrainingEntry(todayStr, false, 0) // Ativa o alerta se já existir
                        ),
                      ),
                      Tooltip(
                        message: "Registrar treino",
                        child: IconButton(
                            icon: const Icon(Icons.fitness_center, color: Colors.green),
                            onPressed: () => _showDurationDialog(todayStr) // Ativa o alerta se já existir
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
                onPressed: _showPastTrainingDialog,
                icon: const Icon(Icons.calendar_month),
                label: const Text("Novo Registro Manual"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45))
            ),
          ),

          const Divider(),
          Expanded(
            child: filteredTrainings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text("Nenhum treino registrado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Text("Registre seus treinos para acompanhar sua frequência", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredTrainings.length,
              itemBuilder: (context, index) {
                final item = filteredTrainings[index];
                int originalIndex = _trainings.indexOf(item);
                bool isTrained = item['trained'];
                String itemDate = item['date'];

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200, width: 1)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isTrained ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isTrained ? Icons.fitness_center : Icons.hotel,
                            color: isTrained ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isTrained ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  isTrained ? "${item['duration']} minutos" : "Dia de descanso",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isTrained ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                                  ),
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
                              onPressed: () {
                                if (isTrained) {
                                  // Como o usuário ativamente clicou em editar, não exibe alerta (forceOverride: true)
                                  _showDurationDialog(itemDate, initialDuration: item['duration'], forceOverride: true);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text("Editar Registro ($itemDate)"),
                                      content: const Text("Este dia está marcado como Descanso. Deseja alterar para Treino?"),
                                      actions: [
                                        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            // Abre janela de tempo já marcando como edição
                                            _showDurationDialog(itemDate, forceOverride: true);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text("Mudar para Treino", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
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