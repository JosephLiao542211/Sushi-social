-- ============================================================
-- Location geography fields for the map.
-- The locations table already exists; this migration makes it map-ready.
-- ============================================================

alter table public.locations
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists phone text,
  add column if not exists website text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.locations
  add constraint locations_latitude_range
    check (latitude is null or latitude between -90 and 90),
  add constraint locations_longitude_range
    check (longitude is null or longitude between -180 and 180),
  add constraint locations_coordinates_pair
    check ((latitude is null and longitude is null) or (latitude is not null and longitude is not null));

create index if not exists locations_coordinates_idx
  on public.locations (latitude, longitude)
  where latitude is not null and longitude is not null;

drop trigger if exists locations_touch_updated_at on public.locations;
create trigger locations_touch_updated_at
  before update on public.locations
  for each row execute function public.touch_updated_at();
