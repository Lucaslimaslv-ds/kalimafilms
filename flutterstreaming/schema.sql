-- =========================================================================
-- KALIMAFILMS - BANCO DE DADOS POSTGRESQL (SUPABASE)
-- =========================================================================

-- Limpar tabelas existentes se necessário para recriar do zero com segurança
drop table if exists historico cascade;
drop table if exists favoritos cascade;
drop table if exists videos cascade;

-- =========================================================================
-- 1. TABELA DE VÍDEOS / FILMES / SÉRIES
-- =========================================================================
create table videos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  descricao text not null,
  capa_url text not null,
  video_url text,
  categoria text not null, -- Ex: 'Mais Assistidos', 'Adicionados Recentemente', 'Design & UI/UX'
  duracao text default '45 min', -- Duração mockada para exibição premium
  classificacao numeric(3,1) default 4.8, -- Nota do vídeo para interface premium (Ex: 4.9)
  criado_em timestamp with time zone default now()
);

-- =========================================================================
-- 2. TABELA DE FAVORITOS
-- =========================================================================
create table favoritos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  video_id uuid not null references videos(id) on delete cascade,
  criado_em timestamp with time zone default now(),
  unique(usuario_id, video_id)
);

-- =========================================================================
-- 3. TABELA DE HISTÓRICO DE ASSISTIDOS
-- =========================================================================
create table historico (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  video_id uuid not null references videos(id) on delete cascade,
  assistido_em timestamp with time zone default now()
);

-- =========================================================================
-- 4. ÍNDICES DE PERFORMANCE E OTIMIZAÇÃO
-- =========================================================================
create index idx_favoritos_usuario on favoritos(usuario_id);
create index idx_historico_usuario on historico(usuario_id);
create index idx_videos_categoria on videos(categoria);

-- =========================================================================
-- 5. ATIVAR ROW LEVEL SECURITY (RLS)
-- =========================================================================
alter table videos enable row level security;
alter table favoritos enable row level security;
alter table historico enable row level security;

-- =========================================================================
-- 6. POLÍTICAS DE SEGURANÇA (RLS POLICIES)
-- =========================================================================

-- POLÍTICAS DA TABELA VIDEOS (Todos podem visualizar)
create policy "Todos podem visualizar videos"
on videos
for select
using (true);

-- POLÍTICAS DA TABELA FAVORITOS (Apenas o próprio usuário autenticado pode manipular)
create policy "Usuario pode ver seus favoritos"
on favoritos
for select
using (auth.uid() = usuario_id);

create policy "Usuario pode adicionar favoritos"
on favoritos
for insert
with check (auth.uid() = usuario_id);

create policy "Usuario pode remover favoritos"
on favoritos
for delete
using (auth.uid() = usuario_id);

-- POLÍTICAS DA TABELA HISTORICO (Apenas o próprio usuário autenticado pode manipular)
create policy "Usuario pode ver historico"
on historico
for select
using (auth.uid() = usuario_id);

create policy "Usuario pode adicionar historico"
on historico
for insert
with check (auth.uid() = usuario_id);

create policy "Usuario pode deletar historico"
on historico
for delete
using (auth.uid() = usuario_id);

-- =========================================================================
-- 7. INSERÇÃO DE VÍDEOS DE EXEMPLO (PREMIUM ACADEMIC & DEV)
-- =========================================================================
insert into videos (titulo, descricao, capa_url, video_url, categoria, duracao, classificacao)
values
-- Categoria: Adicionados Recentemente
(
  'Flutter Avançado & Arquitetura',
  'Domine arquitetura limpa, injeção de dependências e gerência de estado avançada no Flutter para criar apps escaláveis e testáveis de nível profissional.',
  'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/mov_bbb.mp4', -- URL de vídeo real para teste
  'Adicionados Recentemente',
  '1h 15min',
  4.9
),
(
  'Segurança em APIs com Supabase',
  'Descubra como proteger seus dados no Supabase usando políticas RLS (Row Level Security) avançadas, autenticação JWT e melhores práticas de segurança.',
  'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/movie.mp4', -- URL de vídeo real para teste
  'Adicionados Recentemente',
  '48 min',
  4.7
),
(
  'Criando Interfaces com Rive',
  'Aprenda a criar animações fluidas e vetoriais em tempo real com Rive, e integre diretamente no seu aplicativo Flutter com controle total de estado.',
  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/mov_bbb.mp4',
  'Adicionados Recentemente',
  '55 min',
  4.8
),
(
  'Introdução ao Flutter Flow',
  'Acelere o desenvolvimento com no-code/low-code sem perder o controle do código. Crie layouts responsivos de forma visual e exporte para Flutter puro.',
  'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/movie.mp4',
  'Adicionados Recentemente',
  '35 min',
  4.5
),

-- Categoria: Mais Assistidos
(
  'UI/UX Design para Devs',
  'Aprenda como aplicar princípios de design, tipografia, harmonia de cores e espaçamento para tornar suas interfaces incríveis e visualmente premium.',
  'https://images.unsplash.com/photo-1586717791821-3f44a563fa4c?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/mov_bbb.mp4',
  'Mais Assistidos',
  '1h 02min',
  4.9
),
(
  'Machine Learning no Mobile',
  'Como integrar modelos de Inteligência Artificial e Deep Learning localmente ou na nuvem em dispositivos móveis Android e iOS usando Flutter.',
  'https://images.unsplash.com/photo-1527474305487-b87b222841cc?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/movie.mp4',
  'Mais Assistidos',
  '1h 20min',
  4.8
),
(
  'Desenvolvimento Web com Flutter',
  'Entenda como compilar seu projeto Flutter para a Web, otimizar a renderização de elementos CanvasKit/HTML e configurar roteamento e SEO.',
  'https://images.unsplash.com/photo-1531403009284-440f080d1e12?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/mov_bbb.mp4',
  'Mais Assistidos',
  '50 min',
  4.6
),
(
  'Banco de Dados Relacional & SQL',
  'Desmistifique o SQL e aprenda conceitos fundamentais de modelagem de dados, chaves primárias/estrangeiras, joins e triggers usando o PostgreSQL.',
  'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?auto=format&fit=crop&w=600&q=80',
  'https://www.w3schools.com/html/movie.mp4',
  'Mais Assistidos',
  '1h 10min',
  4.8
);
