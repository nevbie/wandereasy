-- Wandern mit den NaturFreunden – Grundschema (SPEC 6) mit Row Level Security.
--
-- Regeln (SPEC 2 und 6):
--   guest (anon)   liest veröffentlichte Touren mit allem Öffentlichen dazu, Gruppenwanderungen
--   member         + an-/abmelden, liest Mitteilungen der Wanderungen, für die er angemeldet ist
--   tour_leader    + Touren anlegen/bearbeiten (nicht freigeben/löschen), eigene Gruppenwanderungen
--                    ausschreiben/absagen, sieht deren Teilnehmende (inkl. Telefonnummer)
--   admin          + Rollen vergeben, Touren freigeben und löschen, alles andere
--
-- Telefonnummern liegen in profile_private statt in profiles (DECISIONS D40): RLS wirkt auf Zeilen;
-- Mitglieder sollen den Namen der Tourenleitung sehen, eine Telefonnummer aber nur die Tourenleitung
-- einer Wanderung, für die sich die Person angemeldet hat.

create extension if not exists postgis with schema extensions;

-- ------------------------------------------------------------------ Typen
create type public.user_role as enum ('member', 'tour_leader', 'admin');
create type public.tour_type as enum ('loop', 'walk_out_ride_back', 'ride_both_ways');
create type public.difficulty as enum ('easy', 'medium', 'hard');
create type public.poi_kind as enum ('wc', 'bench', 'viewpoint', 'shortcut', 'info');
create type public.food_kind as enum ('gasthaus', 'haeckerwirtschaft', 'cafe', 'huette', 'biergarten', 'other');
create type public.food_position as enum ('on_route', 'at_end', 'at_start');
create type public.transit_direction as enum ('to', 'from');
create type public.hike_status as enum ('planned', 'cancelled', 'done');

-- ------------------------------------------------------------------ Personen
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 80),
  role public.user_role not null default 'member',
  created_at timestamptz not null default now()
);

create table public.profile_private (
  id uuid primary key references public.profiles (id) on delete cascade,
  phone text check (phone is null or phone ~ '^\+?[0-9 ]{6,20}$')
);

-- ------------------------------------------------------------------ Orte
create table public.start_points (
  id text primary key,
  name text not null,
  address text,
  location extensions.geometry(Point, 4326), -- null, bis der Verein die Lage bestätigt (SPEC 11)
  nearest_stop_ids text[] not null default '{}',
  walk_min_to_stop jsonb not null default '{}'
);

create table public.stops (
  id text primary key, -- zHV / DHID
  name text not null,
  location extensions.geometry(Point, 4326)
);

create table public.food_places (
  id text primary key,
  name text not null,
  kind public.food_kind not null default 'other',
  phone text,
  website text,
  location extensions.geometry(Point, 4326),
  opening_hours text, -- Syntax wie OSM opening_hours
  rest_days int[] not null default '{}' check (rest_days <@ array[1, 2, 3, 4, 5, 6, 7]),
  -- Jährliche Saison als MM-TT, z. B. Häckerwirtschaft 09-01 … 11-15 (DECISIONS D41)
  season_from text check (season_from ~ '^\d{2}-\d{2}$'),
  season_to text check (season_to ~ '^\d{2}-\d{2}$'),
  osm_id text,
  verified_at date,
  note text,
  is_demo boolean not null default false
);

-- ------------------------------------------------------------------ Touren
create table public.tours (
  id text primary key,
  slug text unique,
  name text not null,
  description text not null default '',
  tour_type public.tour_type not null,
  start_point_ids text[] not null default '{}',
  difficulty public.difficulty not null,
  distance_m int check (distance_m >= 0),
  ascent_m int check (ascent_m >= 0),
  descent_m int check (descent_m >= 0),
  duration_min int check (duration_min >= 0),
  surface_notes text,
  warnings text[] not null default '{}',
  route extensions.geometry(LineString, 4326),
  stop_a_id text references public.stops (id),
  stop_b_id text references public.stops (id),
  has_food boolean not null default false, -- folgt tour_food (Trigger)
  is_demo boolean not null default false,
  published boolean not null default false,
  updated_at timestamptz not null default now(),
  created_by uuid references public.profiles (id) on delete set null,
  constraint ride_both_ways_needs_stops check (
    tour_type <> 'ride_both_ways' or (stop_a_id is not null and stop_b_id is not null and stop_a_id <> stop_b_id)
  ),
  constraint walk_out_needs_stop_b check (tour_type <> 'walk_out_ride_back' or stop_b_id is not null)
);

