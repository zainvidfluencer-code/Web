-- Vidfluencer approvals, campaigns and admin area. Apply after supabase-setup.sql.
-- Idempotent; all admin data and actions require TOTP AAL2. No service key belongs in the website.
begin;
create extension if not exists pgcrypto;
alter table public.creator_profiles
 add column if not exists legal_name text, add column if not exists creator_name text, add column if not exists contact_email text,
 add column if not exists address text, add column if not exists country text, add column if not exists social_handles text,
 add column if not exists paypal_email text, add column if not exists vat_number text, add column if not exists age_confirmation text,
 add column if not exists guardian_name text, add column if not exists guardian_signature text, add column if not exists payment_method text,
 add column if not exists payout_details text, add column if not exists account_status text not null default 'active',
 add column if not exists review_note text, add column if not exists reviewed_by uuid references auth.users(id) on delete set null,
 add column if not exists reviewed_at timestamptz, add column if not exists needs_portfolio_update boolean not null default false;
alter table public.creator_contracts
 add column if not exists contract_status text not null default 'pending', add column if not exists review_note text,
 add column if not exists reviewed_by uuid references auth.users(id) on delete set null, add column if not exists reviewed_at timestamptz,
 add column if not exists pdf_storage_path text;
alter table public.creator_portfolios
 add column if not exists portfolio_status text not null default 'pending', add column if not exists review_note text,
 add column if not exists reviewed_by uuid references auth.users(id) on delete set null, add column if not exists reviewed_at timestamptz;
do $$ begin
 if not exists(select 1 from pg_constraint where conname='creator_contracts_pdf_owner_path_check') then
  alter table public.creator_contracts add constraint creator_contracts_pdf_owner_path_check check(pdf_storage_path is null or split_part(pdf_storage_path,'/',1)=creator_id::text);
 end if;
end $$;
do $$ begin
 if not exists(select 1 from pg_constraint where conname='creator_profiles_account_status_check') then
  alter table public.creator_profiles add constraint creator_profiles_account_status_check check(account_status in('active','rejected','suspended'));
 end if;
 if not exists(select 1 from pg_constraint where conname='creator_contracts_contract_status_check') then
  alter table public.creator_contracts add constraint creator_contracts_contract_status_check check(contract_status in('pending','approved','rejected'));
 end if;
 if not exists(select 1 from pg_constraint where conname='creator_portfolios_portfolio_status_check') then
  alter table public.creator_portfolios add constraint creator_portfolios_portfolio_status_check check(portfolio_status in('pending','approved','rejected'));
 end if;
end $$;
create table if not exists public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade,role text not null check(role in('owner','moderator')),created_at timestamptz not null default now());
create table if not exists public.admin_audit_log(id bigint generated always as identity primary key,admin_id uuid references auth.users(id) on delete set null,action text not null,target_type text not null,target_id text,before_summary jsonb,after_summary jsonb,reason text,created_at timestamptz not null default now());
create table if not exists public.campaigns(
 id uuid primary key default gen_random_uuid(),title text not null,brand_name text not null,thumbnail_path text,thumbnail_alt text,
 short_description text not null default '',description text not null default '',category text not null default 'Other',
 platforms text[] not null default '{}',payout_text text not null default 'Rate on request',deliverables text not null default '',
 requirements text not null default '',usage_rights text not null default '',deadline date,
 status text not null default 'draft' check(status in('draft','published','archived')),featured boolean not null default false,
 display_order integer not null default 0,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id) on delete set null,
 constraint campaigns_short_description_length check(char_length(short_description)<=140),
 constraint campaigns_thumbnail_alt_required check(thumbnail_path is null or nullif(btrim(thumbnail_alt),'') is not null),
 constraint campaigns_thumbnail_path_safe check(thumbnail_path is null or (thumbnail_path !~ '(^/|\.\.|\\)' and thumbnail_path !~ '^https?://')));
create table if not exists public.campaign_applications(
 id uuid primary key default gen_random_uuid(),campaign_id uuid not null references public.campaigns(id) on delete cascade,
 creator_id uuid not null references auth.users(id) on delete cascade,pitch text not null default '',
 status text not null default 'pending' check(status in('pending','approved','rejected')),withdrawn_at timestamptz,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(campaign_id,creator_id),
 constraint campaign_applications_pitch_length check(char_length(pitch)<=500));
-- Private per-admin inbox for completed creator onboarding and new campaign applications.
create table if not exists public.admin_notifications(
 id uuid primary key default gen_random_uuid(),
 admin_id uuid not null references public.admin_users(user_id) on delete cascade,
 notification_type text not null check(notification_type in('creator_signup','campaign_application')),
 creator_id uuid references public.creator_profiles(id) on delete cascade,
 application_id uuid references public.campaign_applications(id) on delete cascade,
 created_at timestamptz not null default now(),read_at timestamptz,
 constraint admin_notifications_target_check check(
  (notification_type='creator_signup' and creator_id is not null and application_id is null) or
  (notification_type='campaign_application' and application_id is not null and creator_id is null)));
