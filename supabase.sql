create extension if not exists pgcrypto;

create table if not exists public.app_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.vpus (
  id uuid primary key default gen_random_uuid(),
  label text not null unique,
  model text,
  license_key text unique,
  status text not null default 'awaiting_update'
    check (status in ('awaiting_update','available','reserved','in_field','maintenance')),
  updated_on date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint available_vpu_requires_license check (status <> 'available' or nullif(trim(license_key),'') is not null)
);

create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  farm_name text not null,
  equipment_id uuid not null references public.vpus(id),
  license_key text not null,
  installation_date date,
  status text not null default 'reserved'
    check (status in ('reserved','separating','in_field','installed','returned','cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Impede duas reservas ativas simultâneas para a mesma VPU.
create unique index if not exists one_active_reservation_per_vpu
on public.reservations(equipment_id)
where status in ('reserved','separating','in_field');

create table if not exists public.movements (
  id uuid primary key default gen_random_uuid(),
  equipment_id uuid references public.vpus(id) on delete set null,
  action text not null,
  details text,
  actor text,
  created_at timestamptz not null default now()
);

create or replace function public.is_vpu_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

alter table public.app_admins enable row level security;
alter table public.vpus enable row level security;
alter table public.reservations enable row level security;
alter table public.movements enable row level security;

-- Remova políticas antigas com estes nomes se estiver repetindo a instalação.
drop policy if exists "Public can read vpus" on public.vpus;
drop policy if exists "Admins manage vpus" on public.vpus;
drop policy if exists "Public can read reservations" on public.reservations;
drop policy if exists "Admins manage reservations" on public.reservations;
drop policy if exists "Public can read movements" on public.movements;
drop policy if exists "Admins manage movements" on public.movements;
drop policy if exists "Admins can read admin list" on public.app_admins;

create policy "Public can read vpus" on public.vpus for select to anon, authenticated using (true);
create policy "Admins manage vpus" on public.vpus for all to authenticated using (public.is_vpu_admin()) with check (public.is_vpu_admin());

create policy "Public can read reservations" on public.reservations for select to anon, authenticated using (true);
create policy "Admins manage reservations" on public.reservations for all to authenticated using (public.is_vpu_admin()) with check (public.is_vpu_admin());

create policy "Public can read movements" on public.movements for select to anon, authenticated using (true);
create policy "Admins manage movements" on public.movements for all to authenticated using (public.is_vpu_admin()) with check (public.is_vpu_admin());

create policy "Admins can read admin list" on public.app_admins for select to authenticated using (user_id = auth.uid());

grant usage on schema public to anon, authenticated;
grant select on public.vpus, public.reservations, public.movements to anon, authenticated;
grant insert, update, delete on public.vpus, public.reservations, public.movements to authenticated;
grant select on public.app_admins to authenticated;

-- IMPORTANTE:
-- 1. Crie o usuário administrador em Authentication > Users no Supabase.
-- 2. Copie o UUID desse usuário e execute:
-- insert into public.app_admins (user_id) values ('COLE-O-UUID-DO-ADMIN-AQUI');
--
-- 3. Não coloque a service_role key no HTML. Use somente a chave anon/publishable.
--
-- Nota: a primeira versão registra histórico de cadastros e mudanças de reserva.
-- Para produção, recomendamos evoluir as movimentações para triggers no banco,
-- assim alterações feitas por qualquer interface também ficam auditadas.
