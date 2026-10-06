-- Speicher für Tourfotos und GPX-Dateien (SPEC 7): öffentlich lesbar, Tourenleitung/Admins laden hoch/ersetzen/löschen.
insert into storage.buckets (id, name, public)
values ('tour-photos', 'tour-photos', true), ('tour-gpx', 'tour-gpx', true)
on conflict (id) do nothing;

create policy "tour files: staff upload" on storage.objects for insert to authenticated
  with check (bucket_id in ('tour-photos', 'tour-gpx') and (select public.is_staff()));
create policy "tour files: staff update" on storage.objects for update to authenticated
  using (bucket_id in ('tour-photos', 'tour-gpx') and (select public.is_staff()))
  with check (bucket_id in ('tour-photos', 'tour-gpx') and (select public.is_staff()));
create policy "tour files: staff delete" on storage.objects for delete to authenticated
  using (bucket_id in ('tour-photos', 'tour-gpx') and (select public.is_staff()));