create index if not exists creator_profiles_status_created_idx on public.creator_profiles(account_status,created_at);
create index if not exists creator_contracts_status_created_idx on public.creator_contracts(contract_status,created_at desc);
create index if not exists creator_portfolios_status_created_idx on public.creator_portfolios(portfolio_status,created_at desc);
create index if not exists campaigns_status_order_idx on public.campaigns(status,featured desc,display_order,created_at desc);
create index if not exists campaigns_deadline_idx on public.campaigns(deadline) where status='published';
create index if not exists applications_campaign_created_idx on public.campaign_applications(campaign_id,created_at desc);
create index if not exists applications_creator_created_idx on public.campaign_applications(creator_id,created_at desc);
create index if not exists audit_created_idx on public.admin_audit_log(created_at desc);
create index if not exists admin_notifications_unread_idx on public.admin_notifications(admin_id,created_at desc) where read_at is null;

create or replace function public.notify_admin_creator_signup() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if tg_op='INSERT' or (tg_op='UPDATE' and new.portfolio_status='pending') then
  insert into public.admin_notifications(admin_id,notification_type,creator_id)
  select a.user_id,'creator_signup',new.creator_id from public.admin_users a where not exists(select 1 from public.admin_notifications n where n.admin_id=a.user_id and n.notification_type='creator_signup' and n.creator_id=new.creator_id and n.read_at is null);
 end if;
 return new;
end; $$;
revoke all on function public.notify_admin_creator_signup() from public,anon,authenticated;
drop trigger if exists creator_portfolio_notify_admins on public.creator_portfolios;
create trigger creator_portfolio_notify_admins after insert or update of portfolio_url,portfolio_status on public.creator_portfolios
for each row execute function public.notify_admin_creator_signup();

create or replace function public.notify_admin_campaign_application() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 insert into public.admin_notifications(admin_id,notification_type,application_id)
 select user_id,'campaign_application',new.id from public.admin_users;
 return new;
end; $$;
revoke all on function public.notify_admin_campaign_application() from public,anon,authenticated;
drop trigger if exists campaign_application_notify_admins on public.campaign_applications;
create trigger campaign_application_notify_admins after insert on public.campaign_applications
for each row execute function public.notify_admin_campaign_application();
create or replace function public.notify_new_admin_pending_items() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 insert into public.admin_notifications(admin_id,notification_type,creator_id)
 select new.user_id,'creator_signup',p.id from public.creator_profiles p
 where exists(select 1 from public.creator_contracts c where c.creator_id=p.id)
 and exists(select 1 from public.creator_portfolios pf where pf.creator_id=p.id)
 and (p.needs_portfolio_update or exists(select 1 from public.creator_contracts c where c.creator_id=p.id and c.contract_status='pending') or exists(select 1 from public.creator_portfolios pf where pf.creator_id=p.id and pf.portfolio_status='pending'))
 and not exists(select 1 from public.admin_notifications n where n.admin_id=new.user_id and n.notification_type='creator_signup' and n.creator_id=p.id);
 insert into public.admin_notifications(admin_id,notification_type,application_id)
 select new.user_id,'campaign_application',a.id from public.campaign_applications a
 where a.status='pending' and a.withdrawn_at is null
 and not exists(select 1 from public.admin_notifications n where n.admin_id=new.user_id and n.notification_type='campaign_application' and n.application_id=a.id);
 return new;
end; $$;
revoke all on function public.notify_new_admin_pending_items() from public,anon,authenticated;
drop trigger if exists admin_user_pending_notifications on public.admin_users;
create trigger admin_user_pending_notifications after insert on public.admin_users
for each row execute function public.notify_new_admin_pending_items();

insert into public.admin_notifications(admin_id,notification_type,creator_id)
select au.user_id,'creator_signup',p.id from public.admin_users au cross join public.creator_profiles p
where exists(select 1 from public.creator_contracts c where c.creator_id=p.id)
and exists(select 1 from public.creator_portfolios pf where pf.creator_id=p.id)
 and (p.needs_portfolio_update or exists(select 1 from public.creator_contracts c where c.creator_id=p.id and c.contract_status='pending') or exists(select 1 from public.creator_portfolios pf where pf.creator_id=p.id and pf.portfolio_status='pending'))
