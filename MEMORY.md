# Memória do Projeto: Calculadora IMC (Atualizado)

## 🚀 Visão Geral
Aplicativo Flutter para monitoramento de saúde (IMC, Dieta, Treinos) com persistência online.

## 🛡️ Privacidade e Isolamento de Dados
O app utiliza um sistema de **ID Único de Dispositivo (UUID)** para garantir que cada usuário tenha seus dados privados sem necessidade de login/senha:
- Na primeira execução, um UUID é gerado e salvo no `SharedPreferences`.
- Todas as consultas ao Supabase filtram pela coluna `device_id`.
- Isso garante que os dados sejam pessoais de cada aparelho.

## 🛠 Tecnologias
- **Framework:** Flutter.
- **Backend:** Supabase (Tabela `app_data`).
- **Identificação:** `uuid` + `shared_preferences`.
- **Gráficos:** `fl_chart`.

## 📂 Arquitetura de Dados (`lib/services/supabase_service.dart`)
Centraliza a comunicação com o banco e mantém um cache em memória para evitar loadings lentos:
- `loadAllData()`: Chamado na Splash Screen, puxa IMC, Dieta e Treinos de uma vez.
- `saveIMC()`, `saveDiet()`, `saveTraining()`: Métodos que realizam o `upsert` enviando `device_id` + `id_key`.

## 📊 Estrutura da Tabela `app_data`
- `device_id` (PK): ID único do celular.
- `id_key` (PK): Tipo do dado (ex: `imc_history`).
- `data` (JSONB): Conteúdo dinâmico (Listas ou Mapas).
- `updated_at`: Timestamp de atualização.
