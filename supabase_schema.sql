create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,email text,display_name text not null,role text not null default 'viewer' check(role in ('admin','manager','viewer')),created_at timestamptz not null default now());
create table if not exists public.construction_sites(id uuid primary key default gen_random_uuid(),name text not null,address text,lat double precision,lon double precision,memo text,created_by uuid references public.profiles(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.fleet_assets(id uuid primary key default gen_random_uuid(),name text not null,asset_no text not null unique,type text not null,site_id uuid references public.construction_sites(id),status text not null default '待機',odometer numeric(12,1) default 0,hour_meter numeric(12,1) default 0,inspection_date date,shaken_date date,memo text,updated_by uuid references public.profiles(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.move_records(id uuid primary key default gen_random_uuid(),asset_id uuid references public.fleet_assets(id) on delete set null,asset_name text,from_site_name text,to_site_name text,memo text,user_id uuid references public.profiles(id),completed boolean not null default false,completed_at timestamptz,created_at timestamptz not null default now());
create table if not exists public.audit_logs(id uuid primary key default gen_random_uuid(),action text not null,detail text,record_id uuid,user_id uuid references public.profiles(id),created_at timestamptz not null default now());

create or replace function public.is_admin() returns boolean language sql security definer set search_path=public stable as $$select exists(select 1 from public.profiles where id=auth.uid() and role='admin')$$;
alter table public.profiles enable row level security; alter table public.construction_sites enable row level security; alter table public.fleet_assets enable row level security; alter table public.move_records enable row level security; alter table public.audit_logs enable row level security;
drop policy if exists p_profiles_select on public.profiles; create policy p_profiles_select on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
drop policy if exists p_profiles_insert on public.profiles; create policy p_profiles_insert on public.profiles for insert to authenticated with check (id=auth.uid());
drop policy if exists p_profiles_update on public.profiles; create policy p_profiles_update on public.profiles for update to authenticated using (id=auth.uid() or public.is_admin()) with check (id=auth.uid() or public.is_admin());
drop policy if exists p_sites_all on public.construction_sites; create policy p_sites_all on public.construction_sites for all to authenticated using (true) with check (true);
drop policy if exists p_assets_all on public.fleet_assets; create policy p_assets_all on public.fleet_assets for all to authenticated using (true) with check (true);
drop policy if exists p_moves_all on public.move_records; create policy p_moves_all on public.move_records for all to authenticated using (true) with check (true);
drop policy if exists p_audit_select on public.audit_logs; create policy p_audit_select on public.audit_logs for select to authenticated using (true);
drop policy if exists p_audit_insert on public.audit_logs; create policy p_audit_insert on public.audit_logs for insert to authenticated with check (user_id=auth.uid());

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now(); return new; end$$;
drop trigger if exists trg_sites_touch on public.construction_sites; create trigger trg_sites_touch before update on public.construction_sites for each row execute function public.touch_updated_at();
drop trigger if exists trg_assets_touch on public.fleet_assets; create trigger trg_assets_touch before update on public.fleet_assets for each row execute function public.touch_updated_at();

-- Realtime（簡易版）
do $$ begin
  alter publication supabase_realtime add table public.construction_sites;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.fleet_assets;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.move_records;
exception when duplicate_object then null; end $$;
