-- Vidfluencer creator filters, profiles, USD earnings and secure application review.
-- Run in Supabase SQL Editor after the existing Vidfluencer setup scripts.
-- Existing campaigns and application records are preserved.
begin;

alter table public.creator_profiles
  add column if not exists profile_picture_source text not null default 'initials',
  add column if not exists profile_picture_path text,
  add column if not exists social_links jsonb not null default '[]'::jsonb;

do $$ begin
  if not exists (select 1 from pg_constraint where conname='creator_profiles_picture_source_check') then
    alter table public.creator_profiles add constraint creator_profiles_picture_source_check check (profile_picture_source in ('initials','google','azure','discord','upload'));
  end if;
  if not exists (select 1 from pg_constraint where conname='creator_profiles_picture_owner_path_check') then
    alter table public.creator_profiles add constraint creator_profiles_picture_owner_path_check check (profile_picture_path is null or split_part(profile_picture_path,'/',1)=id::text);
  end if;
  if not exists (select 1 from pg_constraint where conname='creator_profiles_social_links_array_check') then
    alter table public.creator_profiles add constraint creator_profiles_social_links_array_check check (jsonb_typeof(social_links)='array');
  end if;
end $$;
grant insert(profile_picture_source,profile_picture_path,social_links) on public.creator_profiles to authenticated;
grant update(profile_picture_source,profile_picture_path,social_links) on public.creator_profiles to authenticated;
drop trigger if exists creator_profiles_updated_at on public.creator_profiles;
create trigger creator_profiles_updated_at before update on public.creator_profiles for each row execute function public.set_updated_at();

create table if not exists public.campaign_filter_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 60),
  display_order integer not null default 0,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists campaign_filter_categories_name_unique on public.campaign_filter_categories (lower(btrim(name)));