and not exists(select 1 from public.admin_notifications n where n.admin_id=au.user_id and n.notification_type='creator_signup' and n.creator_id=p.id);
insert into public.admin_notifications(admin_id,notification_type,application_id)
select au.user_id,'campaign_application',a.id from public.admin_users au cross join public.campaign_applications a
where a.status='pending' and a.withdrawn_at is null
and not exists(select 1 from public.admin_notifications n where n.admin_id=au.user_id and n.notification_type='campaign_application' and n.application_id=a.id);

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=''
as $$ select (select auth.jwt()->>'aal')='aal2' and exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())); $$;
create or replace function public.is_owner() returns boolean language sql stable security definer set search_path=''
as $$ select (select auth.jwt()->>'aal')='aal2' and exists(select 1 from public.admin_users a where a.user_id=(select auth.uid()) and a.role='owner'); $$;
revoke all on function public.is_admin() from public,anon; revoke all on function public.is_owner() from public,anon;
grant execute on function public.is_admin(),public.is_owner() to authenticated;
create or replace function public.creator_approval_status(p_creator_id uuid default null)
returns text language plpgsql stable security definer set search_path=''
as $$ declare v_id uuid:=coalesce(p_creator_id,(select auth.uid()));v_account text;v_contract text;v_portfolio text;v_needs boolean;
begin
 if (select auth.uid()) is null or (v_id<>(select auth.uid()) and not public.is_admin()) then raise exception 'Not authorized';end if;
 select account_status,needs_portfolio_update into v_account,v_needs from public.creator_profiles where id=v_id;
 if not found then return 'pending';end if;
 select contract_status into v_contract from public.creator_contracts where creator_id=v_id order by signed_at desc limit 1;
 select portfolio_status into v_portfolio from public.creator_portfolios where creator_id=v_id order by created_at desc limit 1;
 if v_account='suspended' then return 'suspended';end if;
 if v_account='rejected' or v_contract='rejected' or v_portfolio='rejected' then return 'rejected';end if;
 if v_needs then return 'pending';end if;
 if v_contract='approved' and v_portfolio='approved' then return 'approved';end if;return 'pending';
end; $$;
revoke all on function public.creator_approval_status(uuid) from public,anon;grant execute on function public.creator_approval_status(uuid) to authenticated;
create or replace function public.creator_is_approved(p_creator_id uuid) returns boolean language sql stable security definer set search_path=''
as $$ select p_creator_id=(select auth.uid()) and public.creator_approval_status(p_creator_id)='approved'; $$;
revoke all on function public.creator_is_approved(uuid) from public,anon;grant execute on function public.creator_is_approved(uuid) to authenticated;
create or replace view public.creator_approval_status_view with(security_invoker=true) as
select p.id creator_id,case when p.account_status='suspended' then 'suspended'
 when p.account_status='rejected' or c.contract_status='rejected' or pf.portfolio_status='rejected' then 'rejected'
 when p.needs_portfolio_update then 'pending' when c.contract_status='approved' and pf.portfolio_status='approved' then 'approved'
 else 'pending' end approval_status,p.account_status,p.review_note,p.needs_portfolio_update,c.contract_status,c.review_note contract_review_note,
 pf.portfolio_status,pf.review_note portfolio_review_note
from public.creator_profiles p
left join lateral(select contract_status,review_note from public.creator_contracts where creator_id=p.id order by signed_at desc limit 1)c on true
left join lateral(select portfolio_status,review_note from public.creator_portfolios where creator_id=p.id order by created_at desc limit 1)pf on true;
create or replace function public.admin_enrollment_required() returns boolean language sql stable security definer set search_path=''
as $$ select (select auth.uid()) is not null and exists(select 1 from public.admin_users where user_id=(select auth.uid())); $$;
revoke all on function public.admin_enrollment_required() from public,anon;grant execute on function public.admin_enrollment_required() to authenticated;

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path=''
as $$ begin new.updated_at:=now();return new;end; $$;
create or replace function public.protect_creator_profile() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if tg_op='UPDATE' and not public.is_admin() and pg_trigger_depth()=1 and (new.account_status is distinct from old.account_status or new.review_note is distinct from old.review_note or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at or new.needs_portfolio_update is distinct from old.needs_portfolio_update)
 then raise exception 'Review fields are managed by Vidfluencer';end if;
 if tg_op='INSERT' and not public.is_admin() then new.account_status:='active';new.review_note:=null;new.reviewed_by:=null;new.reviewed_at:=null;new.needs_portfolio_update:=false;end if;return new;
end; $$;
create or replace function public.protect_creator_contract() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if tg_op='UPDATE' and not public.is_admin() and (new.contract_status is distinct from old.contract_status or new.review_note is distinct from old.review_note or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at) then raise exception 'Review fields are managed by Vidfluencer';end if;
 if tg_op='INSERT' and not public.is_admin() then new.contract_status:='pending';new.review_note:=null;new.reviewed_by:=null;new.reviewed_at:=null;end if;return new;
end; $$;
create or replace function public.protect_creator_portfolio() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if tg_op='DELETE' and not public.is_admin() then raise exception 'Portfolio records cannot be deleted';end if;
 if tg_op='INSERT' and not public.is_admin() then
  if new.portfolio_url is null or new.portfolio_url !~* '^https?://' then raise exception 'Portfolio link must use http or https';end if;
  new.portfolio_status:='pending';new.review_note:=null;new.reviewed_by:=null;new.reviewed_at:=null;
  update public.creator_profiles set needs_portfolio_update=false where id=new.creator_id;
 elsif tg_op='UPDATE' and not public.is_admin() then
  if new.creator_id is distinct from old.creator_id or new.portfolio_status is distinct from old.portfolio_status or new.review_note is distinct from old.review_note or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'Review fields are managed by Vidfluencer';end if;
  if new.portfolio_url is distinct from old.portfolio_url or exists(select 1 from public.creator_profiles where id=old.creator_id and needs_portfolio_update) then
   if new.portfolio_url is null or new.portfolio_url !~* '^https?://' then raise exception 'Portfolio link must use http or https';end if;
   new.portfolio_status:='pending';new.review_note:=null;new.reviewed_by:=null;new.reviewed_at:=null;
   update public.creator_profiles set needs_portfolio_update=false where id=new.creator_id;
  end if;
 end if;return new;