create table public.tour_elevation (
  tour_id text primary key references public.tours (id) on delete cascade,
  profile jsonb not null -- [{d_m, ele_m}]
);

create table public.pois (
  id bigint generated always as identity primary key,
  tour_id text not null references public.tours (id) on delete cascade,
  kind public.poi_kind not null,
  name text not null,
  note text,
  location extensions.geometry(Point, 4326)
);

create table public.tour_food (
  tour_id text not null references public.tours (id) on delete cascade,
  food_place_id text not null references public.food_places (id) on delete cascade,
  at_km numeric check (at_km >= 0),
  detour_min int check (detour_min >= 0),
  position public.food_position not null,
  primary key (tour_id, food_place_id)
);

create table public.tour_photos (
  id bigint generated always as identity primary key,
  tour_id text not null references public.tours (id) on delete cascade,
  storage_path text not null,
  caption text,
  sort int not null default 0
);

create table public.tour_transit (
  tour_id text not null references public.tours (id) on delete cascade,
  direction public.transit_direction not null,
  stop_id text not null references public.stops (id),
  lines text[] not null default '{}',
  headway_note text,
  walk_min int check (walk_min >= 0),
  note text,
  primary key (tour_id, direction)
);

-- ------------------------------------------------------------------ Gruppenwanderungen
create table public.group_hikes (
  id bigint generated always as identity primary key,
  tour_id text not null references public.tours (id),
  starts_at timestamptz not null,
  meeting_point text not null,
  meeting_location extensions.geometry(Point, 4326),
  leader_id uuid references public.profiles (id) on delete set null,
  max_participants int check (max_participants > 0),
  guest_fee_cents int not null default 0 check (guest_fee_cents >= 0),
  notes text,
  status public.hike_status not null default 'planned'
);

create table public.registrations (
  group_hike_id bigint not null references public.group_hikes (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (group_hike_id, profile_id)
);

create table public.announcements (
  id bigint generated always as identity primary key,
  group_hike_id bigint not null references public.group_hikes (id) on delete cascade,
  author_id uuid references public.profiles (id) on delete set null,
  text text not null check (char_length(text) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index on public.pois (tour_id);
create index on public.tour_photos (tour_id);
create index on public.tour_food (food_place_id);
create index on public.group_hikes (tour_id);
create index on public.group_hikes (leader_id);
create index on public.group_hikes (starts_at);
create index on public.registrations (profile_id);
create index on public.announcements (group_hike_id);
create index on public.tours using gist (route);

-- ------------------------------------------------------------------ Rollen-Hilfsfunktionen
-- security definer: lesen profiles ohne dessen RLS (keine Rekursion).
create function public.my_role() returns public.user_role
language sql stable security definer set search_path = ''
as $$ select role from public.profiles where id = auth.uid() $$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$ select coalesce(public.my_role() = 'admin', false) $$;

create function public.is_staff() returns boolean
language sql stable security definer set search_path = ''
as $$ select coalesce(public.my_role() in ('tour_leader', 'admin'), false) $$;

create function public.leads_hike(hike_id bigint) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.group_hikes where id = hike_id and leader_id = auth.uid()) $$;

create function public.registered_for(hike_id bigint) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.registrations where group_hike_id = hike_id and profile_id = auth.uid())
$$;

-- Anzahl der Anmeldungen, öffentlich (die Liste selbst nicht): „7 von 12 Plätzen belegt“.
create function public.hike_participant_count(hike_id bigint) returns int
language sql stable security definer set search_path = ''
as $$ select count(*)::int from public.registrations where group_hike_id = hike_id $$;

-- ------------------------------------------------------------------ Trigger
-- Neues Konto -> Profil (+ Telefonnummer aus der SMS-Anmeldung).
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(left(new.raw_user_meta_data ->> 'display_name', 80), ''));
  insert into public.profile_private (id, phone) values (new.id, new.phone);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Nur Admins ändern Rollen (den eigenen Anzeigenamen darf jede Person ändern).
