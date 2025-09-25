<!-- .github/copilot-instructions.md - orientações para agentes de codificação AI -->

Objetivo curto
--
Este repositório é uma aplicação Flutter (mobile/web/desktop) chamada `vitrine_nova` — um pequeno PDV/gestão de produtos integrado com Firebase (Auth, Firestore, Storage, Cloud Functions). As instruções abaixo ajudam agentes AI a serem produtivos rapidamente neste código-base.

Arquitetura e responsabilidade dos módulos
--
- `lib/main.dart`: inicialização do Firebase e injeção de dependências via `Provider` (AuthRepository, ProductRepository, AuthStateNotifier). Ponto de entrada para entender como serviços são disponibilizados.
- `lib/app.dart`: monta o `MaterialApp.router` usando `AppRouter` e `AuthStateNotifier` para controlar acesso/roles.
- `lib/config/router/app_router.dart`: define todas as rotas (ex.: `/home`, `/login`, `/pdv`, `/add-product`, `/edit-product/:productId`) e a lógica de redirecionamento baseada em `AuthStateNotifier` e papel do utilizador (`role`).
- `lib/core/notifiers/auth_state_notifier.dart`: escuta `AuthRepository.authStateChanges`, carrega perfil do utilizador do Firestore e garante estado consistente (força logout se Auth existir sem perfil no Firestore).
- `lib/data/repositories/*`: encapsula acesso a Firebase (Auth, Firestore, Storage). Exemplos:
  - `auth_repository.dart`: login, criação de utilizador, leitura de perfil `/users/{uid}`.
  - `product_repository.dart`: streams de produtos/variantes/skus, upload de imagens, operações batch/transaction para vendas.
- `lib/data/models/*`: modelos de domínio (UserModel, ProductModel, SkuModel, VariantModel, SaleModel).
- `lib/presentation/`: UI e controllers (p.ex. `presentation/admin/product_form_controller.dart`) — procure aqui para alterar comportamentos de UI/estado.

Padrões e convenções do projeto (específicos)
--
- Provider/ChangeNotifier é o mecanismo de injeção e state management (veja `main.dart` e `ProductFormController` uso em `app_router.dart`).
- Repositórios retornam Streams para atualizações em tempo real do Firestore (`getProductsStream`, `getVariantsStream`). Preferir consumir Streams usando `StreamBuilder`/`context.watch` patterns já existentes.
- Os modelos usam fábricas `fromFirestore` e validam campos críticos (ex.: `UserModel.fromFirestore` lança se `role` ausente). Tenha cuidado ao retornar dados do Firestore — preserve validações.
- Operações que modificam coleções relacionais usam `WriteBatch` ou `runTransaction` (veja `addNewProduct`, `updateProduct`, `processSale`): prefira manter atomicidade e usar os mesmos padrões.
- Logs: o repositório contém muitos `print`/`debugPrint` para ajudar no diagnóstico; preserve ou atualize conforme necessário.

Integrações externas e pontos sensíveis
--
- Firebase: Auth, Firestore, Storage, Cloud Functions. Configuração de plataformas em `firebase_options.dart` (gerado por FlutterFire CLI). Não editar manualmente sem regenerar quando mudar projectId/credenciais.
- Imagens/Storage: `product_repository.uploadImage` faz sign-in anónimo se necessário (cuidado com permissões). Em web usa `putData`, em mobile `putFile`.
- PDF/printing: `printing` e `pdf` packages usados (veja `pubspec.yaml`).

Build / test / debug (comandos úteis)
--
- Instalar dependências e gerar o `firebase_options.dart` (se necessário):
  - `flutter pub get`
  - Se precisar reconfigurar Firebase: usar FlutterFire CLI (fora do repositório): `flutterfire configure` (não modifique `firebase_options.dart` manualmente).
- Rodar app (Android em Windows):
  - `flutter run -d windows` (desktop)
  - `flutter run -d chrome` (web)
  - `flutter run -d emulator-5554` (Android)
- Testes unitários:
  - `flutter test` (executa `test/` — há testes de exemplo como `pdv_controller_test.dart`).
- Análise/linters:
  - `dart analyze`
  - `flutter analyze`

Coisas a revisar antes de mudar código crítico
--
- Consistência de roles: `UserModel.fromFirestore` exige `role` — alterar schema/seeders requer atualização simultânea do model e das regras de redirecionamento em `AppRouter.redirect`.
- Operações em lote/transaction: quando alterar `processSale`/`updateProduct`, mantenha atomicidade e cuidado com leituras paginadas de subcoleções.
- Segurança: não modifique regras do Firebase sem coordenar com backend; código assume coleções `products`, `users`, `sales` com campos específicos.

Exemplos rápidos (código real do repositório)
--
- Redirect admin check (em `app_router.dart`):
  - rota admin = startsWith('/add-product') || startsWith('/edit-product') || startsWith('/user-management')
  - role é lido via `authNotifier.user?.role`
- Carregar produto complexo (em `product_repository.getProduct`): lê `variants` e para cada variante lê `skus`.

Onde procurar bugs comuns
--
- Falha na inicialização do Firebase: verifique `firebase_options.dart` e chamadas em `main.dart`.
- Autenticação inconsistente: se um utilizador existe no Auth mas não em `/users/{uid}` o `AuthStateNotifier` fará logout — investigar `auth_repository.getUserData` se ocorrer frequentemente.
- Erros de tipos no Firestore: `UserModel.fromFirestore` lança se `role` ausente; trate documentos antigos ou incompletos.

Se for necessário estender instruções
--
- Peça detalhes sobre ambiente Firebase (projectId, emuladores). Se houver uso de emuladores, documentar `firebase emulators:start` e variáveis de ambiente.

Notas finais
--
Mantenha as instruções concisas e referenciando estes ficheiros: `lib/main.dart`, `lib/app.dart`, `lib/config/router/app_router.dart`, `lib/core/notifiers/auth_state_notifier.dart`, `lib/data/repositories/*` e `firebase_options.dart`.

Por favor, reveja este ficheiro e diga se quer que eu inclua comandos específicos do CI, ou detalhes sobre o ambiente Firebase (p.ex. usar emuladores) — posso atualizar rapidamente.
