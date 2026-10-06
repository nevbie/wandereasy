-- Row Level Security (SPEC 2 + 6). Ausführen mit `supabase test db` oder tools/supabase_local/test.sh.
begin;
create extension if not exists pgtap with schema extensions;
select plan(42);

-- ------------------------------------------------------------------ Testdaten (als postgres)
insert into auth.users (id, phone, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', '+491700000001', '{"display_name": "Ada Admin"}'),
  ('00000000-0000-0000-0000-00000000000b', '+491700000002', '{"display_name": "Lea Leitung"}'),
  ('00000000-0000-0000-0000-00000000000c', '+491700000003', '{"display_name": "Leo Leitung"}'),
  ('00000000-0000-0000-0000-00000000000d', '+491700000004', '{"display_name": "Mia Mitglied"}'),
  ('00000000-0000-0000-0000-00000000000e', '+491700000005', '{"display_name": "Max Mitglied"}');
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-00000000000a';
update public.profiles set role = 'tour_leader'
  where id in ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000c');

insert into public.tours (id, name, tour_type, difficulty, published)
  values ('secret_draft', 'Entwurf', 'loop', 'easy', false);
insert into public.pois (tour_id, kind, name) values ('secret_draft', 'bench', 'Bank im Entwurf');

-- Wanderung 1: Leitung Lea, 2 Plätze; Wanderung 2: abgesagt; Wanderung 3: Leitung Leo
insert into public.group_hikes (id, tour_id, starts_at, meeting_point, leader_id, max_participants, status)
overriding system value values
  (1, 'demo_loop', now() + interval '7 days', 'Bahnhof', '00000000-0000-0000-0000-00000000000b', 2, 'planned'),
  (2, 'demo_loop', now() + interval '7 days', 'Bahnhof', '00000000-0000-0000-0000-00000000000b', 10, 'cancelled'),
  (3, 'demo_loop', now() + interval '14 days', 'Bahnhof', '00000000-0000-0000-0000-00000000000c', 10, 'planned');

create function pg_temp.login(uid text) returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.anon() returns void language plpgsql as $$
begin
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', '{"role": "anon"}', true);
end $$;

-- ------------------------------------------------------------------ Gäste
select pg_temp.anon();
select is((select count(*)::int from public.tours where id = 'secret_draft'), 0, 'Gast sieht keine unveröffentlichten Touren');
select ok((select count(*) from public.tours where published) >= 3, 'Gast sieht die veröffentlichten Demo-Touren');
select is((select count(*)::int from public.pois where tour_id = 'secret_draft'), 0, 'Gast sieht keine POIs unveröffentlichter Touren');
select ok((select count(*) from public.pois where tour_id = 'demo_loop') > 0, 'Gast sieht POIs veröffentlichter Touren');
select is((select count(*)::int from public.group_hikes), 3, 'Gast sieht Gruppenwanderungen');
select is((select count(*)::int from public.registrations), 0, 'Gast sieht keine Anmeldungen');
select is((select count(*)::int from public.profile_private), 0, 'Gast sieht keine Telefonnummern');
select throws_ok($$ insert into public.tours (id, name, tour_type, difficulty) values ('x', 'x', 'loop', 'easy') $$,
  '42501', null, 'Gast kann keine Touren anlegen');
select throws_ok($$ select public.delete_my_account() $$, '42501', null, 'Gast kann delete_my_account nicht aufrufen');
reset role;

-- ------------------------------------------------------------------ Mitglieder
select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is((select count(*)::int from public.tours where id = 'secret_draft'), 0, 'Mitglied sieht keine unveröffentlichten Touren');
select throws_ok($$ insert into public.tours (id, name, tour_type, difficulty) values ('x', 'x', 'loop', 'easy') $$,
  '42501', null, 'Mitglied kann keine Touren anlegen');
select lives_ok($$ insert into public.registrations (group_hike_id, profile_id)
  values (1, '00000000-0000-0000-0000-00000000000d') $$, 'Mitglied meldet sich an');
select throws_ok($$ insert into public.registrations (group_hike_id, profile_id)
  values (3, '00000000-0000-0000-0000-00000000000e') $$, '42501', null, 'Mitglied kann niemand anderen anmelden');
select throws_ok($$ insert into public.registrations (group_hike_id, profile_id)
  values (2, '00000000-0000-0000-0000-00000000000d') $$, 'P0001', null, 'keine Anmeldung zu abgesagter Wanderung');
select throws_ok($$ update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-00000000000d' $$,
  '42501', null, 'Mitglied kann sich nicht selbst zum Admin machen');
select lives_ok($$ update public.profiles set display_name = 'Mia M.' where id = '00000000-0000-0000-0000-00000000000d' $$,
  'Mitglied ändert den eigenen Anzeigenamen');
select is((select phone from public.profile_private where id = '00000000-0000-0000-0000-00000000000d'),
  '+491700000004', 'Mitglied sieht die eigene Telefonnummer');
select is((select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-00000000000e'), 0,
  'Mitglied sieht keine anderen Mitglieder');
select is((select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000b'), 'Lea Leitung',
  'Mitglied sieht die Namen der Tourenleitung');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000000e');
select lives_ok($$ insert into public.registrations (group_hike_id, profile_id)
  values (1, '00000000-0000-0000-0000-00000000000e') $$, 'zweites Mitglied bekommt den letzten Platz');
select is((select count(*)::int from public.registrations), 1, 'Mitglied sieht nur eigene Anmeldungen');
select is((select public.hike_participant_count(1)), 2, 'Anzahl der Anmeldungen ist sichtbar');
select is((select count(*)::int from public.profile_private where id = '00000000-0000-0000-0000-00000000000d'), 0,
  'Mitglied sieht keine fremden Telefonnummern');
reset role;

-- ------------------------------------------------------------------ Tourenleitung
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.tours where id = 'secret_draft'), 1, 'Tourenleitung sieht unveröffentlichte Touren');
select lives_ok($$ insert into public.tours (id, name, tour_type, difficulty) values ('lea_tour', 'Leas Tour', 'loop', 'medium') $$,
  'Tourenleitung legt eine Tour an');
select throws_ok($$ update public.tours set published = true where id = 'lea_tour' $$,
  '42501', null, 'Tourenleitung kann nicht freigeben');
select is((select created_by::text from public.tours where id = 'lea_tour'), '00000000-0000-0000-0000-00000000000b',
  'created_by wird gesetzt');
delete from public.tours where id = 'lea_tour';
select is((select count(*)::int from public.tours where id = 'lea_tour'), 1, 'Tourenleitung kann keine Touren löschen');
select is((select count(*)::int from public.registrations where group_hike_id = 1), 2, 'Leitung sieht Teilnehmende der eigenen Wanderung');
select is((select count(*)::int from public.profile_private where id = '00000000-0000-0000-0000-00000000000d'), 1,
  'Leitung sieht Telefonnummern eigener Teilnehmender');
select lives_ok($$ insert into public.announcements (group_hike_id, author_id, text)
  values (1, '00000000-0000-0000-0000-00000000000b', 'Treffpunkt 9 Uhr') $$, 'Leitung sendet eine Mitteilung');
select lives_ok($$ insert into public.tour_food (tour_id, food_place_id, position) values ('lea_tour', 'demo_cafe', 'at_end') $$,
  'Tourenleitung ergänzt eine Einkehr');
select is((select has_food from public.tours where id = 'lea_tour'), true, 'has_food folgt tour_food');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000000c');
select is((select count(*)::int from public.registrations where group_hike_id = 1), 0, 'andere Leitung sieht keine Teilnehmenden');
select is((select count(*)::int from public.profile_private where id = '00000000-0000-0000-0000-00000000000d'), 0,
  'andere Leitung sieht keine Telefonnummern');
select throws_ok($$ insert into public.announcements (group_hike_id, author_id, text)
  values (1, '00000000-0000-0000-0000-00000000000c', 'Hallo') $$, '42501', null, 'andere Leitung kann nicht an fremde Wanderung schreiben');
reset role;

-- volle Wanderung
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select throws_ok($$ insert into public.registrations (group_hike_id, profile_id)
  values (1, '00000000-0000-0000-0000-00000000000a') $$, 'P0001', null, 'keine Anmeldung, wenn die Wanderung voll ist');

-- ------------------------------------------------------------------ Admins
select lives_ok($$ update public.tours set published = true where id = 'lea_tour' $$, 'Admin gibt eine Tour frei');
select lives_ok($$ update public.profiles set role = 'tour_leader' where id = '00000000-0000-0000-0000-00000000000e' $$,
  'Admin vergibt Rollen');
reset role;

-- ------------------------------------------------------------------ Mitteilungen, Konto löschen
select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is((select count(*)::int from public.announcements where group_hike_id = 1), 1, 'Teilnehmende lesen Mitteilungen');
select lives_ok($$ select public.delete_my_account() $$, 'Mitglied löscht das eigene Konto');
reset role;
select is((select count(*)::int from public.registrations where profile_id = '00000000-0000-0000-0000-00000000000d'), 0,
  'Konto löschen entfernt Anmeldungen');

select * from finish();
rollback;