create function public.guard_profile_role() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() and auth.uid() is not null then
    raise exception 'only admins can change roles' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger guard_profile_role
  before update on public.profiles
  for each row execute function public.guard_profile_role();

-- Tourenleitung bearbeitet Touren, freigeben dürfen nur Admins (SPEC 2).
create function public.guard_tour() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' and new.published then
      raise exception 'only admins can publish tours' using errcode = '42501';
    end if;
    if tg_op = 'UPDATE' and new.published is distinct from old.published then
      raise exception 'only admins can publish tours' using errcode = '42501';
    end if;
  end if;
  if tg_op = 'INSERT' and new.created_by is null then
    new.created_by := auth.uid();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger guard_tour
  before insert or update on public.tours
  for each row execute function public.guard_tour();

-- tours.has_food folgt tour_food.
create function public.sync_has_food() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  t text := coalesce(new.tour_id, old.tour_id);
begin
  update public.tours
     set has_food = exists (select 1 from public.tour_food where tour_id = t)
   where id = t;
  if tg_op = 'UPDATE' and old.tour_id <> new.tour_id then
    update public.tours
       set has_food = exists (select 1 from public.tour_food where tour_id = old.tour_id)
     where id = old.tour_id;
  end if;
  return null;
end;
$$;

create trigger sync_has_food
  after insert or update or delete on public.tour_food
  for each row execute function public.sync_has_food();

-- Anmeldung nur für geplante, künftige Wanderungen mit freiem Platz (Zeilensperre gegen Gleichzeitigkeit).
create function public.check_registration() returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  h public.group_hikes;
begin
  select * into h from public.group_hikes where id = new.group_hike_id for update;
  if h.status <> 'planned' or h.starts_at <= now() then
    raise exception 'registration is closed for this group hike' using errcode = 'P0001';
  end if;
  if h.max_participants is not null
     and (select count(*) from public.registrations where group_hike_id = h.id) >= h.max_participants then
    raise exception 'this group hike is full' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger check_registration
  before insert on public.registrations
  for each row execute function public.check_registration();

-- ------------------------------------------------------------------ Konto löschen (SPEC 10)
-- Löscht das Konto; Profil, Telefonnummer und Anmeldungen folgen per on delete cascade.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ------------------------------------------------------------------ row level security
alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;
alter table public.start_points enable row level security;
alter table public.stops enable row level security;
alter table public.food_places enable row level security;
alter table public.tours enable row level security;
alter table public.tour_elevation enable row level security;
alter table public.pois enable row level security;
alter table public.tour_food enable row level security;
alter table public.tour_photos enable row level security;
alter table public.tour_transit enable row level security;
alter table public.group_hikes enable row level security;
alter table public.registrations enable row level security;
alter table public.announcements enable row level security;

-- profiles: eigene Zeile, Namen der Tourenleitung, Teilnehmende eigener Wanderungen, Admins alles
create policy "profiles: read" on public.profiles for select to authenticated using (
  id = (select auth.uid())
  or role in ('tour_leader', 'admin')
  or exists (
    select 1 from public.registrations r
    where r.profile_id = profiles.id and public.leads_hike(r.group_hike_id)
  )
  or (select public.is_admin())
);
create policy "profiles: anyone reads staff names" on public.profiles for select to anon
  using (role in ('tour_leader', 'admin'));
