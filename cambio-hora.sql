-- La hora pasa a ser opcional (solo se usa en parking y zona azul).
-- Pégalo en SQL Editor > New query y pulsa Run una vez.
alter table public.gastos alter column hora drop not null;

-- Quita la hora a los gastos ya guardados que no son parking ni zona azul.
update public.gastos set hora = null where tipo not in ('parking','zona');
