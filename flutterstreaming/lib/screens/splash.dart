import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _textFade;
  late Animation<double> _textTranslate;

  @override
  void initState() {
    super.initState();

    // Controlador da logo (escala e rotação sutil)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Controlador do texto (fade in e deslocamento para cima)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _textTranslate = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Inicia a sequência de animação
    _logoController.forward().then((_) {
      _textController.forward();
    });

    // Navega após 3.5 segundos para a próxima tela adequada
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        final isLoggedIn = SupabaseConfig.currentUser != null;
        if (isLoggedIn) {
          context.go('/');
        } else {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KalimaTheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Luzes de fundo atmosféricas (Glows translúcidos)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KalimaTheme.primary.withOpacity(0.15),
                    blurRadius: 120,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KalimaTheme.accent.withOpacity(0.12),
                    blurRadius: 150,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Logotipo e Identidade visual no centro
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO ANIMADA COM SHUTTER DE FILME GLOW
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: KalimaTheme.primaryGradient,
                      boxShadow: KalimaTheme.neonGlow(blur: 25),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: KalimaTheme.background,
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Shutter / Detalhe de Rolo de Filme
                            ...List.generate(6, (index) {
                              final double angle = index * (3.14159 / 3);
                              return Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: 100,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: KalimaTheme.border.withOpacity(0.4),
                                  ),
                                ),
                              );
                            }),
                            // Círculo central com a Letra "K" de KalimaFilms
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: KalimaTheme.primaryGradient,
                              ),
                              child: const Center(
                                child: Text(
                                  'K',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      )
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                
                // TEXTO E SLOGAN ANIMADOS
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0.0, _textTranslate.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Nome da marca com gradiente
                      ShaderMask(
                        shaderCallback: (bounds) => KalimaTheme.primaryGradient.createShader(bounds),
                        child: const Text(
                          'KALIMA FILMS',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Slogan acadêmico
                      Text(
                        'Conhecimento em Alta Definição',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: KalimaTheme.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Indicador de Carregamento sutil na parte inferior
          Positioned(
            bottom: 60,
            child: SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: KalimaTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(KalimaTheme.primary),
                  minHeight: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
