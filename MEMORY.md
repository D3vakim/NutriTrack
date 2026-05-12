# 🧠 Memória do Projeto: NutriTrack

Este arquivo é a documentação técnica central do projeto **NutriTrack**. Ele deve ser consultado antes de qualquer modificação para garantir a integridade da arquitetura, a consistência do design e a precisão das regras de negócio.

---

## 🚀 1. Visão Geral
O **NutriTrack** é um ecossistema completo de monitoramento de saúde pessoal. Ele permite que usuários acompanhem seu IMC, evolução de peso, planos alimentares e rotinas de treino de forma privada e eficiente, com suporte a uso offline e sincronização na nuvem.

## 🛠 2. Stack Tecnológica
- **Framework:** Flutter (Material 3).
- **Backend:** Supabase (Banco de Dados PostgreSQL + JSONB).
- **Persistência Local:** `shared_preferences` + Cache em memória.
- **Gráficos:** `fl_chart`.
- **Identificação:** `uuid` (UUID v4 gerado no primeiro acesso).

---

## 📐 3. Arquitetura de Dados e Sincronização

### 🛡️ Privacidade por `device_id`
O app não exige login. No primeiro acesso, um UUID único é gerado e salvo localmente. Todos os dados na tabela `app_data` do Supabase são vinculados a este `device_id`, garantindo isolamento total entre usuários.

### 🔄 Estratégia Offline-First (`SupabaseService`)
- **Carregamento:** Ao iniciar, o app carrega os dados do `shared_preferences` instantaneamente. Em seguida, busca atualizações no Supabase.
- **Sincronização:** Operações de salvamento atualizam o local e tentam enviar para a nuvem de forma assíncrona (`_safeSync`).
- **Resolução de Conflitos:** Implementada no método `_mergeLists`. Caso existam registros para a mesma data (local vs nuvem), o registro com o **maior `timestamp`** (mais recente) sempre prevalece.

### 📊 Estrutura de Tabelas (Supabase)
1. **`app_data`**: Armazena dados do usuário.
   - `device_id` (PK): UUID do aparelho.
   - `id_key` (PK): Tipo do dado (`imc_history`, `dieta_do_usuario`, `training_history`).
   - `data` (jsonb): Conteúdo dinâmico (Listas ou Mapas).
   - `timestamp` (int): Milissegundos desde a época para controle de versão.
2. **`suggested_diet`**: Tabela global (somente leitura para o app).
   - `id`: 1 (Padrão).
   - `data` (jsonb): Plano alimentar sugerido pelo nutricionista.

---

## 🎨 4. Design e Identidade Visual

### 🎨 Tema Global (`main.dart`)
- **Cor Semente:** `#2E7D32` (Verde Nutri).
- **Componentes:** AppBars centralizadas e sem elevação, Inputs com bordas arredondadas e foco colorido, ElevatedButtons padronizados, Cards brancos com borda `shade200`.
- **Restrição de Texto:** Escala de fonte travada em `1.0` via `MediaQuery` para evitar quebras de layout.

### 🌈 Cores por Categoria de IMC (OMS)
- **Abaixo do peso (< 18.5):** Azul Escuro (`0xFF1565C0`) / Fundo: `0xFFE3F2FD` / Ícone: `trending_down`.
- **Peso Ideal (18.5 - 24.9):** Verde Escuro (`0xFF2E7D32`) / Fundo: `0xFFE8F5E9` / Ícone: `check_circle_outline`.
- **Sobrepeso (25.0 - 29.9):** Amarelo (`0xFFF57F17`) / Fundo: `0xFFFFFDE7` / Ícone: `trending_up`.
- **Obesidade I/II (30.0 - 39.9):** Laranja (`0xFFE65100`) / Fundo: `0xFFFFF3E0` / Ícone: `warning_amber_outlined`.
- **Obesidade III (>= 40.0):** Vermelho (`0xFFB71C1C`) / Fundo: `0xFFFFEBEE` / Ícone: `dangerous_outlined`.

---

## 📂 5. Módulos e Telas

### 🏠 IMC (Home)
- Calculadora temporária: permite calcular sem sujar o histórico.
- Card de resultado dinâmico: muda cor, ícone e texto baseados no diagnóstico.
- Botão "Salvar no meu Histórico": persiste os dados com o timestamp atual.

### 📈 Evolução (HistoryScreen)
- Filtro mensal: dropdown que sincroniza gráfico e lista.
- Gráfico de linha: estilo curvo, com sombreado e pontos, ajustando eixos automaticamente.
- Lista Premium: cards com avatar colorido do IMC e status da OMS.

### 🥗 Dieta (DietScreen)
- Refeições: Café, Almoço, Lanche, Jantar.
- Substituições: Organizas em um `Map` por grupos.
- **Merge Inteligente:** Ao aplicar a dieta sugerida, o app remove apenas os itens sugeridos antigos (via `lastSuggestedDiet`) e mantém os itens personalizados.
- Suporte a textos longos e quebras de linha em todos os itens.

### 🏋️ Treinos (TrainingScreen)
- Log de Treino vs Descanso.
- Gráfico de constância: segue o estilo visual do gráfico de peso (Tempo de Treino em min).
- Registro rápido para o dia atual e filtro mensal sincronizado.

---

## 🧠 6. Regras de Negócio Importantes
- **Padrão OMS:** Limites de IMC rigorosos (18.5 e 25.0).
- **Tratamento de Números:** Substituição automática de `,` por `.` em campos de peso/altura.
- **Animações:** Splash Screen com fade-in sequencial da logo, nome e progresso.
- **Navegação:** `MainScaffold` usa `IndexedStack` para manter o estado entre abas.

---
*Este documento é a "fonte da verdade". Mantenha-o atualizado.*
