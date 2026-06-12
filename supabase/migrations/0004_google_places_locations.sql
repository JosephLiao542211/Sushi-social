-- ============================================================
-- Google Places metadata for seeded sushi locations.
-- ============================================================

alter table public.locations
  add column if not exists google_place_id text,
  add column if not exists formatted_address text,
  add column if not exists rating numeric(2, 1),
  add column if not exists user_rating_count int,
  add column if not exists price_level text,
  add column if not exists business_status text,
  add column if not exists google_maps_uri text,
  add column if not exists primary_type text,
  add column if not exists types text[] not null default '{}',
  add column if not exists opening_hours jsonb,
  add column if not exists google_data jsonb not null default '{}'::jsonb,
  add column if not exists last_google_sync_at timestamptz;

create unique index if not exists locations_google_place_id_idx
  on public.locations (google_place_id);

create index if not exists locations_rating_idx
  on public.locations (rating desc nulls last);

create index if not exists locations_google_sync_idx
  on public.locations (last_google_sync_at);
