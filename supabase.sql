-- PROJECT Y TICKETING / Supabase SQL
-- Im Supabase SQL Editor vollständig ausführen.
create extension if not exists pgcrypto;

create table if not exists public.project_y_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','bouncer')),
  created_at timestamptz not null default now()
);

create table if not exists public.project_y_tickets (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null check (length(trim(guest_name)) between 1 and 120),
  ticket_number text not null unique,
  token_hash text not null unique,
  status text not null default 'active' check (status in ('active','revoked')),
  created_at timestamptz not null default now()
);

alter table public.project_y_profiles enable row level security;
alter table public.project_y_tickets enable row level security;

drop policy if exists "profile read own" on public.project_y_profiles;
create policy "profile read own" on public.project_y_profiles
for select to authenticated using (user_id = auth.uid());

drop policy if exists "admin read tickets" on public.project_y_tickets;
create policy "admin read tickets" on public.project_y_tickets
for select to authenticated using (
  exists(select 1 from public.project_y_profiles p where p.user_id=auth.uid() and p.role='admin')
);
drop policy if exists "admin update tickets" on public.project_y_tickets;
create policy "admin update tickets" on public.project_y_tickets
for update to authenticated using (
  exists(select 1 from public.project_y_profiles p where p.user_id=auth.uid() and p.role='admin')
) with check (
  exists(select 1 from public.project_y_profiles p where p.user_id=auth.uid() and p.role='admin')
);

create or replace function public.my_project_y_role()
returns text language sql security definer set search_path=public
as $$
  select role from public.project_y_profiles where user_id=auth.uid()
$$;
revoke all on function public.my_project_y_role() from public;
grant execute on function public.my_project_y_role() to authenticated;

create or replace function public.create_project_y_tickets(p_tickets jsonb)
returns table(id uuid) language plpgsql security definer set search_path=public
as $$
declare item jsonb;
begin
  if not exists(select 1 from public.project_y_profiles where user_id=auth.uid() and role='admin') then
    raise exception 'Keine Berechtigung';
  end if;
  if jsonb_typeof(p_tickets) <> 'array' or jsonb_array_length(p_tickets) < 1 or jsonb_array_length(p_tickets) > 200 then
    raise exception 'Bitte zwischen 1 und 200 Tickets pro Vorgang erstellen';
  end if;
  for item in select value from jsonb_array_elements(p_tickets)
  loop
    insert into public.project_y_tickets(guest_name,ticket_number,token_hash,status)
    values(trim(item->>'guest_name'),item->>'ticket_number',item->>'token_hash','active')
    returning project_y_tickets.id into id;
    return next;
  end loop;
end $$;
revoke all on function public.create_project_y_tickets(jsonb) from public;
grant execute on function public.create_project_y_tickets(jsonb) to authenticated;

create or replace function public.check_project_y_ticket(p_token text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare t public.project_y_tickets%rowtype;
begin
  if not exists(select 1 from public.project_y_profiles where user_id=auth.uid() and role in ('admin','bouncer')) then
    raise exception 'Keine Scanner-Berechtigung';
  end if;
  select * into t from public.project_y_tickets
  where token_hash=encode(digest(convert_to(p_token,'UTF8'),'sha256'),'hex')
  limit 1;
  if not found then return jsonb_build_object('valid',false,'reason','Ticket nicht gefunden'); end if;
  if t.status <> 'active' then
    return jsonb_build_object('valid',false,'reason','Ticket wurde vom Veranstalter gesperrt',
      'ticket',jsonb_build_object('guest_name',t.guest_name,'ticket_number',t.ticket_number,'status',t.status));
  end if;
  -- Absichtlich KEIN Update: Scannen verbraucht oder entwertet das Ticket nicht.
  return jsonb_build_object('valid',true,'reason','Ticket aktiv',
    'ticket',jsonb_build_object('guest_name',t.guest_name,'ticket_number',t.ticket_number,'status',t.status));
end $$;
revoke all on function public.check_project_y_ticket(text) from public;
grant execute on function public.check_project_y_ticket(text) to authenticated;

-- WICHTIG: Benutzer zuerst in Supabase > Authentication > Users anlegen.
-- Danach die UUIDs hier eintragen und Rollen vergeben:
-- insert into public.project_y_profiles(user_id, role) values
-- ('UUID-DES-VERANSTALTERS','admin'),
-- ('UUID-TUERSTEHER-1','bouncer'),
-- ('UUID-TUERSTEHER-2','bouncer');