end; $$;
drop trigger if exists creator_profiles_protect_review on public.creator_profiles;
create trigger creator_profiles_protect_review before insert or update on public.creator_profiles for each row execute function public.protect_creator_profile();
drop trigger if exists creator_contracts_protect_review on public.creator_contracts;
create trigger creator_contracts_protect_review before insert or update on public.creator_contracts for each row execute function public.protect_creator_contract();
drop trigger if exists creator_portfolios_protect_review on public.creator_portfolios;
create trigger creator_portfolios_protect_review before insert or update or delete on public.creator_portfolios for each row execute function public.protect_creator_portfolio();
drop trigger if exists campaigns_updated_at on public.campaigns;
create trigger campaigns_updated_at before update on public.campaigns for each row execute function public.set_updated_at();
drop trigger if exists applications_updated_at on public.campaign_applications;
create trigger applications_updated_at before update on public.campaign_applications for each row execute function public.set_updated_at();
create or replace function public.protect_application_withdrawal() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if not public.is_admin() and (new.creator_id is distinct from old.creator_id or new.campaign_id is distinct from old.campaign_id or new.pitch is distinct from old.pitch or new.status is distinct from old.status) then raise exception 'Application review fields are managed by Vidfluencer';end if;
 if not public.is_admin() and old.withdrawn_at is not null and new.withdrawn_at is null then raise exception 'Withdrawn applications cannot be reopened';end if;
 if not public.is_admin() and old.withdrawn_at is null and new.withdrawn_at is null then raise exception 'Creators can only withdraw applications';end if;return new;
end; $$;
drop trigger if exists application_withdrawal_guard on public.campaign_applications;
create trigger application_withdrawal_guard before update on public.campaign_applications for each row execute function public.protect_application_withdrawal();

create or replace function public.audit_admin_change() returns trigger language plpgsql security definer set search_path=''
as $$ declare v_before jsonb;v_after jsonb;v_target text;
begin
 if tg_table_name='admin_users' then
  v_target:=case when tg_op='DELETE' then old.user_id::text else new.user_id::text end;
  v_before:=case when tg_op='INSERT' then null else jsonb_build_object('role',old.role) end;v_after:=case when tg_op='DELETE' then null else jsonb_build_object('role',new.role) end;
  insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary) values((select auth.uid()),'role_'||lower(tg_op),'admin_user',v_target,v_before,v_after);
 elsif tg_table_name='campaigns' then
  v_target:=case when tg_op='DELETE' then old.id::text else new.id::text end;v_before:=case when tg_op='INSERT' then null else to_jsonb(old)-'created_at' end;v_after:=case when tg_op='DELETE' then null else to_jsonb(new)-'created_at' end;
  insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary) values((select auth.uid()),'campaign_'||lower(tg_op),'campaign',v_target,v_before,v_after);
 elsif tg_table_name='campaign_applications' then
  if new.status is distinct from old.status then
   insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary) values((select auth.uid()),'application_status','campaign_application',new.id::text,jsonb_build_object('status',old.status),jsonb_build_object('status',new.status));
  end if;
 elsif tg_table_name='creator_profiles' then
  if new.account_status is distinct from old.account_status or new.review_note is distinct from old.review_note or new.needs_portfolio_update is distinct from old.needs_portfolio_update then
   insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary,reason) values((select auth.uid()),'creator_review','creator',new.id::text,jsonb_build_object('status',old.account_status,'needs_portfolio_update',old.needs_portfolio_update),jsonb_build_object('status',new.account_status,'needs_portfolio_update',new.needs_portfolio_update),new.review_note);
  end if;
 elsif tg_table_name='creator_contracts' then
  if new.contract_status is distinct from old.contract_status then
   insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary,reason) values((select auth.uid()),'contract_review','creator_contract',new.id::text,jsonb_build_object('status',old.contract_status),jsonb_build_object('status',new.contract_status),new.review_note);
  end if;
 elsif tg_table_name='creator_portfolios' then
  if new.portfolio_status is distinct from old.portfolio_status then
   insert into public.admin_audit_log(admin_id,action,target_type,target_id,before_summary,after_summary,reason) values((select auth.uid()),'portfolio_review','creator_portfolio',new.id::text,jsonb_build_object('status',old.portfolio_status),jsonb_build_object('status',new.portfolio_status),new.review_note);
  end if;
 end if;
 if tg_op='DELETE' then return old;else return new;end if;
