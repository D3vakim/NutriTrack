# Memória do Projeto: Calculadora IMC

Este arquivo serve como uma base de conhecimento sobre a estrutura, funcionalidades e tecnologias do projeto `calculadora_imc`.

## 🚀 Visão Geral
O projeto é um aplicativo Flutter para monitoramento de saúde, focado no cálculo de IMC (Índice de Massa Corporal), acompanhamento de evolução física, gestão de dieta e registros de treino.

## 🛠 Tecnologias e Dependências
- **Linguagem/Framework:** Dart & Flutter.
- **Backend:** Supabase (Banco de dados online para persistência de dados).
- **Gráficos:** `fl_chart` para visualização de evolução de peso e treinos.
- **Armazenamento Local:** `shared_preferences` (listado no pubspec, mas o foco principal é Supabase).

## 📂 Estrutura de Arquivos (`lib/`)
- `main.dart`: Ponto de entrada, inicialização do Supabase e definição da `SplashScreen` como home.
- **`screens/`**:
    - `splash_screen.dart`: Tela de abertura com animação de escala no logo.
    - `home_screen.dart`: Calculadora de IMC com validações de peso/altura e integração de salvamento no Supabase.
    - `history_screen.dart`: Gráfico de evolução de peso e lista histórica dos cálculos realizados.
    - `diet_screen.dart`: Gestão de refeições e grupos de substituição, com opção de aplicar uma dieta sugerida.
    - `training_screen.dart`: Registro de dias de treino ou descanso, duração das sessões e gráfico mensal.
- **`widgets/`**:
    - `custom_drawer.dart`: Menu lateral para navegação entre todas as telas.
- **`utils/`**:
    - `calculadora_logic.dart`: Funções puras para cálculo do IMC e classificação do status (Abaixo do peso, Ideal, etc).

## 📊 Fluxo de Dados (Supabase)
Os dados são armazenados na tabela `app_data` usando chaves identificadoras (`id_key`):
- `imc_history`: Histórico de medidas (data, peso, altura, imc).
- `dieta_do_usuario`: Estrutura de refeições (café, almoço, lanche, jantar, substituições).
- `training_history`: Log de atividades físicas (data, se treinou, duração).

## 🧠 Regras de Negócio Importantes
1. **Validação de IMC**: O app alerta se a altura parece estar em metros em vez de centímetros ou se o peso é excepcionalmente alto.
2. **Histórico Diário**: Ao salvar um IMC ou Treino, o sistema verifica se já existe um registro para a data atual e oferece a opção de substituir.
3. **Conversão**: O cálculo de IMC na `home_screen.dart` converte cm para metros antes de processar.

---
*Este arquivo deve ser consultado e atualizado sempre que houver mudanças estruturais significativas no projeto.*