create policy "profiles: update own" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "profiles: admins update" on public.profiles for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Telefonnummern: eigene, Tourenleitung einer Wanderung mit Anmeldung der Person, Admins
create policy "profile_private: read" on public.profile_private for select to authenticated using (
  id = (select auth.uid())
  or exists (
    select 1 from public.registrations r
    where r.profile_id = profile_private.id and public.leads_hike(r.group_hike_id)
  )
  or (select public.is_admin())
);
create policy "profile_private: update own" on public.profile_private for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- öffentliche Stammdaten: alle lesen, Tourenleitung/Admins schreiben
create policy "start_points: read" on public.start_points for select to anon, authenticated using (true);
create policy "start_points: staff write" on public.start_points for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "stops: read" on public.stops for select to anon, authenticated using (true);
create policy "stops: staff write" on public.stops for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "food_places: read" on public.food_places for select to anon, authenticated using (true);
create policy "food_places: staff write" on public.food_places for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));

-- tours: veröffentlichte für alle, alle für Tourenleitung/Admins; Admins löschen
create policy "tours: read" on public.tours for select to anon, authenticated
  using (published or (select public.is_staff()));
create policy "tours: staff insert" on public.tours for insert to authenticated
  with check ((select public.is_staff()));
create policy "tours: staff update" on public.tours for update to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "tours: admins delete" on public.tours for delete to authenticated
  using ((select public.is_admin()));

-- Tourdetails: sichtbar, wenn die Tour sichtbar ist (die Unterabfrage läuft durch die tours-Policy)
create policy "tour_elevation: read" on public.tour_elevation for select to anon, authenticated
  using (exists (select 1 from public.tours t where t.id = tour_id));
create policy "tour_elevation: staff write" on public.tour_elevation for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "pois: read" on public.pois for select to anon, authenticated
  using (exists (select 1 from public.tours t where t.id = tour_id));
create policy "pois: staff write" on public.pois for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "tour_food: read" on public.tour_food for select to anon, authenticated
  using (exists (select 1 from public.tours t where t.id = tour_id));
create policy "tour_food: staff write" on public.tour_food for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "tour_photos: read" on public.tour_photos for select to anon, authenticated
  using (exists (select 1 from public.tours t where t.id = tour_id));
create policy "tour_photos: staff write" on public.tour_photos for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));
create policy "tour_transit: read" on public.tour_transit for select to anon, authenticated
  using (exists (select 1 from public.tours t where t.id = tour_id));
create policy "tour_transit: staff write" on public.tour_transit for all to authenticated
  using ((select public.is_staff())) with check ((select public.is_staff()));

-- Gruppenwanderungen: öffentlich; Tourenleitung schreibt aus (als Leitung); Leitung oder Admin ändert/sagt ab
create policy "group_hikes: read" on public.group_hikes for select to anon, authenticated using (true);
create policy "group_hikes: staff insert" on public.group_hikes for insert to authenticated
  with check ((select public.is_staff()) and (leader_id = (select auth.uid()) or (select public.is_admin())));
create policy "group_hikes: leader or admin update" on public.group_hikes for update to authenticated
  using (((select public.is_staff()) and leader_id = (select auth.uid())) or (select public.is_admin()))
  with check (((select public.is_staff()) and leader_id = (select auth.uid())) or (select public.is_admin()));
create policy "group_hikes: admins delete" on public.group_hikes for delete to authenticated
  using ((select public.is_admin()));

-- registrations: eigene Zeilen; Leitung der Wanderung und Admins lesen sie
create policy "registrations: read" on public.registrations for select to authenticated using (
  profile_id = (select auth.uid()) or public.leads_hike(group_hike_id) or (select public.is_admin())
);
create policy "registrations: register self" on public.registrations for insert to authenticated
  with check (profile_id = (select auth.uid()));
create policy "registrations: unregister self" on public.registrations for delete to authenticated
  using (profile_id = (select auth.uid()) or (select public.is_admin()));

-- announcements: Teilnehmende, Leitung und Admins lesen; Leitung oder Admin schreibt
create policy "announcements: read" on public.announcements for select to authenticated using (
  public.registered_for(group_hike_id) or public.leads_hike(group_hike_id) or (select public.is_admin())
);
create policy "announcements: leader writes" on public.announcements for insert to authenticated with check (
  author_id = (select auth.uid()) and (public.leads_hike(group_hike_id) or (select public.is_admin()))
);
create policy "announcements: admins delete" on public.announcements for delete to authenticated
  using ((select public.is_admin()));
