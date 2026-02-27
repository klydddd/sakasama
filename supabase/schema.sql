-- ============================================================
-- Sakasama — Supabase PostgreSQL Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ── Enable UUID extension ─────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Helper: auto-update updated_at ────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;


-- ============================================================
-- 1. PROFILES — extends auth.users
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  preferred_language text default 'fil',
  onboarding_completed boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function update_updated_at();

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================
-- 2. FARM PROFILES
-- ============================================================
create table if not exists public.farm_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farmer_name text not null,
  farm_name text not null,
  location text,
  crop_type text,
  farm_size_hectares real,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  is_deleted boolean default false
);

create trigger farm_profiles_updated_at
  before update on public.farm_profiles
  for each row execute function update_updated_at();

alter table public.farm_profiles enable row level security;

create policy "Users can CRUD own farms"
  on public.farm_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_farm_profiles_user on public.farm_profiles(user_id);
create index idx_farm_profiles_updated on public.farm_profiles(updated_at);


-- ============================================================
-- 3. ACTIVITY LOGS
-- ============================================================
create table if not exists public.activity_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid references public.farm_profiles(id) on delete set null,
  activity_date date not null,
  activity_type text not null,
  product_used text,
  quantity real,
  unit text,
  notes text,
  photo_path text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  is_deleted boolean default false
);

create trigger activity_logs_updated_at
  before update on public.activity_logs
  for each row execute function update_updated_at();

alter table public.activity_logs enable row level security;

create policy "Users can CRUD own activity logs"
  on public.activity_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_activity_logs_user on public.activity_logs(user_id);
create index idx_activity_logs_farm on public.activity_logs(farm_id);
create index idx_activity_logs_updated on public.activity_logs(updated_at);
create index idx_activity_logs_date on public.activity_logs(activity_date);


-- ============================================================
-- 4. COMPLIANCE RECORDS
-- ============================================================
create table if not exists public.compliance_records (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid references public.farm_profiles(id) on delete set null,
  form_type text not null,
  status text not null default 'incomplete',
  data jsonb default '{}',
  file_path text,
  submitted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  is_deleted boolean default false
);

create trigger compliance_records_updated_at
  before update on public.compliance_records
  for each row execute function update_updated_at();

alter table public.compliance_records enable row level security;

create policy "Users can CRUD own compliance records"
  on public.compliance_records for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_compliance_records_user on public.compliance_records(user_id);
create index idx_compliance_records_farm on public.compliance_records(farm_id);
create index idx_compliance_records_updated on public.compliance_records(updated_at);
