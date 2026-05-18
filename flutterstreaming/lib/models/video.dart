class Video {
  final String id;
  final String titulo;
  final String descricao;
  final String capaUrl;
  final String? videoUrl;
  final String categoria;
  final String duracao;
  final double classificacao;

  // Propriedades auxiliares para tabelas de junção do Supabase
  String? favoriteRowId;
  String? historyRowId;
  DateTime? watchedAt;

  Video({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.capaUrl,
    this.videoUrl,
    required this.categoria,
    this.duracao = '45 min',
    this.classificacao = 4.8,
    this.favoriteRowId,
    this.historyRowId,
    this.watchedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Sem título',
      descricao: json['descricao']?.toString() ?? 'Sem descrição',
      capaUrl: json['capa_url']?.toString() ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
      videoUrl: json['video_url']?.toString(),
      categoria: json['categoria']?.toString() ?? 'Geral',
      duracao: json['duracao']?.toString() ?? '45 min',
      classificacao: double.tryParse(json['classificacao']?.toString() ?? '4.8') ?? 4.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'capa_url': capaUrl,
      'video_url': videoUrl,
      'categoria': categoria,
      'duracao': duracao,
      'classificacao': classificacao,
    };
  }
}
