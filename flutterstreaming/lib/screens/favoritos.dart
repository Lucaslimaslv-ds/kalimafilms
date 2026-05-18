import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';
import '../models/video.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Video> _favoriteVideos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await SupabaseConfig.fetchFavorites();
      setState(() {
        _favoriteVideos = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Remoção rápida com atualização imediata de UI (sem refetch longo)
  Future<void> _removeFavoriteItem(Video video) async {
    final originalList = List<Video>.from(_favoriteVideos);
    
    // Atualização otimista da UI
    setState(() {
      _favoriteVideos.removeWhere((v) => v.id == video.id);
    });

    try {
      await SupabaseConfig.removeFavorite(video.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${video.titulo}" removido dos favoritos.'),
            action: SnackBarAction(
              label: 'Desfazer',
              textColor: KalimaTheme.primary,
              onPressed: () async {
                // Readicionar caso queira desfazer
                setState(() {
                  _favoriteVideos = originalList;
                });
                await SupabaseConfig.addFavorite(video.id);
              },
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: KalimaTheme.surfaceLight,
          ),
        );
      }
    } catch (e) {
      // Reverte se der erro no banco
      setState(() {
        _favoriteVideos = originalList;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao remover item: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KalimaTheme.background,
      appBar: AppBar(
        title: const Text('MEUS FAVORITOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KalimaTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_favoriteVideos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: KalimaTheme.primary,
      backgroundColor: KalimaTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _favoriteVideos.length + 1, // +1 para espaço final de scroll
        itemBuilder: (context, index) {
          if (index == _favoriteVideos.length) {
            return const SizedBox(height: 100); // Evita cobrir o bottom bar flutuante
          }

          final video = _favoriteVideos[index];
          return _buildFavoriteCard(video);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Video video) {
    return Dismissible(
      key: Key('fav-${video.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.redAccent.withOpacity(0.9),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _removeFavoriteItem(video);
      },
      child: GestureDetector(
        onTap: () {
          context.push('/detalhes/${video.id}', extra: video); // Rota de detalhes em português
        },
        child: Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: KalimaTheme.surface,
            border: Border.all(color: KalimaTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Capa de vídeo
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 110,
                  height: double.infinity,
                  child: Image.network(
                    video.capaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: KalimaTheme.surfaceLight,
                      child: const Icon(Icons.broken_image, color: KalimaTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              
              // Título, Duração, Classificação
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        video.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: KalimaTheme.gold, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            video.classificacao.toString(),
                            style: const TextStyle(
                              color: KalimaTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            video.duracao,
                            style: const TextStyle(
                              color: KalimaTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Botão Remover Rápido
              IconButton(
                icon: const Icon(Icons.favorite, color: KalimaTheme.gold, size: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: () {
                  _removeFavoriteItem(video);
                },
              ),
            ],
          ),
        ),
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
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KalimaTheme.primary.withOpacity(0.08),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: KalimaTheme.primary,
                size: 45,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sua lista está vazia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore o catálogo e adicione suas aulas e mídias favoritas aqui para acesso rápido.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KalimaTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
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
              'Erro de conexão',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Não foi possível buscar seus favoritos.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: KalimaTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadFavorites,
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
