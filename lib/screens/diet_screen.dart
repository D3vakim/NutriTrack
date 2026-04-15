import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_drawer.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  List<String> _breakfast = [];
  List<String> _lunch = [];
  List<String> _supper = [];
  List<String> _dinner = [];
  List<String> _substitutions = [];

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  // --- MUDANÇA AQUI: Nova forma de salvar os dados ---
  Future<void> _saveDietData() async {
    Map<String, dynamic> data = {
      'breakfast': _breakfast,
      'lunch': _lunch,
      'supper': _supper,
      'dinner': _dinner,
      'substitutions': _substitutions,
    };

    String jsonString = json.encode(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diet_data', jsonString);
  }

  // --- MUDANÇA AQUI: Nova forma de carregar os dados ---
  Future<void> _loadDietData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('diet_data');

      if (jsonString != null) {
        Map<String, dynamic> data = json.decode(jsonString);

        setState(() {
          _breakfast = List<String>.from(data['breakfast'] ?? []);
          _lunch = List<String>.from(data['lunch'] ?? []);
          _supper = List<String>.from(data['supper'] ?? []);
          _dinner = List<String>.from(data['dinner'] ?? []);
          _substitutions = List<String>.from(data['substitutions'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        _breakfast = [];
        _lunch = [];
        _supper = [];
        _dinner = [];
        _substitutions = [];
      });
    }
  }

  void _applySuggestedDiet() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Aplicar Dieta Sugerida"),
          content: const Text("Tem certeza que deseja substituir toda a sua dieta atual pela dieta sugerida pelo nutricionista? Isso apagará seus registros atuais."),
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
                setState(() {
                  _breakfast = [
                    "Cacau em pó (4g) OU Café (80ml)",
                    "Ovo de galinha cozido (110g) OU Peito de frango desfiado (50g)",
                    "Pera Willians crua (110g) OU Morango (200g) OU Mamão papaia (135g) OU Goiaba (105g)",
                    "Torrada integral (40g) OU Pão de forma integral (50g) OU Farelo de aveia (60g) OU Farinha de linhaça (60g)"
                  ];
                  _lunch = [
                    "Acelga (40g) OU Agrião (35g) OU Alface (40g) OU Alface roxa (40g)",
                    "Abóbora moranga cozida (220g) OU Abobrinha (280g) OU Beterraba (120g) OU Cenoura (150g)",
                    "Filé de frango grelhado (100g) OU Coxa de frango (100g) OU Ovo cozido (220g) OU Filé de tilápia (120g)",
                    "Arroz integral cozido (100g) OU Batata doce (200g) OU Batata baroa (175g) OU Cará (200g)",
                    "Feijão carioca cozido (130g) OU Grão de bico (90g) OU Lentilha (70g)",
                    "Azeite de oliva (8ml)"
                  ];
                  _supper = [
                    "Maçã Fuji (90g) OU Uva passa (18g) OU Maçã argentina (80g) OU Laranja lima (140g)",
                    "Semente de linhaça (30g) OU Castanha-do-Brasil (16g) OU Amendoim (19g) OU Noz crua (20g)",
                    "Queijo minas frescal (40g) OU Ricota (70g) OU Cottage (60g) OU Minas frescal light (40g)"
                  ];
                  _dinner = [
                    "Alface roxa (40g) OU Couve refogada (40g) OU Acelga (40g) OU Alface (40g)",
                    "Brócolis cozido (240g) OU Couve-flor (240g) OU Tomate salada (180g) OU Chuchu (180g)",
                    "Filé de tilápia cozido (90g) OU Cupim assado (75g) OU Peito de frango (75g) OU Ovo (150g)",
                    "Arroz integral cozido (60g) OU Cará (120g) OU Macarrão integral (75g) OU Batata doce (120g)",
                    "Feijão carioca cozido (130g) OU Grão de bico (90g)",
                    "Laranja lima (140g) OU Mamão formosa (170g) OU Pera Park (110g) OU Uva passa (18g)"
                  ];
                  _substitutions = [
                    "Grupo 1 (Baixa Caloria): Cacau em pó, Café, Chás, Água com limão",
                    "Grupo 2 (Vegetais A): Acelga, Agrião, Alface, Espinafre, Rúcula, Repolho, etc.",
                    "Grupo 3 (Vegetais B): Abobrinha, Abóbora, Beterraba, Brócolis, Cenoura, Chuchu, etc.",
                    "Grupo 4 (Carnes/Proteínas): Frango, Ovo, Tilápia, Atum, Patinho, Salmão, Contra filé, etc.",
                    "Grupo 5 (Cereais/Tubérculos): Arroz, Batata doce/inglesa, Macarrão, Quinoa, Cará, Inhame",
                    "Grupo 6 (Leguminosas): Feijão (todos), Grão de bico, Lentilha, Ervilha",
                    "Grupo 7 (Óleos/Gorduras): Azeite, Manteiga, Manteiga Ghee, Óleo de soja",
                    "Grupo 8 (Gordurosos): Azeitona, Bacon, Cream Cheese, Creme de leite, Torresmo",
                    "Grupo 9 (Frutas Comuns): Maçã, Morango, Mamão, Laranja, Pera, Uva, Banana, etc.",
                    "Grupo 10 (Frutas Oleosas): Abacate, Avocado, Coco, Açaí",
                    "Grupo 11 (Nozes/Sementes): Linhaça, Castanhas, Amendoim, Chia, Semente de abóbora",
                    "Grupo 12 (Pães/Fibras): Torrada, Aveia, Pão de forma, Biscoito de polvilho, Tapioca",
                    "Grupo 13 (Laticínios): Queijo minas, Ricota, Cottage, Iogurte natural, Leite, Coalhada",
                    "Grupo 14 (Suplementos): Whey Protein, Caseína, Proteína de soja",
                    "Grupo 15 (Açúcares): Açúcar mascavo/demerara, Melado, Xylitol, Maltodextrina"
                  ];
                });
                _saveDietData();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sua dieta personalizada foi aplicada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Substituir", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showItemDialog(String title, List<String> list, String listKey, {int? index}) {
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
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: "Digite o alimento e a quantidade",
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
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

  void _confirmDelete(List<String> list, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text("Tem certeza que deseja deletar este item da sua dieta?"),
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
                _deleteItem(list, index);
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

  Widget _buildDietSection(String title, List<String> list, String listKey) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(list[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showItemDialog(title, list, listKey, index: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(list, index),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showItemDialog(title, list, listKey),
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Item"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minha Dieta"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      drawer: CustomDrawer(),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildDietSection("Café da Manhã (08:00)", _breakfast, 'breakfast'),
            _buildDietSection("Almoço (12:00)", _lunch, 'lunch'),
            _buildDietSection("Lanche (16:30)", _supper, 'supper'),
            _buildDietSection("Jantar (20:00)", _dinner, 'dinner'),
            _buildDietSection("Grupos de Substituição", _substitutions, 'substitutions'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _applySuggestedDiet,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text("Aplicar Dieta Sugerida"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}