end; $$;
drop trigger if exists admins_audit on public.admin_users;
create trigger admins_audit after insert or update or delete on public.admin_users for each row execute function public.audit_admin_change();
drop trigger if exists campaigns_audit on public.campaigns;
create trigger campaigns_audit after insert or update or delete on public.campaigns for each row execute function public.audit_admin_change();
drop trigger if exists applications_audit on public.campaign_applications;
create trigger applications_audit after update on public.campaign_applications for each row execute function public.audit_admin_change();
drop trigger if exists profile_review_audit on public.creator_profiles;
create trigger profile_review_audit after update on public.creator_profiles for each row execute function public.audit_admin_change();
drop trigger if exists contract_review_audit on public.creator_contracts;
create trigger contract_review_audit after update on public.creator_contracts for each row execute function public.audit_admin_change();
drop trigger if exists portfolio_review_audit on public.creator_portfolios;
create trigger portfolio_review_audit after update on public.creator_portfolios for each row execute function public.audit_admin_change();
create or replace function public.guard_last_owner() returns trigger language plpgsql security definer set search_path=''
as $$ begin
 if tg_op='DELETE' and old.role='owner' and (select count(*) from public.admin_users where role='owner')<=1 then raise exception 'At least one owner must remain';end if;
 if tg_op='UPDATE' and old.role='owner' and new.role<>'owner' and (select count(*) from public.admin_users where role='owner')<=1 then raise exception 'At least one owner must remain';end if;
 if tg_op='DELETE' then return old;else return new;end if;
end; $$;
drop trigger if exists admin_last_owner_guard on public.admin_users;
create trigger admin_last_owner_guard before update or delete on public.admin_users for each row execute function public.guard_last_owner();

create or replace function public.admin_creator_queue(p_filter text default 'pending',p_search text default '')
returns jsonb language plpgsql security definer set search_path=''
as $$ declare v_result jsonb;
begin
 if not public.is_admin() then raise exception 'Not authorized';end if;
 select coalesce(jsonb_agg(item order by created_at),'[]'::jsonb) into v_result from(
 select jsonb_build_object('id',p.id,'name',p.full_name,'email',u.email,'creatorName',p.creator_name,'legalName',p.legal_name,'country',p.country,
 'socialHandles',p.social_handles,'address',p.address,'contactEmail',p.contact_email,'paypalEmail',p.paypal_email,'vatNumber',p.vat_number,
 'ageConfirmation',p.age_confirmation,'guardianName',p.guardian_name,'guardianSignature',p.guardian_signature,'paymentMethod',p.payment_method,
 'payoutMasked',case when p.payout_details is null then '' else '•••• '||right(regexp_replace(p.payout_details,'\s','','g'),4) end,
 'accountStatus',p.account_status,'approvalStatus',public.creator_approval_status(p.id),'reviewNote',p.review_note,'needsPortfolioUpdate',p.needs_portfolio_update,'createdAt',p.created_at,
 'contract',case when c.id is null then null else jsonb_build_object('id',c.id,'version',c.agreement_version,'signer',c.signer_name,'signedAt',c.signed_at,'status',c.contract_status,'reviewNote',c.review_note,'snapshotPath',c.storage_path,'pdfPath',c.pdf_storage_path) end,
 'portfolio',case when pf.id is null then null else jsonb_build_object('id',pf.id,'url',pf.portfolio_url,'status',pf.portfolio_status,'reviewNote',pf.review_note,'createdAt',pf.created_at) end) item,p.created_at
 from public.creator_profiles p join auth.users u on u.id=p.id
 left join lateral(select * from public.creator_contracts where creator_id=p.id order by signed_at desc limit 1)c on true
 left join lateral(select * from public.creator_portfolios where creator_id=p.id order by created_at desc limit 1)pf on true
 where (p_filter='all' or public.creator_approval_status(p.id)=p_filter)
 and (nullif(btrim(p_search),'') is null or concat_ws(' ',p.full_name,p.creator_name,u.email,p.country) ilike '%'||btrim(p_search)||'%'))q;
 return v_result;
end; $$;
create or replace function public.admin_review_creator(p_creator_id uuid,p_action text,p_component text default 'all',p_reason text default null)
returns void language plpgsql security definer set search_path=''
as $$ declare v_contract uuid;v_portfolio uuid;v_reason text:=nullif(btrim(p_reason),'');
begin
 if not public.is_admin() then raise exception 'Not authorized';end if;
 if p_action not in('approve','reject','request_changes','suspend','reinstate') then raise exception 'Invalid action';end if;
 if p_component not in('all','contract','portfolio') then raise exception 'Invalid review component';end if;
 if p_action in('reject','request_changes','suspend') and v_reason is null then raise exception 'A reason is required';end if;
 select id into v_contract from public.creator_contracts where creator_id=p_creator_id order by signed_at desc limit 1;
 select id into v_portfolio from public.creator_portfolios where creator_id=p_creator_id order by created_at desc limit 1;
 if p_action='approve' then
  if p_component in('all','contract') then if v_contract is null then raise exception 'No signed agreement exists';end if;
   update public.creator_contracts set contract_status='approved',review_note=null,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_contract;end if;
  if p_component in('all','portfolio') then if v_portfolio is null then raise exception 'No portfolio link exists';end if;
   update public.creator_portfolios set portfolio_status='approved',review_note=null,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_portfolio;
   update public.creator_profiles set needs_portfolio_update=false where id=p_creator_id;end if;
  update public.creator_profiles set account_status='active',review_note=null,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='reject' then
  if p_component in('all','contract') and v_contract is not null then update public.creator_contracts set contract_status='rejected',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_contract;end if;
  if p_component in('all','portfolio') and v_portfolio is not null then update public.creator_portfolios set portfolio_status='rejected',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_portfolio;end if;
  update public.creator_profiles set account_status='rejected',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='request_changes' then update public.creator_profiles set needs_portfolio_update=true,review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='suspend' then update public.creator_profiles set account_status='suspended',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='reinstate' then update public.creator_profiles set account_status='active',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;end if;
 if not exists(select 1 from public.creator_profiles where id=p_creator_id) then raise exception 'Creator record not found';end if;
 update public.admin_notifications set read_at=now() where admin_id=(select auth.uid()) and notification_type='creator_signup' and creator_id=p_creator_id and read_at is null;
end; $$;
create or replace function public.admin_reveal_payout(p_creator_id uuid) returns text language plpgsql security definer set search_path=''
as $$ declare v text;begin
 if not public.is_admin() then raise exception 'Not authorized';end if;select payout_details into v from public.creator_profiles where id=p_creator_id;
 if not found then raise exception 'Creator not found';end if;
 insert into public.admin_audit_log(admin_id,action,target_type,target_id,reason) values((select auth.uid()),'payout_revealed','creator',p_creator_id::text,'Sensitive payout detail accessed');return coalesce(v,'');
end; $$;
create or replace function public.admin_dashboard_summary() returns jsonb language plpgsql security definer set search_path=''
as $$ begin if not public.is_admin() then raise exception 'Not authorized';end if;
 return jsonb_build_object('pendingContracts',(select count(*) from public.creator_contracts where contract_status='pending'),'pendingPortfolios',(select count(*) from public.creator_portfolios where portfolio_status='pending'),
 'publishedCampaigns',(select count(*) from public.campaigns where status='published'),'newApplications',(select count(*) from public.campaign_applications where status='pending' and withdrawn_at is null),
 'unreadCreatorSignups',(select count(*) from public.admin_notifications n join public.creator_profiles p on p.id=n.creator_id where n.admin_id=(select auth.uid()) and n.notification_type='creator_signup' and n.read_at is null and public.creator_approval_status(p.id)='pending'),
 'unreadCampaignApplications',(select count(*) from public.admin_notifications n join public.campaign_applications a on a.id=n.application_id where n.admin_id=(select auth.uid()) and n.notification_type='campaign_application' and n.read_at is null and a.status='pending' and a.withdrawn_at is null));end; $$;
create or replace function public.admin_campaign_applications(p_campaign_id uuid) returns jsonb language plpgsql security definer set search_path=''
as $$ begin if not public.is_admin() then raise exception 'Not authorized';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'campaignId',a.campaign_id,'campaignTitle',c.title,'creatorId',a.creator_id,'name',p.full_name,'email',u.email,'pitch',a.pitch,'status',a.status,'createdAt',a.created_at,'withdrawnAt',a.withdrawn_at) order by a.created_at desc)
 from public.campaign_applications a join public.campaigns c on c.id=a.campaign_id join auth.users u on u.id=a.creator_id left join public.creator_profiles p on p.id=a.creator_id where (p_campaign_id is null or a.campaign_id=p_campaign_id)),'[]'::jsonb);end; $$;
create or replace function public.admin_set_application_status(p_application_id uuid,p_status text) returns void language plpgsql security definer set search_path=''
as $$ begin if not public.is_admin() or p_status is null or p_status not in('pending','approved','rejected') then raise exception 'Not authorized';end if;
 update public.campaign_applications set status=p_status where id=p_application_id;if not found then raise exception 'Application not found';end if;
 if p_status<>'pending' then update public.admin_notifications set read_at=now() where admin_id=(select auth.uid()) and notification_type='campaign_application' and application_id=p_application_id and read_at is null;end if;end; $$;
create or replace function public.admin_list_users() returns jsonb language plpgsql security definer set search_path=''
as $$ begin if not public.is_owner() then raise exception 'Not authorized';end if;
 return coalesce((select jsonb_agg(jsonb_build_object('userId',a.user_id,'email',u.email,'role',a.role,'createdAt',a.created_at) order by a.created_at) from public.admin_users a left join auth.users u on u.id=a.user_id),'[]'::jsonb);end; $$;
create or replace function public.admin_manage_user(p_action text,p_email text default null,p_user_id uuid default null,p_role text default null)
returns void language plpgsql security definer set search_path='' as $$ declare v_id uuid;
begin if not public.is_owner() then raise exception 'Not authorized';end if;
 if p_action='add' then if p_role not in('owner','moderator') or nullif(btrim(p_email),'') is null then raise exception 'Valid email and role required';end if;
  select id into v_id from auth.users where lower(email)=lower(btrim(p_email)) limit 1;if v_id is null then raise exception 'No account exists for that email';end if;
  insert into public.admin_users(user_id,role) values(v_id,p_role) on conflict(user_id) do update set role=excluded.role;
 elsif p_action='role' then if p_role not in('owner','moderator') or p_user_id is null then raise exception 'Valid role required';end if;
  update public.admin_users set role=p_role where user_id=p_user_id;if not found then raise exception 'Admin not found';end if;
 elsif p_action='remove' then if p_user_id is null or p_user_id=(select auth.uid()) then raise exception 'Select another admin';end if;
  delete from public.admin_users where user_id=p_user_id;if not found then raise exception 'Admin not found';end if;
 else raise exception 'Invalid action';end if;end; $$;

create or replace function public.audit_campaign_thumbnail() returns trigger language plpgsql security definer set search_path=''
as $$ begin if coalesce(new.bucket_id,old.bucket_id)='campaign-thumbnails' then
 insert into public.admin_audit_log(admin_id,action,target_type,target_id,after_summary) values((select auth.uid()),case when tg_op='DELETE' then 'thumbnail_deleted' else 'thumbnail_'||lower(tg_op) end,'storage_object',case when tg_op='DELETE' then old.name else new.name end,jsonb_build_object('bucket','campaign-thumbnails'));end if;
 if tg_op='DELETE' then return old;else return new;end if;end; $$;
drop trigger if exists campaign_thumbnail_audit on storage.objects;
create trigger campaign_thumbnail_audit after insert or update or delete on storage.objects for each row execute function public.audit_campaign_thumbnail();

alter table public.admin_users enable row level security;alter table public.admin_audit_log enable row level security;
alter table public.admin_notifications enable row level security;
alter table public.campaigns enable row level security;alter table public.campaign_applications enable row level security;
alter table public.creator_profiles enable row level security;alter table public.creator_contracts enable row level security;alter table public.creator_portfolios enable row level security;
drop policy if exists "Creators can read their own profile" on public.creator_profiles;drop policy if exists "Creators can create their own profile" on public.creator_profiles;drop policy if exists "Creators can update their own profile" on public.creator_profiles;drop policy if exists "Creator reads own profile" on public.creator_profiles;
create policy "Creator reads own profile" on public.creator_profiles for select to authenticated using(id=(select auth.uid()) or public.is_admin());
drop policy if exists "Creator creates own profile" on public.creator_profiles;create policy "Creator creates own profile" on public.creator_profiles for insert to authenticated with check(id=(select auth.uid()));
drop policy if exists "Creator updates own editable profile" on public.creator_profiles;create policy "Creator updates own editable profile" on public.creator_profiles for update to authenticated using(id=(select auth.uid()) or public.is_admin()) with check(id=(select auth.uid()) or public.is_admin());
drop policy if exists "Creators can read their own agreements" on public.creator_contracts;drop policy if exists "Creators can save their own agreements" on public.creator_contracts;drop policy if exists "Creator reads own or admin reviews agreements" on public.creator_contracts;
create policy "Creator reads own or admin reviews agreements" on public.creator_contracts for select to authenticated using(creator_id=(select auth.uid()) or public.is_admin());
drop policy if exists "Creator inserts own agreement" on public.creator_contracts;create policy "Creator inserts own agreement" on public.creator_contracts for insert to authenticated with check(creator_id=(select auth.uid()));
drop policy if exists "Creators can read their own portfolios" on public.creator_portfolios;drop policy if exists "Creators can submit their own portfolios" on public.creator_portfolios;drop policy if exists "Creators can update their own portfolios" on public.creator_portfolios;drop policy if exists "Creators can remove their own portfolios" on public.creator_portfolios;drop policy if exists "Creator reads own or admin reviews portfolios" on public.creator_portfolios;
create policy "Creator reads own or admin reviews portfolios" on public.creator_portfolios for select to authenticated using(creator_id=(select auth.uid()) or public.is_admin());
drop policy if exists "Creator inserts own portfolio" on public.creator_portfolios;create policy "Creator inserts own portfolio" on public.creator_portfolios for insert to authenticated with check(creator_id=(select auth.uid()));
drop policy if exists "Creator updates own portfolio link" on public.creator_portfolios;create policy "Creator updates own portfolio link" on public.creator_portfolios for update to authenticated using(creator_id=(select auth.uid()) or public.is_admin()) with check(creator_id=(select auth.uid()) or public.is_admin());
drop policy if exists "Admin deletes portfolios" on public.creator_portfolios;create policy "Admin deletes portfolios" on public.creator_portfolios for delete to authenticated using(public.is_admin());
drop policy if exists "Admin users readable by admins" on public.admin_users;create policy "Admin users readable by admins" on public.admin_users for select to authenticated using(public.is_admin());
drop policy if exists "Audit readable by admins" on public.admin_audit_log;create policy "Audit readable by admins" on public.admin_audit_log for select to authenticated using(public.is_admin());
drop policy if exists "Campaigns admin or approved select" on public.campaigns;create policy "Campaigns admin or approved select" on public.campaigns for select to authenticated using(public.is_admin() or (status='published' and public.creator_is_approved((select auth.uid()))));
drop policy if exists "Admins insert campaigns" on public.campaigns;create policy "Admins insert campaigns" on public.campaigns for insert to authenticated with check(public.is_admin());
drop policy if exists "Admins update campaigns" on public.campaigns;create policy "Admins update campaigns" on public.campaigns for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "Admins delete campaigns" on public.campaigns;create policy "Admins delete campaigns" on public.campaigns for delete to authenticated using(public.is_admin());
drop policy if exists "Creators read own applications; admins read all" on public.campaign_applications;create policy "Creators read own applications; admins read all" on public.campaign_applications for select to authenticated using(creator_id=(select auth.uid()) or public.is_admin());
drop policy if exists "Approved creators apply to published campaigns" on public.campaign_applications;create policy "Approved creators apply to published campaigns" on public.campaign_applications for insert to authenticated with check(creator_id=(select auth.uid()) and public.creator_is_approved((select auth.uid())) and status='pending' and withdrawn_at is null and exists(select 1 from public.campaigns c where c.id=campaign_id and c.status='published'));
drop policy if exists "Creators withdraw own application" on public.campaign_applications;create policy "Creators withdraw own application" on public.campaign_applications for update to authenticated using(creator_id=(select auth.uid())) with check(creator_id=(select auth.uid()));
drop policy if exists "Admins update applications" on public.campaign_applications;create policy "Admins update applications" on public.campaign_applications for update to authenticated using(public.is_admin()) with check(public.is_admin());

