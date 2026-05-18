import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/supabase_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userEmail = 'Carregando...';
  int _favoritesCount = 0;
  int _historyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = SupabaseConfig.currentUser;
    if (currentUser != null) {
      _userEmail = currentUser.email ?? 'academico@kalima.edu';
    } else {
      _userEmail = 'Convidado';
    }

    try {
      final favs = await SupabaseConfig.fetchFavorites();
      final hist = await SupabaseConfig.fetchHistory();
      if (mounted) {
        setState(() {
          _favoritesCount = favs.length;
          _historyCount = hist.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Diálogo de Confirmação Premium
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KalimaTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: KalimaTheme.border),
        ),
        title: const Text(
          'Confirmar Saída',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Você tem certeza que deseja encerrar sua sessão acadêmica no Kalima Films?',
          style: TextStyle(color: KalimaTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: KalimaTheme.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: KalimaTheme.primaryGradient,
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('SAIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await SupabaseConfig.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão encerrada com segurança.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: KalimaTheme.surfaceLight,
          ),
        );
        // Retorna para a tela de Login e limpa o histórico de navegação
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KalimaTheme.background,
      appBar: AppBar(
        title: const Text('MEU PERFIL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProfileData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KalimaTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: KalimaTheme.primary,
              backgroundColor: KalimaTheme.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 1. DOME AVATAR GLOWING
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: KalimaTheme.primaryGradient,
                          boxShadow: KalimaTheme.neonGlow(blur: 16),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: KalimaTheme.background,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded, // Ícone acadêmico
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // E-mail e Nível Acadêmico
                    Text(
                      _userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: KalimaTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KalimaTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'COMUNIDADE ACADÊMICA',
                        style: TextStyle(
                          color: KalimaTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // 2. MÉTRICAS ACADÊMICAS (ESTATÍSTICAS)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.favorite_rounded,
                            iconColor: KalimaTheme.gold,
                            value: _favoritesCount.toString(),
                            label: 'Salvos',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.history_rounded,
                            iconColor: KalimaTheme.primary,
                            value: _historyCount.toString(),
                            label: 'Assistidos',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. CARTÃO DE INFORMAÇÕES DO APP
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: KalimaTheme.surface,
                        border: Border.all(color: KalimaTheme.border),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProfileRow(
                            icon: Icons.verified_user_outlined,
                            title: 'Status da Conta',
                            value: 'Premium Ativo',
                            valueColor: Colors.greenAccent,
                          ),
                          const Divider(color: KalimaTheme.border, height: 24),
                          _buildProfileRow(
                            icon: Icons.phonelink_setup_rounded,
                            title: 'Conexão Supabase',
                            value: SupabaseConfig.isInitialized ? 'Conectado (Live)' : 'Demonstração (Local)',
                            valueColor: SupabaseConfig.isInitialized ? Colors.greenAccent : KalimaTheme.gold,
                          ),
                          const Divider(color: KalimaTheme.border, height: 24),
                          _buildProfileRow(
                            icon: Icons.code_rounded,
                            title: 'Protótipo Versão',
                            value: 'v1.0.0',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 4. BOTÃO VISÍVEL DE LOGOUT COM TEMA PREMIUM DE ALERTA
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: KalimaTheme.surfaceLight,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                        label: const Text(
                          'LOGOUT / SAIR DA CONTA',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.8,
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
                    const SizedBox(height: 120), // Espaço para o bottom bar
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: KalimaTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KalimaTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: KalimaTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: KalimaTheme.textSecondary, size: 22),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? KalimaTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
