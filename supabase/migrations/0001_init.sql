-- ============================================================
-- Sushi Social — initial schema
--
-- Run this once against your Supabase project (SQL Editor or
-- `supabase db push`). It is idempotent-unsafe: designed for a
-- fresh project. Re-running will fail on the CREATE TABLE steps.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- profiles  (one row per auth user)
-- ============================================================
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text unique not null,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now()
);

-- Auto-create a profile whenever a new auth.user is inserted.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_display  text;
begin
  v_username := coalesce(
    nullif(new.raw_user_meta_data->>'username', ''),
    split_part(new.email, '@', 1) || '_' || substr(new.id::text, 1, 4)
  );
  v_display := coalesce(
    nullif(new.raw_user_meta_data->>'display_name', ''),
    nullif(new.raw_user_meta_data->>'username', ''),
    split_part(new.email, '@', 1)
  );
  insert into public.profiles (id, username, display_name)
  values (new.id, v_username, v_display);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- locations  (sushi restaurants — crowdsourced)
-- ============================================================
create table public.locations (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  address    text,
  city       text,
  created_by uuid references public.profiles(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create index locations_name_idx on public.locations (lower(name));

-- ============================================================
-- sessions  (one AYCE event)
-- ============================================================
create or replace function public.generate_join_code()
returns text
language plpgsql
as $$
declare
  -- 32 unambiguous chars (no 0/O/1/I)
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(alphabet, (floor(random() * length(alphabet))::int) + 1, 1);
  end loop;
  return result;
end;
$$;

create table public.sessions (
  id          uuid primary key default gen_random_uuid(),
  host_id     uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  location_id uuid references public.locations(id) on delete set null,
  name        text,
  join_code   text not null unique,
  status      text not null default 'active' check (status in ('active','ended')),
  started_at  timestamptz not null default now(),
  ended_at    timestamptz
);

create index sessions_status_idx    on public.sessions (status);
create index sessions_join_code_idx on public.sessions (join_code);
create index sessions_host_idx      on public.sessions (host_id);

-- Auto-fill join_code on insert with a unique 6-char string.
create or replace function public.set_session_join_code()
returns trigger
language plpgsql
as $$
declare
  candidate text;
  tries int := 0;
begin
  if new.join_code is not null and length(new.join_code) > 0 then
    return new;
  end if;
  loop
    candidate := public.generate_join_code();
    exit when not exists (select 1 from public.sessions where join_code = candidate);
    tries := tries + 1;
    if tries > 10 then
      raise exception 'Could not generate a unique join code';
    end if;
  end loop;
  new.join_code := candidate;
  return new;
end;
$$;

drop trigger if exists sessions_set_join_code on public.sessions;
create trigger sessions_set_join_code
  before insert on public.sessions
  for each row execute function public.set_session_join_code();

-- ============================================================
-- session_participants  (who is in the session + their plate count)
-- ============================================================
create table public.session_participants (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references public.sessions(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  plate_count int  not null default 0 check (plate_count >= 0),
  joined_at   timestamptz not null default now(),
  unique (session_id, user_id)
);

create index session_participants_session_idx on public.session_participants (session_id);
create index session_participants_user_idx    on public.session_participants (user_id);

-- Auto-add the host as a participant when a session is created.
create or replace function public.add_host_as_participant()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.session_participants (session_id, user_id)
  values (new.id, new.host_id)
  on conflict (session_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists sessions_add_host on public.sessions;
create trigger sessions_add_host
  after insert on public.sessions
  for each row execute function public.add_host_as_participant();

-- ============================================================
-- Helper: is the current user a participant of a session?
-- SECURITY DEFINER avoids recursive RLS on session_participants.
-- ============================================================
create or replace function public.is_session_member(p_session_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.session_participants
    where session_id = p_session_id and user_id = auth.uid()
  );
$$;

-- ============================================================
-- RPCs: atomic plate count operations + join by code
-- ============================================================
create or replace function public.increment_my_plate_count(p_session_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new int;
begin
  if not exists (select 1 from public.sessions where id = p_session_id and status = 'active') then
    raise exception 'Session is not active';
  end if;
  update public.session_participants
     set plate_count = plate_count + 1
   where session_id = p_session_id and user_id = auth.uid()
  returning plate_count into v_new;
  if v_new is null then
    raise exception 'You are not a participant of this session';
  end if;
  return v_new;
end;
$$;

create or replace function public.decrement_my_plate_count(p_session_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new int;
begin
  if not exists (select 1 from public.sessions where id = p_session_id and status = 'active') then
    raise exception 'Session is not active';
  end if;
  update public.session_participants
     set plate_count = greatest(plate_count - 1, 0)
   where session_id = p_session_id and user_id = auth.uid()
  returning plate_count into v_new;
  if v_new is null then
    raise exception 'You are not a participant of this session';
  end if;
  return v_new;
end;
$$;

create or replace function public.join_session_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_id uuid;
begin
  select id into v_session_id
    from public.sessions
   where join_code = upper(p_code) and status = 'active';

  if v_session_id is null then
    raise exception 'No active session with that code';
  end if;

  insert into public.session_participants (session_id, user_id)
  values (v_session_id, auth.uid())
  on conflict (session_id, user_id) do nothing;

  return v_session_id;
end;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.profiles             enable row level security;
alter table public.locations            enable row level security;
alter table public.sessions             enable row level security;
alter table public.session_participants enable row level security;

-- profiles: anyone logged in can read; only self can update.
create policy "profiles read"   on public.profiles
  for select to authenticated using (true);
create policy "profiles update" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- locations: anyone logged in can read & add.
create policy "locations read"   on public.locations
  for select to authenticated using (true);
create policy "locations insert" on public.locations
  for insert to authenticated with check (created_by = auth.uid());

-- sessions: host or participants can read; only user can host-create;
-- only host can update/end.
create policy "sessions read" on public.sessions
  for select to authenticated using (
    host_id = auth.uid() or public.is_session_member(id)
  );
create policy "sessions insert" on public.sessions
  for insert to authenticated with check (host_id = auth.uid());
create policy "sessions update host" on public.sessions
  for update to authenticated using (host_id = auth.uid()) with check (host_id = auth.uid());

-- session_participants: members of the same session can see each other's rows;
-- users can insert (join) and delete (leave) only their own row.
-- Plate count is changed only via SECURITY DEFINER RPCs, so no UPDATE policy is given here.
create policy "participants read" on public.session_participants
  for select to authenticated using (
    user_id = auth.uid() or public.is_session_member(session_id)
  );
create policy "participants insert self" on public.session_participants
  for insert to authenticated with check (user_id = auth.uid());
create policy "participants delete self" on public.session_participants
  for delete to authenticated using (user_id = auth.uid());

-- ============================================================
-- Realtime: expose plate-count changes + session status changes
-- ============================================================
alter publication supabase_realtime add table public.session_participants;
alter publication supabase_realtime add table public.sessions;