create table if not exists public.campaign_filter_options (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.campaign_filter_categories(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 60),
  display_order integer not null default 0,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists campaign_filter_options_name_unique on public.campaign_filter_options (category_id, lower(btrim(name)));
create index if not exists campaign_filter_options_order_idx on public.campaign_filter_options (category_id, display_order, name);
create table if not exists public.campaign_category_assignments (
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  option_id uuid not null references public.campaign_filter_options(id) on delete cascade,
  created_at timestamptz not null default now(), primary key (campaign_id, option_id)
);
create index if not exists campaign_category_assignments_option_idx on public.campaign_category_assignments (option_id, campaign_id);

alter table public.campaign_filter_categories enable row level security;
alter table public.campaign_filter_options enable row level security;
alter table public.campaign_category_assignments enable row level security;
drop policy if exists "Signed-in users can read campaign filter categories" on public.campaign_filter_categories;
create policy "Signed-in users can read campaign filter categories" on public.campaign_filter_categories for select to authenticated using ((select auth.uid()) is not null);
drop policy if exists "Admins manage campaign filter categories" on public.campaign_filter_categories;
create policy "Admins manage campaign filter categories" on public.campaign_filter_categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Signed-in users can read campaign filter options" on public.campaign_filter_options;
create policy "Signed-in users can read campaign filter options" on public.campaign_filter_options for select to authenticated using ((select auth.uid()) is not null);
drop policy if exists "Admins manage campaign filter options" on public.campaign_filter_options;
create policy "Admins manage campaign filter options" on public.campaign_filter_options for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Signed-in users can read campaign category assignments" on public.campaign_category_assignments;
create policy "Signed-in users can read campaign category assignments" on public.campaign_category_assignments for select to authenticated using ((select auth.uid()) is not null);
drop policy if exists "Admins manage campaign category assignments" on public.campaign_category_assignments;
create policy "Admins manage campaign category assignments" on public.campaign_category_assignments for all to authenticated using (public.is_admin()) with check (public.is_admin());
revoke all on public.campaign_filter_categories, public.campaign_filter_options, public.campaign_category_assignments from anon, authenticated;
grant select on public.campaign_filter_categories, public.campaign_filter_options, public.campaign_category_assignments to authenticated;
grant insert, update, delete on public.campaign_filter_categories, public.campaign_filter_options to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('creator-avatars','creator-avatars',false,2097152,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=2097152,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Creators read their own avatar files" on storage.objects;
create policy "Creators read their own avatar files" on storage.objects for select to authenticated using (bucket_id='creator-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Creators upload their own avatar files" on storage.objects;
create policy "Creators upload their own avatar files" on storage.objects for insert to authenticated with check (bucket_id='creator-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Creators update their own avatar files" on storage.objects;
create policy "Creators update their own avatar files" on storage.objects for update to authenticated using (bucket_id='creator-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text) with check (bucket_id='creator-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Creators remove their own avatar files" on storage.objects;
create policy "Creators remove their own avatar files" on storage.objects for delete to authenticated using (bucket_id='creator-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);

create table if not exists public.creator_earnings (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references auth.users(id) on delete set null,
  application_id uuid unique references public.campaign_applications(id) on delete set null,
  campaign_id uuid references public.campaigns(id) on delete set null,
  campaign_title_snapshot text not null,
  creator_name_snapshot text, creator_email_snapshot text,
  amount_usd numeric(12,2) not null check (amount_usd > 0),
  currency text not null default 'USD' check (currency='USD'),
  status text not null default 'pending' check (status in ('pending','paid','cancelled')),
  created_at timestamptz not null default now(), paid_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint creator_earnings_paid_at_check check ((status='paid')=(paid_at is not null))
);
create index if not exists creator_earnings_creator_status_idx on public.creator_earnings (creator_id,status,created_at desc);
create index if not exists creator_earnings_status_created_idx on public.creator_earnings (status,created_at desc);
alter table public.creator_earnings enable row level security;
drop policy if exists "Creators and admins can read permitted earnings" on public.creator_earnings;
create policy "Creators and admins can read permitted earnings" on public.creator_earnings for select to authenticated using (creator_id=(select auth.uid()) or public.is_admin());
revoke all on public.creator_earnings from anon, authenticated;
grant select on public.creator_earnings to authenticated;

create or replace function public.admin_review_campaign_application(p_application_id uuid,p_status text,p_amount numeric default null)
returns void language plpgsql security definer set search_path=''
as $$
declare v_app public.campaign_applications%rowtype; v_campaign_title text; v_creator_name text; v_creator_email text; v_existing_status text; v_existing_amount numeric;
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  if p_status is null or p_status not in ('pending','approved','rejected') then raise exception 'Choose a valid application status'; end if;
  if p_status='approved' and (p_amount is null or p_amount <= 0) then raise exception 'Enter a positive USD amount before approving'; end if;
  select * into v_app from public.campaign_applications where id=p_application_id for update;
  if not found then raise exception 'Application not found'; end if;
  if v_app.withdrawn_at is not null and p_status='approved' then raise exception 'A withdrawn application cannot be approved'; end if;
  select c.title into v_campaign_title from public.campaigns c where c.id=v_app.campaign_id;
  select p.full_name,u.email into v_creator_name,v_creator_email from auth.users u left join public.creator_profiles p on p.id=u.id where u.id=v_app.creator_id;
  select e.status,e.amount_usd into v_existing_status,v_existing_amount from public.creator_earnings e where e.application_id=p_application_id for update;
  if v_existing_status='paid' and (p_status<>'approved' or p_amount is distinct from v_existing_amount) then raise exception 'A paid earning cannot be changed; contact an owner to correct a payment record'; end if;
  update public.campaign_applications set status=p_status,updated_at=now() where id=p_application_id;
  if p_status='approved' then
    insert into public.creator_earnings(creator_id,application_id,campaign_id,campaign_title_snapshot,creator_name_snapshot,creator_email_snapshot,amount_usd,currency,status,paid_at,updated_at)
    values(v_app.creator_id,p_application_id,v_app.campaign_id,coalesce(v_campaign_title,'Campaign'),v_creator_name,v_creator_email,round(p_amount,2),'USD','pending',null,now())
    on conflict(application_id) do update set creator_id=excluded.creator_id,campaign_id=excluded.campaign_id,campaign_title_snapshot=excluded.campaign_title_snapshot,
      creator_name_snapshot=excluded.creator_name_snapshot,creator_email_snapshot=excluded.creator_email_snapshot,amount_usd=excluded.amount_usd,currency='USD',status='pending',paid_at=null,updated_at=now()
    where public.creator_earnings.status<>'paid';
  else
    update public.creator_earnings set status='cancelled',paid_at=null,updated_at=now() where application_id=p_application_id and status='pending';
  end if;
  if p_status<>'pending' then update public.admin_notifications set read_at=now() where admin_id=(select auth.uid()) and notification_type='campaign_application' and application_id=p_application_id and read_at is null; end if;
  insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary,reason)
  values((select auth.uid()),'application_status','campaign_application',p_application_id::text,jsonb_build_object('status',v_app.status),
    jsonb_build_object('status',p_status,'amountUsd',case when p_status='approved' then round(p_amount,2) else null end),case when p_status='approved' then 'USD earning recorded' else 'Application reviewed' end);
end;
$$;

create or replace function public.admin_set_campaign_filter_options(p_campaign_id uuid,p_option_ids uuid[])
returns void language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  if not exists(select 1 from public.campaigns where id=p_campaign_id) then raise exception 'Campaign not found'; end if;
  if coalesce(array_length(p_option_ids,1),0)>0 and exists(select 1 from unnest(p_option_ids) selected(id) left join public.campaign_filter_options o on o.id=selected.id where o.id is null) then raise exception 'One or more filter options no longer exist'; end if;
  delete from public.campaign_category_assignments where campaign_id=p_campaign_id;
  insert into public.campaign_category_assignments(campaign_id,option_id) select p_campaign_id,selected.id from (select distinct unnest(coalesce(p_option_ids,'{}'::uuid[])) as id) selected;
  insert into public.admin_audit_log(admin_id,action,target_type,target_id,after_summary,reason)
    values((select auth.uid()),'campaign_filters_update','campaign',p_campaign_id::text,jsonb_build_object('optionIds',to_jsonb(coalesce(p_option_ids,'{}'::uuid[]))),'Campaign filter options updated');
end;
$$;

create or replace function public.admin_list_earnings()
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'creatorId',e.creator_id,'creatorName',e.creator_name_snapshot,'creatorEmail',e.creator_email_snapshot,
    'campaignId',e.campaign_id,'campaignTitle',e.campaign_title_snapshot,'amountUsd',e.amount_usd,'status',e.status,'createdAt',e.created_at,'paidAt',e.paid_at) order by e.created_at desc)
    from public.creator_earnings e),'[]'::jsonb);
end;
$$;

create or replace function public.admin_mark_earning_paid(p_earning_id uuid)
returns void language plpgsql security definer set search_path=''
as $$
declare v_row public.creator_earnings%rowtype;
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  select * into v_row from public.creator_earnings where id=p_earning_id for update;
  if not found then raise exception 'Earning not found'; end if;
  if v_row.status<>'pending' then raise exception 'Only a pending earning can be marked paid'; end if;
  update public.creator_earnings set status='paid',paid_at=now(),updated_at=now() where id=p_earning_id;
  insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary,reason)
    values((select auth.uid()),'earning_paid','creator_earning',p_earning_id::text,jsonb_build_object('status','pending'),jsonb_build_object('status','paid','paidAt',now(),'amountUsd',v_row.amount_usd),'Payment marked as paid');
