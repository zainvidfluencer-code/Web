-- Require a Discord handle on each new campaign application and expose it to admins.
-- Existing applications are retained; older rows may have a NULL Discord handle.
begin;

alter table public.campaign_applications
  add column if not exists discord_handle text;

create or replace function public.require_campaign_application_discord_handle()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if nullif(btrim(new.discord_handle), '') is null then
    raise exception 'Discord handle is required' using errcode = '23514';
  end if;
  new.discord_handle := btrim(new.discord_handle);
  return new;
end;
$$;

drop trigger if exists campaign_applications_require_discord_handle
  on public.campaign_applications;
create trigger campaign_applications_require_discord_handle
  before insert or update of discord_handle on public.campaign_applications
  for each row execute function public.require_campaign_application_discord_handle();

create or replace function public.admin_campaign_applications(p_campaign_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
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
      'discordHandle', a.discord_handle,
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

revoke all on function public.admin_campaign_applications(uuid) from public, anon;
grant execute on function public.admin_campaign_applications(uuid) to authenticated;
revoke insert on public.campaign_applications from public, anon, authenticated;
grant insert(campaign_id, creator_id, pitch, discord_handle)
  on public.campaign_applications to authenticated;

commit;