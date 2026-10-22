-- Gastos de Trabajo · cliente en las comisiones
-- Cada venta guarda el nombre del cliente. La fecha del gasto es la fecha de instalación.
-- Pégalo en SQL Editor > New query y pulsa Run (una sola vez). No borra nada.
alter table public.gastos add column if not exists cliente text not null default '';
