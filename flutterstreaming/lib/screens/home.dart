import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';
import '../models/video.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Video> _videos = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Vídeo em destaque (Spotlight) no cabeçalho
  Video? _spotlightVideo;

  // Dicionário de Categorias Mapeadas
  final Map<String, List<Video>> _categories = {
    'Aulas & Tutoriais': [],
    'Curtas Acadêmicos': [],
    'Documentários': [],
    'Cinema e Crítica': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchCatalogData();
  }

  Future<void> _fetchCatalogData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catalog = await SupabaseConfig.fetchVideos();
      
      if (catalog.isNotEmpty) {
        // Spotlight é o primeiro vídeo cadastrado
        _spotlightVideo = catalog.first;
        
        // Limpa e distribui os itens por categoria
        _categories.forEach((key, value) => value.clear());

        for (var video in catalog) {
          final catLower = video.categoria.toLowerCase();
          if (catLower.contains('aula') || catLower.contains('tutorial') || catLower.contains('tecnologia')) {
            _categories['Aulas & Tutoriais']!.add(video);
          } else if (catLower.contains('curta') || catLower.contains('estudante') || catLower.contains('ficção')) {
            _categories['Curtas Acadêmicos']!.add(video);
          } else if (catLower.contains('doc') || catLower.contains('realidade') || catLower.contains('cultura')) {
            _categories['Documentários']!.add(video);
          } else {
            _categories['Cinema e Crítica']!.add(video);
          }
        }
      }

      setState(() {
        _videos = catalog;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KalimaTheme.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_videos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchCatalogData,
      color: KalimaTheme.primary,
      backgroundColor: KalimaTheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER SPOTLIGHT BANNER
            if (_spotlightVideo != null) _buildSpotlightBanner(_spotlightVideo!),

            const SizedBox(height: 25),

            // 2. PRATELEIRAS DE CATEGORIAS
            ..._categories.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
              return _buildCategoryShelf(entry.key, entry.value);
            }),

            const SizedBox(height: 120), // Altura extra de segurança para a barra flutuante
          ],
        ),
      ),
    );
  }

  // Spotlight Banner Premium no topo da página
  Widget _buildSpotlightBanner(Video video) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Capa do Spotlight em tela grande
        Container(
          height: size.height * 0.58,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(video.capaUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black45,
                  Colors.transparent,
                  Colors.black87,
                  KalimaTheme.background,
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Badges e título centralizado embaixo do gradiente
        Positioned(
          bottom: 15,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Categoria do Spotlight
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KalimaTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KalimaTheme.accent.withOpacity(0.3)),
                ),
                child: Text(
                  video.categoria.toUpperCase(),
                  style: const TextStyle(
                    color: KalimaTheme.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Título
              Text(
                video.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),

              // Botões (Assistir e Ver Detalhes)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Assistir Direto
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: KalimaTheme.primaryGradient,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/detalhes/${video.id}', extra: video);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      label: const Text(
                        'ASSISTIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Mais Informações
                  GestureDetector(
                    onTap: () {
                      context.push('/detalhes/${video.id}', extra: video);
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'INFO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Constrói prateleira (shelf) horizontal para categorias de mídia
  Widget _buildCategoryShelf(String title, List<Video> categoryVideos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: KalimaTheme.primaryGradient,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${categoryVideos.length} mídias',
                style: TextStyle(
                  color: KalimaTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categoryVideos.length,
            itemBuilder: (context, index) {
              final video = categoryVideos[index];
              return _buildVideoCard(video);
            },
          ),
        ),
      ],
    );
  }

  // Card do vídeo horizontal
  Widget _buildVideoCard(Video video) {
    return GestureDetector(
      onTap: () {
        context.push('/detalhes/${video.id}', extra: video); // Rota de detalhes em português
      },
      child: Container(
        width: 135,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: KalimaTheme.surface,
          border: Border.all(color: KalimaTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem da capa com overlay gradiente sutil
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        video.capaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: KalimaTheme.surface,
                          child: const Icon(Icons.broken_image, color: KalimaTheme.textSecondary),
                        ),
                      ),
                    ),
                    // Sombra inferior do card
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Badge de Duração
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.duracao,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Rodapé do Card
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: KalimaTheme.gold, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          video.classificacao.toString(),
                          style: const TextStyle(
                            color: KalimaTheme.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Mock Loading para carregamentos cinematográficos
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Shimmer
          Container(
            height: 350,
            width: double.infinity,
            color: KalimaTheme.surface,
            child: const Center(
              child: CircularProgressIndicator(color: KalimaTheme.primary),
            ),
          ),
          const SizedBox(height: 30),
          // Trilhas Shimmer
          ...List.generate(2, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(width: 150, height: 16, color: KalimaTheme.surface),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: 4,
                    itemBuilder: (context, idx) => Container(
                      width: 125,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: KalimaTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_creation_outlined, color: KalimaTheme.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Catálogo indisponível',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Nenhum filme ou aula foi cadastrado no momento. Tente recarregar a lista.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KalimaTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCatalogData,
              style: ElevatedButton.styleFrom(
                backgroundColor: KalimaTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Recarregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Ocorreu um problema ao recuperar o catálogo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: KalimaTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCatalogData,
              style: ElevatedButton.styleFrom(
                backgroundColor: KalimaTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Recarregar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
