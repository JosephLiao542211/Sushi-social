-- ============================================================
-- Friends + discoverable active friend sessions.
-- ============================================================

create table public.friends (
  id uuid primary key default gen_random_uuid(),
  user_low uuid not null references public.profiles(id) on delete cascade,
  user_high uuid not null references public.profiles(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  check (user_low < user_high),
  unique (user_low, user_high)
);

create index friends_user_low_idx on public.friends (user_low);
create index friends_user_high_idx on public.friends (user_high);

create or replace function public.are_friends(p_user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
      from public.friends f
     where (f.user_low = auth.uid() and f.user_high = p_user_id)
        or (f.user_high = auth.uid() and f.user_low = p_user_id)
  );
$$;

create or replace function public.add_friend_by_username(p_username text)
returns table (
  friend_id uuid,
  username text,
  display_name text,
  avatar_url text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_friend public.profiles%rowtype;
  v_low uuid;
  v_high uuid;
begin
  select *
    into v_friend
    from public.profiles
   where lower(profiles.username) = lower(trim(p_username));

  if v_friend.id is null then
    raise exception 'No user found with that username';
  end if;

  if v_friend.id = auth.uid() then
    raise exception 'You cannot add yourself';
  end if;

  v_low := least(auth.uid(), v_friend.id);
  v_high := greatest(auth.uid(), v_friend.id);

  insert into public.friends (user_low, user_high, requested_by)
  values (v_low, v_high, auth.uid())
  on conflict (user_low, user_high) do nothing;

  return query
  select v_friend.id, v_friend.username, v_friend.display_name, v_friend.avatar_url;
end;
$$;

create or replace function public.my_friends()
returns table (
  friend_id uuid,
  username text,
  display_name text,
  avatar_url text,
  created_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select
    p.id as friend_id,
    p.username,
    p.display_name,
    p.avatar_url,
    f.created_at
  from public.friends f
  join public.profiles p on p.id = case
    when f.user_low = auth.uid() then f.user_high
    else f.user_low
  end
  where f.user_low = auth.uid() or f.user_high = auth.uid()
  order by coalesce(p.display_name, p.username);
$$;

create or replace function public.active_friend_sessions()
returns table (
  session_id uuid,
  session_name text,
  host_id uuid,
  host_username text,
  host_name text,
  host_avatar_url text,
  location_name text,
  started_at timestamptz,
  participant_count int
)
language sql
security definer
stable
set search_path = public
as $$
  select
    s.id as session_id,
    s.name as session_name,
    s.host_id,
    hp.username as host_username,
    coalesce(hp.display_name, hp.username) as host_name,
    hp.avatar_url as host_avatar_url,
    l.name as location_name,
    s.started_at,
    count(sp.user_id)::int as participant_count
  from public.sessions s
  join public.profiles hp on hp.id = s.host_id
  left join public.locations l on l.id = s.location_id
  left join public.session_participants sp on sp.session_id = s.id
  where s.status = 'active'
    and s.host_id <> auth.uid()
    and public.are_friends(s.host_id)
    and not exists (
      select 1
        from public.session_participants mine
       where mine.session_id = s.id and mine.user_id = auth.uid()
    )
  group by s.id, hp.id, l.id
  order by s.started_at desc
  limit 10;
$$;

create or replace function public.join_friend_session(p_session_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_host_id uuid;
begin
  select host_id into v_host_id
    from public.sessions
   where id = p_session_id and status = 'active';

  if v_host_id is null then
    raise exception 'No active session found';
  end if;

  if v_host_id <> auth.uid() and not public.are_friends(v_host_id) then
    raise exception 'You can only join active sessions hosted by friends';
  end if;

  insert into public.session_participants (session_id, user_id)
  values (p_session_id, auth.uid())
  on conflict (session_id, user_id) do nothing;

  return p_session_id;
end;
$$;

alter table public.friends enable row level security;

create policy "friends read own" on public.friends
  for select to authenticated using (
    user_low = auth.uid() or user_high = auth.uid()
  );

create policy "friends insert own" on public.friends
  for insert to authenticated with check (
    requested_by = auth.uid()
    and (user_low = auth.uid() or user_high = auth.uid())
  );

create policy "friends delete own" on public.friends
  for delete to authenticated using (
    user_low = auth.uid() or user_high = auth.uid()
  );

grant select, insert, delete on public.friends to authenticated;
grant execute on function public.add_friend_by_username(text) to authenticated;
grant execute on function public.my_friends() to authenticated;
grant execute on function public.active_friend_sessions() to authenticated;
grant execute on function public.join_friend_session(uuid) to authenticated;
