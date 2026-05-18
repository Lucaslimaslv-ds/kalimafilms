import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';
import '../models/video.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Video> _historyVideos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await SupabaseConfig.fetchHistory();
      setState(() {
        _historyVideos = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Remoção rápida individual com feedback de UI imediato
  Future<void> _deleteHistoryItem(Video video) async {
    final String? historyRowId = video.historyRowId;
    if (historyRowId == null) return;

    final originalList = List<Video>.from(_historyVideos);

    // Otimista: remove localmente na hora
    setState(() {
      _historyVideos.removeWhere((v) => v.historyRowId == historyRowId);
    });

    try {
      await SupabaseConfig.deleteHistoryItem(historyRowId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item removido do histórico.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: KalimaTheme.surfaceLight,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Reverte
      setState(() {
        _historyVideos = originalList;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper para formatar data e hora do histórico
  String _formatWatchedDate(DateTime? dateTime) {
    if (dateTime == null) return 'Recentemente';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final String timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return 'Hoje às $timeString';
    } else if (difference.inDays <= 1 && now.day - 1 == dateTime.day) {
      return 'Ontem às $timeString';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} às $timeString';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KalimaTheme.background,
      appBar: AppBar(
        title: const Text('HISTÓRICO DE EXIBIÇÃO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
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

    if (_historyVideos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: KalimaTheme.primary,
      backgroundColor: KalimaTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _historyVideos.length + 1, // +1 para espaço final de scroll
        itemBuilder: (context, index) {
          if (index == _historyVideos.length) {
            return const SizedBox(height: 100); // Margem para o Bottom bar
          }

          final video = _historyVideos[index];
          return _buildHistoryCard(video);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Video video) {
    return Dismissible(
      key: Key('hist-${video.historyRowId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.redAccent.withOpacity(0.9),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteHistoryItem(video);
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
              // Imagem da capa (com badge de tempo no overlay)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 110,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          video.capaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: KalimaTheme.surfaceLight,
                            child: const Icon(Icons.broken_image, color: KalimaTheme.textSecondary),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black38,
                        ),
                      ),
                      // Ícone de Play sutil
                      const Center(
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Detalhes textuais
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
                      // Informação de Duração
                      Text(
                        'Duração: ${video.duracao}',
                        style: const TextStyle(color: KalimaTheme.textSecondary, fontSize: 11.5),
                      ),
                      const SizedBox(height: 4),
                      // Data e hora de exibição
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: KalimaTheme.primary, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatWatchedDate(video.watchedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: KalimaTheme.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Botão Deletar Item
              IconButton(
                icon: const Icon(Icons.clear_rounded, color: KalimaTheme.textSecondary, size: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: () {
                  _deleteHistoryItem(video);
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
                Icons.history_toggle_off_rounded,
                color: KalimaTheme.primary,
                size: 45,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Histórico vazio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você ainda não assistiu a nenhuma aula ou filme. Inicie uma reprodução e ela aparecerá cronologicamente aqui!',
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
              'Falha ao conectar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Erro ao recuperar histórico.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: KalimaTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHistory,
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
