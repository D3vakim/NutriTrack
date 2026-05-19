import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
//comentário, Caminho correto do serviço, separação de lógica está boa, é bom manter essa organização, ajuda muito na manutenção

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    //cometário, Ponto de atenção: instanciar o serviço assim cria uma nova instância toda vez.
Melhoria: use injeção de dependência ou provedor para compartilhar a mesma instância em todo o app — evita consumo desnecessário de recursos.
  
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
            //cometário, Problema: cor está fixa como 'verde padrão', diferente da cor principal do app (0xFF2E7D32) definida no tema.
Correção: usar Theme.of(context).primaryColor — deixa tudo padronizado e fácil de mudar depois.
            
            accountName: const Text(
              'NutriTrack',
              // cometário,  Nome do app definido
Melhoria: tirar o 'const' se for usar tema, ou mover o texto para constantes para reaproveitar
              
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            accountEmail: lastImcData != null 
                ? Text('Último IMC: ${lastImcData['imc'].toStringAsFixed(2)} (${lastImcData['date']})')
                : const Text('Nenhum registro ainda'),
            // cometário, Boa lógica de exibição condicional
 Possível erro: os dados 'imc' e 'date' podem não existir ou ser nulos — pode causar erro em tela.
Sugestão: adicionar verificação se os campos existem antes de usar.
 Melhoria: formatar a data para um formato mais amigável ao usuário.
            
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/logo.png'),
                // cometário, Caminho da imagem correto
 Lembrete: verificar se a imagem está declarada corretamente no pubspec.yaml, senão dá erro ao carregar
                
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
          // cometário Mesmo problema da cor: está fixa, não usa a cor do tema.
Correção: usar Theme.of(context).primaryColor
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Versão 1.0.0',
              // cometário, Versão informada
 Melhoria: não deixar versão fixa no código — ler automaticamente do arquivo de configuração do app, assim não precisa mudar em vários lugares.
              
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
// cometário, ### Resumo geral

 Pontos positivos:
- Código limpo e objetivo
- Separação da lógica no arquivo de serviço
- Trata o caso de não ter dados cadastrados

Pontos para corrigir:
- [ ] Usar cor do tema em vez de `Colors.green` fixo
- [ ] Verificar se os campos `imc` e `date` existem antes de exibir
- [ ] Não criar nova instância do serviço toda vez

 Melhorias recomendadas:
- Usar gerenciamento de estado para atualizar dado automaticamente
- Formatar data para melhor visualização
- Ler versão do app automaticamente
  
