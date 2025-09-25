alter table public.thoughts_meta enable row level security;

create policy "Users can CRUD their own thoughts"
on public.thoughts_meta
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can upload to their folder"
on storage.objects
for insert
with check (
  bucket_id = 'thoughts'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users can read own objects"
on storage.objects
for select
using (
  bucket_id = 'thoughts'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users can delete their objects"
on storage.objects
for delete
using (
  bucket_id = 'thoughts'
  and auth.uid()::text = (storage.foldername(name))[1]
);