end;
$$;

create or replace function public.admin_campaign_applications(p_campaign_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'campaignId',a.campaign_id,'campaignTitle',c.title,'creatorId',a.creator_id,'name',p.full_name,'email',u.email,
    'pitch',a.pitch,'status',a.status,'createdAt',a.created_at,'withdrawnAt',a.withdrawn_at,
    'earningAmount',(select e.amount_usd from public.creator_earnings e where e.application_id=a.id and e.status in ('pending','paid')),
    'earningStatus',(select e.status from public.creator_earnings e where e.application_id=a.id)) order by a.created_at desc)
    from public.campaign_applications a join public.campaigns c on c.id=a.campaign_id join auth.users u on u.id=a.creator_id left join public.creator_profiles p on p.id=a.creator_id
    where p_campaign_id is null or a.campaign_id=p_campaign_id),'[]'::jsonb);
end;
$$;

drop function if exists public.admin_set_application_status(uuid,text);
revoke all on function public.admin_review_campaign_application(uuid,text,numeric),public.admin_set_campaign_filter_options(uuid,uuid[]),public.admin_list_earnings(),public.admin_mark_earning_paid(uuid) from public,anon;
grant execute on function public.admin_review_campaign_application(uuid,text,numeric),public.admin_set_campaign_filter_options(uuid,uuid[]),public.admin_list_earnings(),public.admin_mark_earning_paid(uuid) to authenticated;
revoke all on function public.admin_campaign_applications(uuid) from public,anon;
grant execute on function public.admin_campaign_applications(uuid) to authenticated;

commit;
