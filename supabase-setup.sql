-- Vidfluencer creator onboarding schema
-- Run this in the Supabase SQL Editor after creating a project.
-- Creator files stay private in two buckets, under <auth user id>/<file name>.

create extension if not exists pgcrypto;

create table if not exists public.creator_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  contact_method text not null check (contact_method in ('email', 'phone')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.creator_profiles enable row level security;
drop policy if exists "Creators can read their own profile" on public.creator_profiles;
create policy "Creators can read their own profile"
  on public.creator_profiles for select to authenticated
  using (id = (select auth.uid()));
drop policy if exists "Creators can create their own profile" on public.creator_profiles;
create policy "Creators can create their own profile"
  on public.creator_profiles for insert to authenticated
  with check (id = (select auth.uid()));
drop policy if exists "Creators can update their own profile" on public.creator_profiles;
create policy "Creators can update their own profile"
  on public.creator_profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create table if not exists public.creator_contracts (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  agreement_version text not null,
  signer_name text not null,
  signed_at timestamptz not null,
  storage_path text not null unique,
  created_at timestamptz not null default now(),
  constraint creator_contracts_storage_owner check (
    split_part(storage_path, '/', 1) = creator_id::text
  )
);

alter table public.creator_contracts enable row level security;
drop policy if exists "Creators can read their own agreements" on public.creator_contracts;
create policy "Creators can read their own agreements"
  on public.creator_contracts for select to authenticated
  using (creator_id = (select auth.uid()));
drop policy if exists "Creators can save their own agreements" on public.creator_contracts;
create policy "Creators can save their own agreements"
  on public.creator_contracts for insert to authenticated
  with check (creator_id = (select auth.uid()));

create table if not exists public.creator_portfolios (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  portfolio_url text,
  storage_path text,
  file_name text,
  content_type text,
  file_size_bytes bigint,
  created_at timestamptz not null default now(),
  constraint creator_portfolios_has_submission check (
    portfolio_url is not null or storage_path is not null
  ),
  constraint creator_portfolios_storage_owner check (
    storage_path is null or split_part(storage_path, '/', 1) = creator_id::text
  )
);

-- Keep these tables private to signed-in creators. Grants control API reachability;
-- the row-level policies below restrict each creator to their own records.
revoke all privileges on table public.creator_profiles, public.creator_contracts, public.creator_portfolios
  from anon, authenticated;
grant select, insert, update on table public.creator_profiles to authenticated;
grant select, insert on table public.creator_contracts to authenticated;
grant select, insert, update, delete on table public.creator_portfolios to authenticated;

alter table public.creator_portfolios enable row level security;
drop policy if exists "Creators can read their own portfolios" on public.creator_portfolios;
create policy "Creators can read their own portfolios"
  on public.creator_portfolios for select to authenticated
  using (creator_id = (select auth.uid()));
drop policy if exists "Creators can submit their own portfolios" on public.creator_portfolios;
create policy "Creators can submit their own portfolios"
  on public.creator_portfolios for insert to authenticated
  with check (creator_id = (select auth.uid()));
drop policy if exists "Creators can update their own portfolios" on public.creator_portfolios;
create policy "Creators can update their own portfolios"
  on public.creator_portfolios for update to authenticated
  using (creator_id = (select auth.uid()))
  with check (creator_id = (select auth.uid()));
drop policy if exists "Creators can remove their own portfolios" on public.creator_portfolios;
create policy "Creators can remove their own portfolios"
  on public.creator_portfolios for delete to authenticated
  using (creator_id = (select auth.uid()));

-- Private, creator-specific folders in separate buckets:
-- creator-contracts/<auth.uid()>/<unique agreement copy>
-- creator-portfolios/<auth.uid()>/<unique portfolio file>
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'creator-contracts',
  'creator-contracts',
  false,
  104857600,
  array['text/plain','application/pdf']
)
on conflict (id) do update set
  name = excluded.name,
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'creator-portfolios',
  'creator-portfolios',
  false,
  104857600,
  array['application/pdf','image/jpeg','image/png','image/webp','video/mp4','video/quicktime']
)
on conflict (id) do update set
  name = excluded.name,
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Creators can read their own agreement files" on storage.objects;
create policy "Creators can read their own agreement files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'creator-contracts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Creators can upload their own agreement files" on storage.objects;
create policy "Creators can upload their own agreement files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'creator-contracts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Creators can read their own portfolio files" on storage.objects;
create policy "Creators can read their own portfolio files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'creator-portfolios'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Creators can upload their own portfolio files" on storage.objects;
create policy "Creators can upload their own portfolio files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'creator-portfolios'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Creators can update their own portfolio files" on storage.objects;
create policy "Creators can update their own portfolio files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'creator-portfolios'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'creator-portfolios'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
drop policy if exists "Creators can remove their own portfolio files" on storage.objects;
create policy "Creators can remove their own portfolio files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'creator-portfolios'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );