-- ============================================================
-- Social feed: posts, likes, and comments.
--
-- Photo bytes live in Google Cloud Storage. Supabase stores only
-- the public/signed object URL and stable object metadata.
-- ============================================================

create table public.posts (
  id                  uuid primary key default gen_random_uuid(),
  author_id           uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  location_id         uuid references public.locations(id) on delete set null,
  session_id          uuid references public.sessions(id) on delete set null,
  photo_url           text not null,
  photo_storage       text not null default 'google_cloud_storage'
                        check (photo_storage in ('google_cloud_storage')),
  photo_bucket        text,
  photo_object_path   text,
  caption             text not null default '',
  plate_count         int not null default 0 check (plate_count >= 0),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index posts_author_idx     on public.posts (author_id);
create index posts_location_idx   on public.posts (location_id);
create index posts_created_at_idx on public.posts (created_at desc);

create table public.post_likes (
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index post_likes_user_idx on public.post_likes (user_id);

create table public.post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  author_id  uuid not null references public.profiles(id) on delete cascade default auth.uid(),
  body       text not null check (length(trim(body)) between 1 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index post_comments_post_idx       on public.post_comments (post_id, created_at);
create index post_comments_author_idx     on public.post_comments (author_id);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger posts_touch_updated_at
  before update on public.posts
  for each row execute function public.touch_updated_at();

create trigger post_comments_touch_updated_at
  before update on public.post_comments
  for each row execute function public.touch_updated_at();

create or replace view public.feed_posts
with (security_invoker = true)
as
select
  p.id,
  p.author_id,
  p.location_id,
  p.session_id,
  p.photo_url,
  p.photo_storage,
  p.photo_bucket,
  p.photo_object_path,
  p.caption,
  p.plate_count,
  p.created_at,
  p.updated_at,
  coalesce(pr.display_name, pr.username) as author_name,
  pr.username as author_username,
  pr.avatar_url as author_avatar_url,
  l.name as location_name,
  count(distinct pl.user_id)::int as like_count,
  count(distinct pc.id)::int as comment_count,
  bool_or(pl.user_id = auth.uid()) as liked_by_me
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join public.locations l on l.id = p.location_id
left join public.post_likes pl on pl.post_id = p.id
left join public.post_comments pc on pc.post_id = p.id
group by p.id, pr.id, l.id;

alter table public.posts         enable row level security;
alter table public.post_likes    enable row level security;
alter table public.post_comments enable row level security;

create policy "posts read" on public.posts
  for select to authenticated using (true);

create policy "posts insert own" on public.posts
  for insert to authenticated with check (author_id = auth.uid());

create policy "posts update own" on public.posts
  for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());

create policy "posts delete own" on public.posts
  for delete to authenticated using (author_id = auth.uid());

create policy "likes read" on public.post_likes
  for select to authenticated using (true);

create policy "likes insert own" on public.post_likes
  for insert to authenticated with check (user_id = auth.uid());

create policy "likes delete own" on public.post_likes
  for delete to authenticated using (user_id = auth.uid());

create policy "comments read" on public.post_comments
  for select to authenticated using (true);

create policy "comments insert own" on public.post_comments
  for insert to authenticated with check (author_id = auth.uid());

create policy "comments update own" on public.post_comments
  for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());

create policy "comments delete own" on public.post_comments
  for delete to authenticated using (author_id = auth.uid());

grant select on public.feed_posts to authenticated;
grant select, insert, update, delete on public.posts to authenticated;
grant select, insert, delete on public.post_likes to authenticated;
grant select, insert, update, delete on public.post_comments to authenticated;

alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.post_likes;
alter publication supabase_realtime add table public.post_comments;
