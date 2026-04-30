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
  List<String> _substitutions = [];

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
      _substitutions = List<String>.from(data['substitutions'] ?? []);
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Aplicar Dieta Sugerida"),
          content: const Text("Tem certeza que deseja substituir toda a sua dieta atual pela dieta sugerida?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _breakfast = [
                    "Cacau em pó (4g) OU Café (80ml)",
                    "Ovo cozido (110g) OU Frango desfiado (50g)",
                    "Pera (110g) OU Morango (200g) OU Mamão (135g)",
                    "Torrada integral (40g) OU Pão de forma integral (50g)"
                  ];
                  _lunch = [
                    "Vegetais folhosos à vontade (Alface, Acelga)",
                    "Legumes cozidos (150g) (Cenoura, Chuchu)",
                    "Filé de frango (100g) OU Tilápia (120g)",
                    "Arroz integral (100g) OU Batata doce (200g)",
                    "Feijão carioca (130g)",
                    "Azeite de oliva (8ml)"
                  ];
                  _supper = [
                    "Maçã (90g) OU Laranja (140g)",
                    "Castanha-do-Brasil (16g) OU Amendoim (19g)",
                    "Queijo minas frescal (40g) OU Ricota (70g)"
                  ];
                  _dinner = [
                    "Salada de folhas à vontade",
                    "Brócolis ou Couve-flor (240g)",
                    "Filé de tilápia (90g) OU Ovo (150g)",
                    "Arroz integral (60g) OU Batata doce (120g)",
                    "Laranja (140g) OU Mamão (170g)"
                  ];
                  _substitutions = [
                    "G1 (Baixa Caloria): Chás, Café, Água com limão",
                    "G2 (Vegetais A): Acelga, Agrião, Alface, Espinafre",
                    "G3 (Vegetais B): Abobrinha, Abóbora, Beterraba",
                    "G4 (Proteínas): Frango, Ovo, Tilápia, Patinho",
                    "G5 (Cereais): Arroz, Batata, Macarrão, Quinoa"
                  ];
                });
                _saveDietData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dieta aplicada com sucesso!'), backgroundColor: Colors.green),
                );
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  void _showItemDialog(String title, List<String> list, {int? index}) {
    TextEditingController controller = TextEditingController(
      text: index != null ? list[index] : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index != null ? 'Editar $title' : 'Adicionar ao $title'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: "Ex: 1 maçã média"),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    if (index != null) {
                      list[index] = controller.text.trim();
                    } else {
                      list.add(controller.text.trim());
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

  void _deleteItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
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
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      itemText,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
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
            _buildDietSection("Grupos de Substituição", _substitutions, Icons.swap_horiz_rounded, const Color(0xFFF3E5F5), const Color(0xFF8E24AA)),
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
