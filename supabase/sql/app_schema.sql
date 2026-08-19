-- Schema: app_grammar_fix
-- Used exclusively for optional anonymous feedback.
-- User writing, correction text, custom dictionaries, and history NEVER touch Supabase.

create schema if not exists app_grammar_fix;

create table if not exists app_grammar_fix.feedback (
  id uuid primary key default gen_random_uuid(),
  rating smallint not null check (rating between 1 and 5),
  message text not null,
  app_version text not null default '1.0.0',
  created_at timestamptz not null default now()
);

alter table app_grammar_fix.feedback enable row level security;

-- Allow anonymous inserts for feedback
drop policy if exists "anon feedback insert" on app_grammar_fix.feedback;
create policy "anon feedback insert"
  on app_grammar_fix.feedback for insert
  to anon, authenticated
  with check (true);

grant usage on schema app_grammar_fix to anon, authenticated;
grant insert on app_grammar_fix.feedback to anon, authenticated;

-- Add app_grammar_fix to: Dashboard -> Project Settings -> API -> Exposed schemas.
