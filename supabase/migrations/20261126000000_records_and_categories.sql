-- Registros y categorias de Fino. La app guarda primero en el dispositivo
-- (Hive) y sincroniza con estas tablas. Un borrado se marca con deleted_at
-- para que llegue a los demas dispositivos.

create table public.records (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null check (kind in ('income', 'expense', 'debt', 'buy')),
  name text not null,
  amount numeric(16, 2) not null default 0,
  date date,
  category text,
  note text,
  done boolean not null default false,
  price_pending boolean not null default false,
  -- Gasto generado al marcar como pagada una deuda o comprada una compra.
  expense_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index records_user_updated_idx on public.records (user_id, updated_at);

create table public.categories (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null check (kind in ('income', 'expense', 'debt', 'buy')),
  name text not null check (char_length(name) between 1 and 24),
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, kind, name)
);

create index categories_user_updated_idx on public.categories (user_id, updated_at);

-- El servidor fija updated_at; los clientes lo usan como cursor para bajar
-- solo lo que cambio desde la ultima sincronizacion.
create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger records_touch before insert or update on public.records
  for each row execute function public.touch_updated_at();
create trigger categories_touch before insert or update on public.categories
  for each row execute function public.touch_updated_at();

-- Cada cuenta solo ve y modifica sus datos. No hay politica de borrado: los
-- clientes marcan deleted_at.
alter table public.records enable row level security;
alter table public.categories enable row level security;

create policy "Cada usuario ve sus registros" on public.records
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Cada usuario crea sus registros" on public.records
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Cada usuario edita sus registros" on public.records
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "Cada usuario ve sus categorias" on public.categories
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Cada usuario crea sus categorias" on public.categories
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Cada usuario edita sus categorias" on public.categories
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
