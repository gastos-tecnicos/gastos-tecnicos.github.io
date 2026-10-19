-- Gastos de Trabajo · cobros en mano
-- Pégalo en SQL Editor > New query y pulsa Run (una sola vez).

create table if not exists public.cobros (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fecha       date not null,
  importe     numeric(10,2) not null check (importe >= 0),   -- lo que te han dado en mano
  marcado     numeric(10,2) not null default 0,              -- suma de los gastos que dice cubrir
  entregado_por text not null default '',
  nota        text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists cobros_user_fecha on public.cobros (user_id, fecha desc);

alter table public.cobros enable row level security;

drop policy if exists "cobros_select_own" on public.cobros;
drop policy if exists "cobros_insert_own" on public.cobros;
drop policy if exists "cobros_update_own" on public.cobros;
drop policy if exists "cobros_delete_own" on public.cobros;

create policy "cobros_select_own" on public.cobros for select to authenticated using (user_id = auth.uid());
create policy "cobros_insert_own" on public.cobros for insert to authenticated with check (user_id = auth.uid());
create policy "cobros_update_own" on public.cobros for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "cobros_delete_own" on public.cobros for delete to authenticated using (user_id = auth.uid());

-- Cada gasto sabe con qué cobro se pagó
alter table public.gastos add column if not exists cobro_id uuid references public.cobros(id) on delete set null;
create index if not exists gastos_cobro on public.gastos (cobro_id);
