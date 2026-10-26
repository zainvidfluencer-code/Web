-- Incremental campaign application status and review details migration.
-- Safe to run against the existing Vidfluencer Supabase project.
begin;

alter table public.campaign_applications
  drop constraint if exists campaign_applications_status_check;

update public.campaign_applications
set status = case status
  when 'new' then 'pending'
  when 'shortlisted' then 'approved'
  when 'declined' then 'rejected'
  else status
end;

alter table public.campaign_applications
  alter column status set default 'pending',
  add constraint campaign_applications_status_check
    check (status in ('pending', 'approved', 'rejected'));

drop policy if exists "Approved creators apply to published campaigns" on public.campaign_applications;
create policy "Approved creators apply to published campaigns"
  on public.campaign_applications for insert to authenticated
  with check (creator_id = (select auth.uid())
    and public.creator_is_approved((select auth.uid()))
    and status = 'pending' and withdrawn_at is null
    and exists (select 1 from public.campaigns c where c.id = campaign_id and c.status = 'published'));

create or replace function public.notify_new_admin_pending_items()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  insert into public.admin_notifications(admin_id, notification_type, creator_id)
  select new.user_id, 'creator_signup', p.id
  from public.creator_profiles p
  where exists (select 1 from public.creator_contracts c where c.creator_id = p.id)
    and exists (select 1 from public.creator_portfolios pf where pf.creator_id = p.id)
    and (p.needs_portfolio_update
      or exists (select 1 from public.creator_contracts c where c.creator_id = p.id and c.contract_status = 'pending')
      or exists (select 1 from public.creator_portfolios pf where pf.creator_id = p.id and pf.portfolio_status = 'pending'))
    and not exists (select 1 from public.admin_notifications n where n.admin_id = new.user_id and n.notification_type = 'creator_signup' and n.creator_id = p.id);

  insert into public.admin_notifications(admin_id, notification_type, application_id)
  select new.user_id, 'campaign_application', a.id
  from public.campaign_applications a
  where a.status = 'pending' and a.withdrawn_at is null
    and not exists (select 1 from public.admin_notifications n where n.admin_id = new.user_id and n.notification_type = 'campaign_application' and n.application_id = a.id);
  return new;
end;
$$;

create or replace function public.admin_dashboard_summary()
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  return jsonb_build_object(
    'pendingContracts', (select count(*) from public.creator_contracts where contract_status = 'pending'),
    'pendingPortfolios', (select count(*) from public.creator_portfolios where portfolio_status = 'pending'),
    'publishedCampaigns', (select count(*) from public.campaigns where status = 'published'),
    'newApplications', (select count(*) from public.campaign_applications where status = 'pending' and withdrawn_at is null),
    'unreadCreatorSignups', (select count(*) from public.admin_notifications n join public.creator_profiles p on p.id = n.creator_id where n.admin_id = (select auth.uid()) and n.notification_type = 'creator_signup' and n.read_at is null and public.creator_approval_status(p.id) = 'pending'),
    'unreadCampaignApplications', (select count(*) from public.admin_notifications n join public.campaign_applications a on a.id = n.application_id where n.admin_id = (select auth.uid()) and n.notification_type = 'campaign_application' and n.read_at is null and a.status = 'pending' and a.withdrawn_at is null)
  );
end;
$$;

create or replace function public.admin_campaign_applications(p_campaign_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', a.id,
      'campaignId', a.campaign_id,
      'campaignTitle', c.title,
      'creatorId', a.creator_id,
      'name', p.full_name,
      'email', u.email,
      'pitch', a.pitch,
      'status', a.status,
      'createdAt', a.created_at,
      'withdrawnAt', a.withdrawn_at
    ) order by a.created_at desc)
    from public.campaign_applications a
    join public.campaigns c on c.id = a.campaign_id
    join auth.users u on u.id = a.creator_id
    left join public.creator_profiles p on p.id = a.creator_id
    where p_campaign_id is null or a.campaign_id = p_campaign_id
  ), '[]'::jsonb);
end;
$$;

create or replace function public.admin_set_application_status(p_application_id uuid, p_status text)
returns void language plpgsql security definer set search_path=''
as $$
begin
  if not public.is_admin() or p_status is null or p_status not in ('pending', 'approved', 'rejected') then
    raise exception 'Not authorized';
  end if;
  update public.campaign_applications set status = p_status where id = p_application_id;
  if not found then raise exception 'Application not found'; end if;
  if p_status <> 'pending' then
    update public.admin_notifications set read_at = now()
    where admin_id = (select auth.uid()) and notification_type = 'campaign_application'
      and application_id = p_application_id and read_at is null;
  end if;
end;
$$;

revoke all on function public.notify_new_admin_pending_items() from public, anon, authenticated;
revoke all on function public.admin_dashboard_summary(), public.admin_campaign_applications(uuid), public.admin_set_application_status(uuid, text) from public, anon;
grant execute on function public.admin_dashboard_summary(), public.admin_campaign_applications(uuid), public.admin_set_application_status(uuid, text) to authenticated;

revoke insert on public.campaign_applications from public, anon, authenticated;
grant insert(campaign_id, creator_id, pitch) on public.campaign_applications to authenticated;

insert into public.admin_notifications(admin_id, notification_type, application_id)
select au.user_id, 'campaign_application', a.id
from public.admin_users au cross join public.campaign_applications a
where a.status = 'pending' and a.withdrawn_at is null
  and not exists (
    select 1 from public.admin_notifications n
    where n.admin_id = au.user_id and n.notification_type = 'campaign_application' and n.application_id = a.id
  );

commit;
