-- One Supabase project, one schema per app.
-- Replace app_starter with app_<your_app_slug> before running in the SQL
-- editor (the bootstrap script does this automatically).
--
-- Schema summary
-- --------------
-- profiles:  user profile mirror (auth metadata + display name)
-- feedback:  private in-app feedback (stars + message)
--
-- The template intentionally ships only generic tables. App-specific tables
-- (history, usage, entitlements, etc.) are added per app inside the same
-- app_<slug> schema with their own RLS policies. The delete-account edge
-- function must be extended to cover any app-specific tables.

create schema if not exists app_starter;

create table if not exists app_starter.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists app_starter.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  message text not null,
  created_at timestamptz not null default now()
);

alter table app_starter.profiles enable row level security;
alter table app_starter.feedback enable row level security;

drop policy if exists "profiles select own" on app_starter.profiles;
create policy "profiles select own"
  on app_starter.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles insert own" on app_starter.profiles;
create policy "profiles insert own"
  on app_starter.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles update own" on app_starter.profiles;
create policy "profiles update own"
  on app_starter.profiles for update
  using (auth.uid() = id);

drop policy if exists "feedback insert own" on app_starter.feedback;
create policy "feedback insert own"
  on app_starter.feedback for insert
  with check (auth.uid() = user_id);

drop policy if exists "feedback select own" on app_starter.feedback;
create policy "feedback select own"
  on app_starter.feedback for select
  using (auth.uid() = user_id);

drop policy if exists "feedback delete own" on app_starter.feedback;
create policy "feedback delete own"
  on app_starter.feedback for delete
  using (auth.uid() = user_id);

grant usage on schema app_starter to anon, authenticated;
grant select, insert, update on app_starter.profiles to authenticated;
grant select, insert, delete on app_starter.feedback to authenticated;

-- Remember to add app_starter to: Dashboard -> Project Settings -> API -> Exposed schemas.
