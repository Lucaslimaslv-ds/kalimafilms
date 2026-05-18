import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';
import '../models/video.dart';

class DetailsScreen extends StatefulWidget {
  final String videoId;
  final Video? video;

  const DetailsScreen({
    super.key,
    required this.videoId,
    this.video,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Video? _video;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  List<Video> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadVideoDetails();
  }

  Future<void> _loadVideoDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Busca dados do vídeo atual
      Video? currentVideo = widget.video;
      if (currentVideo == null) {
        final videos = await SupabaseConfig.fetchVideos();
        currentVideo = videos.firstWhere(
          (v) => v.id == widget.videoId,
          orElse: () => throw Exception('Vídeo não encontrado no catálogo'),
        );
      }
      _video = currentVideo;

      // 2. Busca lista de favoritos para checar se este vídeo está favoritado
      final favorites = await SupabaseConfig.fetchFavorites();
      _isFavorite = favorites.any((v) => v.id == currentVideo!.id);

      // 3. Carrega recomendações (outros vídeos da mesma categoria)
      final allVideos = await SupabaseConfig.fetchVideos();
      _recommendations = allVideos
          .where((v) => v.categoria == currentVideo!.categoria && v.id != currentVideo.id)
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  // Toggle Favoritos Otimista
  Future<void> _toggleFavorite() async {
    if (_video == null || _isActionLoading) return;

    final wasFavorite = _isFavorite;
    setState(() {
      _isFavorite = !wasFavorite;
      _isActionLoading = true;
    });

    try {
      if (wasFavorite) {
        await SupabaseConfig.removeFavorite(_video!.id);
      } else {
        await SupabaseConfig.addFavorite(_video!.id);
      }
      setState(() {
        _isActionLoading = false;
      });
    } catch (e) {
      // Reverte se falhar
      setState(() {
        _isFavorite = wasFavorite;
        _isActionLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar favorito: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Inicializa a reprodução do vídeo e adiciona ao histórico
  Future<void> _watchVideo() async {
    if (_video == null) return;

    try {
      // Adiciona ao histórico do Supabase / Local
      await SupabaseConfig.addToHistory(_video!.id);
      
      if (mounted) {
        // Exibe o Player Premium de Simulação
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimulatedVideoPlayer(video: _video!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao iniciar reprodução: $e'),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KalimaTheme.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ops, ocorreu um erro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KalimaTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadVideoDetails,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Tentar Novamente', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KalimaTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final video = _video!;
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER COM IMAGEM DE CAPA EM DESTAQUE E VOLTAR
          Stack(
            children: [
              // Banner da capa com sombra gradiente inferior
              Container(
                height: size.height * 0.45,
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
                        Colors.black87,
                        Colors.transparent,
                        Colors.transparent,
                        KalimaTheme.background,
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Botão de Voltar personalizado
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                      border: Border.all(color: KalimaTheme.border),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. METADADOS E INFORMAÇÕES DO VÍDEO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag de Categoria
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KalimaTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KalimaTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    video.categoria.toUpperCase(),
                    style: const TextStyle(
                      color: KalimaTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Título do Vídeo
                Text(
                  video.titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Estrelas + Duração
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: KalimaTheme.gold, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      video.classificacao.toString(),
                      style: const TextStyle(
                        color: KalimaTheme.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      video.duracao,
                      style: TextStyle(
                        color: KalimaTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 3. AÇÕES RÁPIDAS (ASSISTIR + FAVORITO)
                Row(
                  children: [
                    // Botão Principal Assistir
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: KalimaTheme.primaryGradient,
                          boxShadow: KalimaTheme.neonGlow(color: KalimaTheme.primary, blur: 8),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _watchVideo,
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          label: const Text(
                            'ASSISTIR AGORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Botão de Favoritar
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: KalimaTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isFavorite ? KalimaTheme.gold : KalimaTheme.border,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorite ? KalimaTheme.gold : KalimaTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 4. DESCRIÇÃO / SINOPSE
                const Text(
                  'SINOPSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.descricao,
                  style: TextStyle(
                    color: KalimaTheme.textSecondary,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 35),

                // 5. RECOMENDAÇÕES (SE HOUVER)
                if (_recommendations.isNotEmpty) ...[
                  const Text(
                    'CONTEÚDOS SEMELHANTES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final rec = _recommendations[index];
                        return _buildRecommendationCard(rec);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Video video) {
    return GestureDetector(
      onTap: () {
        // Recarrega a tela com o novo vídeo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(videoId: video.id, video: video),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: KalimaTheme.surface,
          border: Border.all(color: KalimaTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem pequena
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
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
            // Título pequeno
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.duracao,
                      style: TextStyle(color: KalimaTheme.textSecondary, fontSize: 11),
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
}

// =========================================================================
// HUD INTERATIVO DO PLAYER DE VÍDEO SIMULADO
// =========================================================================

class SimulatedVideoPlayer extends StatefulWidget {
  final Video video;

  const SimulatedVideoPlayer({super.key, required this.video});

  @override
  State<SimulatedVideoPlayer> createState() => _SimulatedVideoPlayerState();
}

class _SimulatedVideoPlayerState extends State<SimulatedVideoPlayer> {
  bool _isPlaying = true;
  double _sliderValue = 0.0;
  bool _isBuffering = true;
  
  late Timer _playbackTimer;
  late Timer _bufferingTimer;

  int _currentSeconds = 0;
  final int _totalSeconds = 480; // 8 minutos fixos para demonstração

  @override
  void initState() {
    super.initState();

    // Simula atraso inicial de carregamento / buffering
    _bufferingTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
        _startPlayback();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          if (_currentSeconds < _totalSeconds) {
            _currentSeconds++;
            _sliderValue = _currentSeconds / _totalSeconds;
          } else {
            _isPlaying = false;
            _playbackTimer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bufferingTimer.cancel();
    if (this._isPlaying) {
      _playbackTimer.cancel();
    }
    super.dispose();
  }

  // Helpers de Formatação de Tempo
  String _formatTime(int totalSecs) {
    final minutes = totalSecs ~/ 60;
    final seconds = totalSecs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. TELA PRETA OU BACKDROP DE CAPA DE FUNDO ESCURECIDA
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                widget.video.capaUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. BUFFERING OVERLAY
          if (_isBuffering)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: KalimaTheme.primary, strokeWidth: 4),
                const SizedBox(height: 20),
                Text(
                  'Conectando servidor de mídia...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

          // 3. CONTROLES HUD OPERACIONAIS (SÓ EXIBIDOS APÓS O BUFFERING)
          if (!_isBuffering) ...[
            // Cabeçalho superior (Título + Fechar)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPRODUZINDO AGORA',
                          style: TextStyle(
                            color: KalimaTheme.primary.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          widget.video.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'HD 1080P',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controles de Play / Avançar / Voltar centrais
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Voltar 10 segundos
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                    onPressed: () {
                      setState(() {
                        _currentSeconds = (_currentSeconds - 10).clamp(0, _totalSeconds);
                        _sliderValue = _currentSeconds / _totalSeconds;
                      });
                    },
                  ),
                  const SizedBox(width: 30),

                  // Botão central de Play / Pause com glow
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KalimaTheme.primary.withOpacity(0.9),
                        boxShadow: KalimaTheme.neonGlow(color: KalimaTheme.primary, blur: 15),
                      ),
                      child: Center(
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),

                  // Avançar 10 segundos
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                    onPressed: () {
                      setState(() {
                        _currentSeconds = (_currentSeconds + 10).clamp(0, _totalSeconds);
                        _sliderValue = _currentSeconds / _totalSeconds;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Painel inferior de Linha do Tempo / Timeline
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Cronômetro (Decorrido e Total)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(_currentSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(_totalSeconds),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Slider Linha do tempo interativa
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: KalimaTheme.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayColor: KalimaTheme.primary.withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                          _currentSeconds = (value * _totalSeconds).toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
