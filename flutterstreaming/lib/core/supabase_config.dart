import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video.dart';

class SupabaseConfig {
  // =========================================================================
  // SUPABASE CREDENTIALS
  // Altere os valores abaixo com as credenciais do seu projeto Supabase
  // =========================================================================
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';
  static const String supabaseAnonKey = 'sua-anon-key-aqui';

  static bool isInitialized = false;
  static bool demoLoggedIn = false;
  static String demoEmail = '';

  /// Inicializa o Supabase. Caso as credenciais padrão não tenham sido alteradas,
  /// o app irá rodar em modo de demonstração com dados locais para evitar travamentos.
  static Future<void> init() async {
    if (supabaseUrl == 'https://seu-projeto.supabase.co' || supabaseAnonKey == 'sua-anon-key-aqui') {
      print('Aviso: Supabase rodando em modo DEMO/LOCAL. Configure as chaves reais para persistência remota.');
      isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isInitialized = true;
      print('Supabase inicializado com sucesso!');
    } catch (e) {
      print('Erro ao inicializar Supabase: $e');
      isInitialized = false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  // =========================================================================
  // METODOS DE AUTENTICAÇÃO
  // =========================================================================

  static Future<AuthResponse?> signIn(String email, String password) async {
    if (!isInitialized) {
      // Modo DEMO: Simula login com qualquer credencial
      demoLoggedIn = true;
      demoEmail = email;
      return null;
    }
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse?> signUp(String email, String password) async {
    if (!isInitialized) {
      // Modo DEMO
      demoLoggedIn = true;
      demoEmail = email;
      return null;
    }
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    if (isInitialized) {
      await client.auth.signOut();
    } else {
      demoLoggedIn = false;
      demoEmail = '';
    }
  }

  static User? get currentUser {
    if (!isInitialized) {
      // Retorna usuário simulado no modo DEMO se logado
      if (demoLoggedIn) {
        return User(
          id: 'demo-user-12345',
          appMetadata: {},
          userMetadata: {},
          aud: '',
          createdAt: DateTime.now().toIso8601String(),
          email: demoEmail.isNotEmpty ? demoEmail : 'academico@kalima.edu',
        );
      }
      return null;
    }
    return client.auth.currentUser;
  }

  // =========================================================================
  // SERVIÇOS DO BANCO DE DADOS (VIDEOS, FAVORITOS E HISTORICO)
  // =========================================================================

  /// Busca todos os vídeos do banco. Retorna fallback de qualidade se o Supabase não estiver conectado ou vazio.
  static Future<List<Video>> fetchVideos() async {
    if (!isInitialized) {
      return fallbackVideos;
    }

    try {
      final response = await client.from('videos').select();
      if (response == null || (response as List).isEmpty) {
        return fallbackVideos;
      }
      final List<dynamic> data = response;
      return data.map((json) => Video.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar vídeos do Supabase (usando fallback): $e');
      return fallbackVideos;
    }
  }

  /// Busca a lista de vídeos favoritados pelo usuário ativo
  static Future<List<Video>> fetchFavorites() async {
    if (!isInitialized) {
      return demoFavorites;
    }

    try {
      final user = currentUser;
      if (user == null) return [];

      // Consulta no formato: favoritos(video_id, videos(*))
      final response = await client
          .from('favoritos')
          .select('id, video:videos(*)')
          .eq('usuario_id', user.id);

      if (response == null) return [];
      
      final List<dynamic> data = response;
      List<Video> favoriteVideos = [];

      for (var item in data) {
        if (item['video'] != null) {
          final video = Video.fromJson(item['video']);
          // Salva o ID da linha da tabela favoritos para exclusão direta
          video.favoriteRowId = item['id'];
          favoriteVideos.add(video);
        }
      }
      return favoriteVideos;
    } catch (e) {
      print('Erro ao buscar favoritos (usando demo): $e');
      return demoFavorites;
    }
  }

  /// Verifica se um vídeo específico está favoritado pelo usuário
  static Future<bool> isFavorite(String videoId) async {
    if (!isInitialized) {
      return demoFavorites.any((element) => element.id == videoId);
    }

    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await client
          .from('favoritos')
          .select('id')
          .eq('usuario_id', user.id)
          .eq('video_id', videoId);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Adiciona um vídeo aos favoritos
  static Future<void> addFavorite(String videoId) async {
    if (!isInitialized) {
      if (!demoFavorites.any((element) => element.id == videoId)) {
        final video = fallbackVideos.firstWhere((v) => v.id == videoId, orElse: () => fallbackVideos[0]);
        demoFavorites.add(video);
      }
      return;
    }

    final user = currentUser;
    if (user == null) return;

    await client.from('favoritos').insert({
      'usuario_id': user.id,
      'video_id': videoId,
    });
  }

  /// Remove um vídeo dos favoritos
  static Future<void> removeFavorite(String videoId) async {
    if (!isInitialized) {
      demoFavorites.removeWhere((element) => element.id == videoId);
      return;
    }

    final user = currentUser;
    if (user == null) return;

    await client
        .from('favoritos')
        .delete()
        .eq('usuario_id', user.id)
        .eq('video_id', videoId);
  }

  /// Busca o histórico de exibição do usuário
  static Future<List<Video>> fetchHistory() async {
    if (!isInitialized) {
      return demoHistory;
    }

    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await client
          .from('historico')
          .select('id, assistido_em, video:videos(*)')
          .eq('usuario_id', user.id)
          .order('assistido_em', ascending: false);

      if (response == null) return [];

      final List<dynamic> data = response;
      List<Video> historyVideos = [];

      for (var item in data) {
        if (item['video'] != null) {
          final video = Video.fromJson(item['video']);
          video.historyRowId = item['id'];
          
          // Formata a data de visualização
          if (item['assistido_em'] != null) {
            video.watchedAt = DateTime.tryParse(item['assistido_em']);
          }
          historyVideos.add(video);
        }
      }
      return historyVideos;
    } catch (e) {
      print('Erro ao buscar histórico (usando demo): $e');
      return demoHistory;
    }
  }

  /// Adiciona um vídeo ao histórico
  static Future<void> addToHistory(String videoId) async {
    if (!isInitialized) {
      final video = fallbackVideos.firstWhere((v) => v.id == videoId, orElse: () => fallbackVideos[0]);
      // Remove se já existir para colocar no topo
      demoHistory.removeWhere((element) => element.id == videoId);
      final clonedVideo = Video(
        id: video.id,
        titulo: video.titulo,
        descricao: video.descricao,
        capaUrl: video.capaUrl,
        videoUrl: video.videoUrl,
        categoria: video.categoria,
        duracao: video.duracao,
        classificacao: video.classificacao,
      );
      clonedVideo.historyRowId = 'demo-hist-${DateTime.now().millisecondsSinceEpoch}';
      clonedVideo.watchedAt = DateTime.now();
      demoHistory.insert(0, clonedVideo);
      return;
    }

    final user = currentUser;
    if (user == null) return;

    await client.from('historico').insert({
      'usuario_id': user.id,
      'video_id': videoId,
    });
  }

  /// Remove um item específico do histórico
  static Future<void> deleteHistoryItem(String historyRowId) async {
    if (!isInitialized) {
      demoHistory.removeWhere((element) => element.historyRowId == historyRowId);
      return;
    }

    await client.from('historico').delete().eq('id', historyRowId);
  }

  // =========================================================================
  // DADOS DE DEMONSTRAÇÃO / FALLBACK (PREMIUM LOOK)
  // =========================================================================

  static final List<Video> fallbackVideos = [
    Video(
      id: 'v1',
      titulo: 'Flutter Avançado & Arquitetura',
      descricao: 'Domine arquitetura limpa, injeção de dependências e gerência de estado avançada no Flutter para criar apps escaláveis e testáveis de nível profissional.',
      capaUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      categoria: 'Adicionados Recentemente',
      duracao: '1h 15min',
      classificacao: 4.9,
    ),
    Video(
      id: 'v2',
      titulo: 'Segurança em APIs com Supabase',
      descricao: 'Descubra como proteger seus dados no Supabase usando políticas RLS (Row Level Security) avançadas, autenticação JWT e melhores práticas de segurança.',
      capaUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/movie.mp4',
      categoria: 'Adicionados Recentemente',
      duracao: '48 min',
      classificacao: 4.7,
    ),
    Video(
      id: 'v3',
      titulo: 'Criando Interfaces com Rive',
      descricao: 'Aprenda a criar animações fluidas e vetoriais em tempo real com Rive, e integre diretamente no seu aplicativo Flutter com controle total de estado.',
      capaUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      categoria: 'Adicionados Recentemente',
      duracao: '55 min',
      classificacao: 4.8,
    ),
    Video(
      id: 'v4',
      titulo: 'Introdução ao Flutter Flow',
      descricao: 'Acelere o desenvolvimento com no-code/low-code sem perder o controle do código. Crie layouts responsivos de forma visual e exporte para Flutter puro.',
      capaUrl: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/movie.mp4',
      categoria: 'Adicionados Recentemente',
      duracao: '35 min',
      classificacao: 4.5,
    ),
    Video(
      id: 'v5',
      titulo: 'UI/UX Design para Devs',
      descricao: 'Aprenda como aplicar princípios de design, tipografia, harmonia de cores e espaçamento para tornar suas interfaces incríveis e visualmente premium.',
      capaUrl: 'https://images.unsplash.com/photo-1586717791821-3f44a563fa4c?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      categoria: 'Mais Assistidos',
      duracao: '1h 02min',
      classificacao: 4.9,
    ),
    Video(
      id: 'v6',
      titulo: 'Machine Learning no Mobile',
      descricao: 'Como integrar modelos de Inteligência Artificial e Deep Learning localmente ou na nuvem em dispositivos móveis Android e iOS usando Flutter.',
      capaUrl: 'https://images.unsplash.com/photo-1527474305487-b87b222841cc?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/movie.mp4',
      categoria: 'Mais Assistidos',
      duracao: '1h 20min',
      classificacao: 4.8,
    ),
    Video(
      id: 'v7',
      titulo: 'Desenvolvimento Web com Flutter',
      descricao: 'Entenda como compilar seu projeto Flutter para a Web, otimizar a renderização de elementos CanvasKit/HTML e configurar roteamento e SEO.',
      capaUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      categoria: 'Mais Assistidos',
      duracao: '50 min',
      classificacao: 4.6,
    ),
    Video(
      id: 'v8',
      titulo: 'Banco de Dados Relacional & SQL',
      descricao: 'Desmistifique o SQL e aprenda conceitos fundamentais de modelagem de dados, chaves primárias/estrangeiras, joins e triggers usando o PostgreSQL.',
      capaUrl: 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.w3schools.com/html/movie.mp4',
      categoria: 'Mais Assistidos',
      duracao: '1h 10min',
      classificacao: 4.8,
    ),
  ];

  static List<Video> demoFavorites = [];
  static List<Video> demoHistory = [];
}
