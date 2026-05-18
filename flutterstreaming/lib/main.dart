import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'routes.dart';

void main() async {
  // Garante a inicialização das integrações nativas
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carrega as variáveis de ambiente do arquivo .env com segurança
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: arquivo .env não encontrado ou com formato inválido.");
  }

  // Inicializa a conexão com o Supabase (ou ativa o modo demonstrativo local se as chaves forem padrão)
  await SupabaseConfig.init();

  runApp(const KalimaApp());
}

class KalimaApp extends StatelessWidget {
  const KalimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kalima Films',
      debugShowCheckedModeBanner: false,
      
      // Aplica o tema escuro premium personalizado (Obsidiana / Néon / Metalizado)
      theme: KalimaTheme.darkTheme,
      
      // Vincula a árvore de renderização ao GoRouter (controle de autenticação automática)
      routerConfig: routes,
    );
  }
}
