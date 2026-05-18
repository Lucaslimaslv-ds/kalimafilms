import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/supabase_config.dart';
import 'models/video.dart';
import 'screens/splash.dart';
import 'screens/login.dart';
import 'screens/cadastro.dart';
import 'screens/main_layout.dart';
import 'screens/detalhes.dart';

// Configuração do roteador GoRouter nomeada exatamente como 'routes' na raiz do lib
final GoRouter routes = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = SupabaseConfig.currentUser != null;
    final isGoingToSplash = state.matchedLocation == '/splash';
    final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/cadastro';

    // Se estiver na splash screen, deixa prosseguir (ela cuidará do redirecionamento após a animação)
    if (isGoingToSplash) return null;

    // Se não estiver logado e não estiver indo para a tela de autenticação, força login
    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }

    // Se estiver logado e tentar acessar login/registro, redireciona para a Home
    if (isLoggedIn && isGoingToAuth) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cadastro',
      name: 'cadastro',
      builder: (context, state) => const CadastroScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainLayout(),
    ),
    GoRoute(
      path: '/detalhes/:id',
      name: 'detalhes',
      builder: (context, state) {
        final videoId = state.pathParameters['id'] ?? '';
        final videoExtra = state.extra as Video?;
        return DetailsScreen(
          videoId: videoId,
          video: videoExtra,
        );
      },
    ),
  ],
);