revoke all on public.creator_profiles,public.creator_contracts,public.creator_portfolios,public.admin_users,public.admin_audit_log,public.campaigns,public.campaign_applications from public,anon,authenticated;
revoke all on public.admin_notifications from public,anon,authenticated;
grant select on public.creator_profiles,public.creator_contracts,public.creator_portfolios to authenticated;
grant insert(id,full_name,contact_method) on public.creator_profiles to authenticated;
grant update(id,full_name,contact_method,legal_name,creator_name,contact_email,address,country,social_handles,paypal_email,vat_number,age_confirmation,guardian_name,guardian_signature,payment_method,payout_details) on public.creator_profiles to authenticated;
grant insert(creator_id,agreement_version,signer_name,signed_at,storage_path,pdf_storage_path) on public.creator_contracts to authenticated;
grant insert(creator_id,portfolio_url) on public.creator_portfolios to authenticated;grant update(portfolio_url) on public.creator_portfolios to authenticated;
grant select on public.admin_users,public.admin_audit_log to authenticated;
grant select,insert,update,delete on public.campaigns to authenticated;
grant select on public.campaign_applications to authenticated;grant insert(campaign_id,creator_id,pitch) on public.campaign_applications to authenticated;grant update(withdrawn_at) on public.campaign_applications to authenticated;
revoke all on public.creator_approval_status_view from public,anon,authenticated;
grant select on public.creator_approval_status_view to authenticated;
revoke all on function public.admin_creator_queue(text,text),public.admin_review_creator(uuid,text,text,text),public.admin_reveal_payout(uuid),public.admin_dashboard_summary(),public.admin_campaign_applications(uuid),public.admin_set_application_status(uuid,text),public.admin_list_users(),public.admin_manage_user(text,text,uuid,text) from public,anon;
grant execute on function public.admin_creator_queue(text,text),public.admin_review_creator(uuid,text,text,text),public.admin_reveal_payout(uuid),public.admin_dashboard_summary(),public.admin_campaign_applications(uuid),public.admin_set_application_status(uuid,text),public.admin_list_users(),public.admin_manage_user(text,text,uuid,text) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('campaign-thumbnails','campaign-thumbnails',true,2097152,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set name=excluded.name,public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Public reads campaign thumbnails" on storage.objects;create policy "Public reads campaign thumbnails" on storage.objects for select to anon,authenticated using(bucket_id='campaign-thumbnails');
drop policy if exists "AAL2 admins upload campaign thumbnails" on storage.objects;create policy "AAL2 admins upload campaign thumbnails" on storage.objects for insert to authenticated with check(bucket_id='campaign-thumbnails' and public.is_admin());
drop policy if exists "AAL2 admins update campaign thumbnails" on storage.objects;create policy "AAL2 admins update campaign thumbnails" on storage.objects for update to authenticated using(bucket_id='campaign-thumbnails' and public.is_admin()) with check(bucket_id='campaign-thumbnails' and public.is_admin());
drop policy if exists "AAL2 admins delete campaign thumbnails" on storage.objects;create policy "AAL2 admins delete campaign thumbnails" on storage.objects for delete to authenticated using(bucket_id='campaign-thumbnails' and public.is_admin());
drop policy if exists "Creators can read their own agreement files" on storage.objects;create policy "Creators can read their own agreement files" on storage.objects for select to authenticated using(bucket_id='creator-contracts' and ((storage.foldername(name))[1]=(select auth.uid())::text or public.is_admin()));
drop policy if exists "Creators can upload their own agreement files" on storage.objects;create policy "Creators can upload their own agreement files" on storage.objects for insert to authenticated with check(bucket_id='creator-contracts' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Creators can read their own portfolio files" on storage.objects;create policy "Creators can read their own portfolio files" on storage.objects for select to authenticated using(bucket_id='creator-portfolios' and ((storage.foldername(name))[1]=(select auth.uid())::text or public.is_admin()));
drop policy if exists "Creators can upload their own portfolio files" on storage.objects;create policy "Creators can upload their own portfolio files" on storage.objects for insert to authenticated with check(bucket_id='creator-portfolios' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Creators can update their own portfolio files" on storage.objects;drop policy if exists "Creators can remove their own portfolio files" on storage.objects;
commit;

