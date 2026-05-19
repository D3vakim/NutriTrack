import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
//comentário, Caminho correto do serviço, separação de lógica está boa, é bom manter essa organização, ajuda muito na manutenção

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    final lastImcData = supabaseService.imcHistory.isNotEmpty 
        ? supabaseService.imcHistory.first 
        : null;
    //cometário Lógica correta para pegar o último registro
 Melhoria: se a lista for atualizada fora dessa tela, esse valor não muda automaticamente.
Sugestão: usar um Estado reativo (Provider, Riverpod, etc.) para que o dado atualize sozinho quando novo registro for salvo.
  

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            accountName: const Text(
              'NutriTrack',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            accountEmail: lastImcData != null 
                ? Text('Último IMC: ${lastImcData['imc'].toStringAsFixed(2)} (${lastImcData['date']})')
                : const Text('Nenhum registro ainda'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/logo.png'),
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.green),
            title: Text('Sobre o App'),
          ),
          const ListTile(
            leading: Icon(Icons.settings, color: Colors.green),
            title: Text('Configurações'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
