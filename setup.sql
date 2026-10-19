-- Gastos de Trabajo · esquema para Supabase
-- Pégalo entero en SQL Editor > New query y pulsa Run (una sola vez).

-- 1. Tabla de gastos
create table if not exists public.gastos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fecha       date not null,
  hora        time,                       -- solo parking y zona azul
  tipo        text not null check (tipo in ('dieta','comision','parking','zona')),
  importe     numeric(10,2) not null check (importe > 0),
  fibras      integer not null default 0 check (fibras >= 0),
  moviles     integer not null default 0 check (moviles >= 0),
  lugar       text not null default '',
  nota        text not null default '',
  foto        text,                       -- ruta del archivo en el bucket "tickets"
  estado      text not null default 'pendiente' check (estado in ('pendiente','cobrado')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists gastos_user_fecha on public.gastos (user_id, fecha desc, hora desc);

-- updated_at automático
create or replace function public.gastos_touch() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists gastos_touch on public.gastos;
create trigger gastos_touch before update on public.gastos
for each row execute function public.gastos_touch();

-- 2. Seguridad: cada usuario solo ve y toca sus propios gastos
alter table public.gastos enable row level security;

drop policy if exists "gastos_select_own" on public.gastos;
drop policy if exists "gastos_insert_own" on public.gastos;
drop policy if exists "gastos_update_own" on public.gastos;
drop policy if exists "gastos_delete_own" on public.gastos;

create policy "gastos_select_own" on public.gastos for select to authenticated
  using (user_id = auth.uid());
create policy "gastos_insert_own" on public.gastos for insert to authenticated
  with check (user_id = auth.uid());
create policy "gastos_update_own" on public.gastos for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "gastos_delete_own" on public.gastos for delete to authenticated
  using (user_id = auth.uid());

-- 3. Fotos de facturas y tickets: bucket privado, cada usuario en su carpeta
insert into storage.buckets (id, name, public)
values ('tickets', 'tickets', false)
on conflict (id) do nothing;

drop policy if exists "tickets_select_own" on storage.objects;
drop policy if exists "tickets_insert_own" on storage.objects;
drop policy if exists "tickets_delete_own" on storage.objects;

create policy "tickets_select_own" on storage.objects for select to authenticated
  using (bucket_id = 'tickets' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "tickets_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'tickets' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "tickets_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'tickets' and (storage.foldername(name))[1] = auth.uid()::text);
