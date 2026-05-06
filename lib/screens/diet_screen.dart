import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _supabaseService = SupabaseService();

  List<String> _breakfast = [];
  List<String> _lunch = [];
  List<String> _supper = [];
  List<String> _dinner = [];
  Map<String, List<String>> _substitutions = {};

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  void _loadLocalData() {
    final data = _supabaseService.dietData;
    setState(() {
      _breakfast = List<String>.from(data['breakfast'] ?? []);
      _lunch = List<String>.from(data['lunch'] ?? []);
      _supper = List<String>.from(data['supper'] ?? []);
      _dinner = List<String>.from(data['dinner'] ?? []);

      // Carrega o Map de substituições com segurança
      final subData = data['substitutions'];
      if (subData is Map) {
        _substitutions = subData.map((key, value) => MapEntry(key.toString(), List<String>.from(value ?? [])));
      } else {
        _substitutions = {};
      }
    });
  }

  Future<void> _saveDietData() async {
    Map<String, dynamic> dietData = {
      'breakfast': _breakfast,
      'lunch': _lunch,
      'supper': _supper,
      'dinner': _dinner,
      'substitutions': _substitutions,
    };
    await _supabaseService.saveDiet(dietData);
  }

  void _applySuggestedDiet() {
    final outerContext = context; // ✅ salva o context do widget antes do dialog

    showDialog(
      context: outerContext,
      builder: (dialogContext) { // ✅ renomeia para não sobrescrever o outer
        return AlertDialog(
          title: const Text("Aplicar Dieta Sugerida"),
          content: const Text("Tem certeza que deseja substituir toda a sua dieta atual pela dieta sugerida?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // ✅ fecha só o dialog de confirmação

                // Mostra loading usando o outerContext
                showDialog(
                  context: outerContext,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final data = await _supabaseService.fetchSuggestedDiet();

                // Fecha o loading
                if (mounted) Navigator.of(outerContext).pop();

                if (data == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao buscar dieta sugerida. Tente novamente.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                setState(() {
                  _breakfast = List<String>.from(data['breakfast'] ?? []);
                  _lunch    = List<String>.from(data['lunch'] ?? []);
                  _supper   = List<String>.from(data['supper'] ?? []);
                  _dinner   = List<String>.from(data['dinner'] ?? []);

                  final subData = data['substitutions'];
                  if (subData is Map) {
                    _substitutions = subData.map(
                          (key, value) => MapEntry(key.toString(), List<String>.from(value ?? [])),
                    );
                  } else {
                    _substitutions = {};
                  }
                });

                await _saveDietData();

                if (mounted) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Dieta aplicada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }
  void _showItemDialog(String title, dynamic list, {int? index, String? groupKey}) {
    TextEditingController controller = TextEditingController();
    if (list is List<String>) {
      controller.text = index != null ? list[index] : '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index != null ? 'Editar $title' : 'Adicionar ao $title'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null, // Permite múltiplas linhas na edição
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(hintText: "Digite o alimento e detalhes..."),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    if (groupKey != null) {
                      // Lógica para Map (Substituições)
                      if (index != null) {
                        _substitutions[groupKey]![index] = controller.text.trim();
                      } else {
                        if (!_substitutions.containsKey(groupKey)) {
                          _substitutions[groupKey] = [];
                        }
                        _substitutions[groupKey]!.add(controller.text.trim());
                      }
                    } else if (list is List<String>) {
                      // Lógica para Listas (Refeições)
                      if (index != null) {
                        list[index] = controller.text.trim();
                      } else {
                        list.add(controller.text.trim());
                      }
                    }
                  });
                  _saveDietData();
                  Navigator.pop(context);
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(dynamic list, int index, {String? groupKey}) {
    setState(() {
      if (groupKey != null) {
        _substitutions[groupKey]!.removeAt(index);
      } else if (list is List<String>) {
        list.removeAt(index);
      }
    });
    _saveDietData();
  }

  Widget _buildDietSection(String title, List<String> list, IconData icon, Color bgColor, Color iconColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          subtitle: Text(
            "${list.length} ${list.length == 1 ? 'item' : 'itens'}",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.primary,
          children: [
            ...list.asMap().entries.map((entry) {
              int index = entry.key;
              String itemText = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            itemText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showItemDialog(title, list, index: index),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteItem(list, index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (index != list.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
            InkWell(
              onTap: () => _showItemDialog(title, list),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Adicionar item",
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutionsSection() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF8E24AA), size: 20),
          ),
          title: Text(
            "Grupos de Substituição",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          subtitle: Text(
            "${_substitutions.length} grupos",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          iconColor: const Color(0xFF8E24AA),
          collapsedIconColor: const Color(0xFF8E24AA),
          children: _substitutions.entries.map((entry) {
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text("${entry.value.length} itens", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              children: entry.value.asMap().entries.map((itemEntry) {
                int itemIndex = itemEntry.key;
                String itemText = itemEntry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E24AA),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(itemText, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showItemDialog(entry.key, entry.value, index: itemIndex, groupKey: entry.key),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                iconSize: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteItem(entry.value, itemIndex, groupKey: entry.key),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (itemIndex != entry.value.length - 1)
                      const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFF5F5F5)),
                  ],
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Minha Dieta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDietSection("Café da Manhã", _breakfast, Icons.wb_sunny_outlined, const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
            _buildDietSection("Almoço", _lunch, Icons.lunch_dining_outlined, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
            _buildDietSection("Lanche", _supper, Icons.emoji_food_beverage_outlined, const Color(0xFFFFEBEE), const Color(0xFFE53935)),
            _buildDietSection("Jantar", _dinner, Icons.dinner_dining_outlined, const Color(0xFFE8EAF6), const Color(0xFF3949AB)),
            _buildSubstitutionsSection(),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: const Color(0xFFFFF8E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFFFF176), width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFF57F17), size: 28),
                title: const Text("Aplicar dieta sugerida", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text("Substitui sua dieta atual pelo plano do nutricionista", style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _applySuggestedDiet,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
