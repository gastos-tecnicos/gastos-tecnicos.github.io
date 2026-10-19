-- Gastos de Trabajo · versión 2
-- Conceptos y tarifas configurables, estado "presentado", avisos.
-- Requiere haber ejecutado antes setup.sql, cambio-hora.sql y cobros.sql.
-- Pégalo en SQL Editor > New query y pulsa Run (una sola vez). No borra nada.

-- 1. Conceptos de cada usuario (dieta, comisión, guardia…), con sus tarifas
create table if not exists public.conceptos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nombre      text not null check (char_length(nombre) between 1 and 40),
  modo        text not null default 'importe' check (modo in ('importe','unidades')),
  unidades    jsonb not null default '[]'::jsonb,   -- [{"nombre":"Fibra","precio":30}]
  rapidos     jsonb not null default '[]'::jsonb,   -- importes rápidos: [15,16,17]
  pide_hora   boolean not null default false,
  pide_foto   boolean not null default true,
  activo      boolean not null default true,
  orden       integer not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists conceptos_user on public.conceptos (user_id, orden);

alter table public.conceptos enable row level security;
drop policy if exists "conceptos_select_own" on public.conceptos;
drop policy if exists "conceptos_insert_own" on public.conceptos;
drop policy if exists "conceptos_update_own" on public.conceptos;
drop policy if exists "conceptos_delete_own" on public.conceptos;
create policy "conceptos_select_own" on public.conceptos for select to authenticated using (user_id = auth.uid());
create policy "conceptos_insert_own" on public.conceptos for insert to authenticated with check (user_id = auth.uid());
create policy "conceptos_update_own" on public.conceptos for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "conceptos_delete_own" on public.conceptos for delete to authenticated using (user_id = auth.uid());

-- 2. Gastos: concepto libre, unidades guardadas con su precio, fecha de presentación
alter table public.gastos drop constraint if exists gastos_tipo_check;
alter table public.gastos drop constraint if exists gastos_estado_check;
alter table public.gastos add constraint gastos_estado_check check (estado in ('pendiente','presentado','cobrado'));

alter table public.gastos add column if not exists concepto_id     uuid references public.conceptos(id) on delete set null;
alter table public.gastos add column if not exists concepto_nombre text;
alter table public.gastos add column if not exists unidades        jsonb;
alter table public.gastos add column if not exists presentado_el   date;
alter table public.gastos add column if not exists no_duplicado    boolean not null default false;

-- 3. Los gastos que ya tienes pasan al formato nuevo (no se pierde nada)
update public.gastos set concepto_nombre = case tipo
    when 'dieta' then 'Dieta' when 'comision' then 'Comisión'
    when 'parking' then 'Parking' when 'zona' then 'Zona azul' else initcap(tipo) end
  where concepto_nombre is null;

update public.gastos set unidades = (
    select coalesce(jsonb_agg(u),'[]'::jsonb) from (
      select jsonb_build_object('nombre','Fibra','precio',30,'cantidad',fibras) as u where fibras > 0
      union all
      select jsonb_build_object('nombre','Línea móvil','precio',10,'cantidad',moviles) where moviles > 0
    ) t)
  where tipo = 'comision' and unidades is null;
