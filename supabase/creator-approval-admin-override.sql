-- Creator-side contract submission still requires essential profile details.
-- VAT remains optional. This migration only removes the completeness veto from
-- admin review, so an admin can approve an existing incomplete record.
begin;

-- Keep completeness and signer checks on new creator agreements, but do not
-- block an administrator from changing an existing agreement's review status.
create or replace function public.creator_contracts_require_complete_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_legal_name text;
begin
  if tg_op = 'INSERT' then
    if not public.creator_profile_is_complete(new.creator_id) then
      raise exception 'Essential creator profile details are required before signing the agreement.'
        using errcode = '23514';
    end if;

    select p.legal_name into v_legal_name
    from public.creator_profiles p
    where p.id = new.creator_id;

    if nullif(btrim(new.signer_name), '') is null
       or lower(btrim(new.signer_name)) <> lower(btrim(v_legal_name)) then
      raise exception 'The agreement signature must match the creator legal name.'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$function$;
revoke all on function public.creator_contracts_require_complete_profile() from public, anon, authenticated;

-- Report an explicitly approved contract + portfolio as approved even if an
-- older profile is missing optional or previously unenforced details.
create or replace function public.creator_approval_status(p_creator_id uuid default null)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_id uuid := coalesce(p_creator_id, (select auth.uid()));
  v_account text;
  v_contract text;
  v_portfolio text;
  v_needs boolean;
begin
  if (select auth.uid()) is null
     or (v_id <> (select auth.uid()) and not public.is_admin()) then
    raise exception 'Not authorized';
  end if;

  select p.account_status, p.needs_portfolio_update
  into v_account, v_needs
  from public.creator_profiles p
  where p.id = v_id;
  if not found then return 'pending'; end if;

  select c.contract_status into v_contract
  from public.creator_contracts c
  where c.creator_id = v_id
  order by c.signed_at desc limit 1;
  select pf.portfolio_status into v_portfolio
  from public.creator_portfolios pf
  where pf.creator_id = v_id
  order by pf.created_at desc limit 1;

  if v_account = 'suspended' then return 'suspended'; end if;
  if v_account = 'rejected' or v_contract = 'rejected' or v_portfolio = 'rejected' then return 'rejected'; end if;
  if v_needs then return 'pending'; end if;
  if v_contract = 'approved' and v_portfolio = 'approved' then return 'approved'; end if;
  return 'pending';
end;
$function$;
revoke all on function public.creator_approval_status(uuid) from public, anon;
grant execute on function public.creator_approval_status(uuid) to authenticated;

create or replace view public.creator_approval_status_view with (security_invoker = true) as
select p.id as creator_id,
  case
    when p.account_status = 'suspended' then 'suspended'
    when p.account_status = 'rejected' or c.contract_status = 'rejected' or pf.portfolio_status = 'rejected' then 'rejected'
    when p.needs_portfolio_update then 'pending'
    when c.contract_status = 'approved' and pf.portfolio_status = 'approved' then 'approved'
    else 'pending'
  end as approval_status,
  p.account_status, p.review_note, p.needs_portfolio_update,
  c.contract_status, c.review_note as contract_review_note,
  pf.portfolio_status, pf.review_note as portfolio_review_note
from public.creator_profiles p
left join lateral (
  select contract_status, review_note
  from public.creator_contracts
  where creator_id = p.id
  order by signed_at desc limit 1
) c on true
left join lateral (
  select portfolio_status, review_note
  from public.creator_portfolios
  where creator_id = p.id
  order by created_at desc limit 1
) pf on true;

-- Keep all existing admin-only checks and required saved records. Only remove
-- the profile-completeness veto that prevented reviewing legacy applications.
create or replace function public.admin_review_creator(
  p_creator_id uuid,
  p_action text,
  p_component text default 'all',
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_contract uuid;
  v_portfolio uuid;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if not public.is_admin() then raise exception 'Not authorized'; end if;
  if p_action not in ('approve', 'reject', 'request_changes', 'suspend', 'reinstate') then
    raise exception 'Invalid action';
  end if;
  if p_component not in ('all', 'contract', 'portfolio') then
    raise exception 'Invalid review component';
  end if;
  if p_action in ('reject', 'request_changes', 'suspend') and v_reason is null then
    raise exception 'A reason is required';
  end if;

  select c.id into v_contract
  from public.creator_contracts c
  where c.creator_id = p_creator_id
  order by c.signed_at desc limit 1;
  select pf.id into v_portfolio
  from public.creator_portfolios pf
  where pf.creator_id = p_creator_id
  order by pf.created_at desc limit 1;
  if not exists (select 1 from public.creator_profiles p where p.id = p_creator_id) then
    raise exception 'Creator record not found';
  end if;

  if p_action = 'approve' then
    if p_component in ('all', 'contract') then
      if v_contract is null then raise exception 'No signed agreement exists'; end if;
      update public.creator_contracts
      set contract_status = 'approved', review_note = null,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_contract;
    end if;
    if p_component in ('all', 'portfolio') then
      if v_portfolio is null then raise exception 'No portfolio link exists'; end if;
      update public.creator_portfolios
      set portfolio_status = 'approved', review_note = null,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_portfolio;
      update public.creator_profiles set needs_portfolio_update = false where id = p_creator_id;
    end if;
    update public.creator_profiles
    set account_status = 'active', review_note = null,
        reviewed_by = (select auth.uid()), reviewed_at = now()
    where id = p_creator_id;
  elsif p_action = 'reject' then
    if p_component in ('all', 'contract') and v_contract is not null then
      update public.creator_contracts
      set contract_status = 'rejected', review_note = v_reason,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_contract;
    end if;
    if p_component in ('all', 'portfolio') and v_portfolio is not null then
      update public.creator_portfolios
      set portfolio_status = 'rejected', review_note = v_reason,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_portfolio;
    end if;
    update public.creator_profiles
    set account_status = 'rejected', review_note = v_reason,
        reviewed_by = (select auth.uid()), reviewed_at = now()
    where id = p_creator_id;
  elsif p_action = 'request_changes' then
    if p_component in ('all', 'contract') then
      if v_contract is null then raise exception 'No signed agreement exists'; end if;
      update public.creator_contracts
      set contract_status = 'rejected', review_note = v_reason,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_contract;
    end if;
    if p_component in ('all', 'portfolio') then
      if v_portfolio is null then raise exception 'No portfolio link exists'; end if;
      update public.creator_portfolios
      set portfolio_status = 'rejected', review_note = v_reason,
          reviewed_by = (select auth.uid()), reviewed_at = now()
      where id = v_portfolio;
      update public.creator_profiles set needs_portfolio_update = true where id = p_creator_id;
    end if;
    update public.creator_profiles
    set account_status = 'active', review_note = v_reason,
        reviewed_by = (select auth.uid()), reviewed_at = now()
    where id = p_creator_id;
  elsif p_action = 'suspend' then
    update public.creator_profiles
    set account_status = 'suspended', review_note = v_reason,
        reviewed_by = (select auth.uid()), reviewed_at = now()
    where id = p_creator_id;
  elsif p_action = 'reinstate' then
    update public.creator_profiles
    set account_status = 'active', review_note = v_reason,
        reviewed_by = (select auth.uid()), reviewed_at = now()
    where id = p_creator_id;
  end if;

  update public.admin_notifications
  set read_at = now()
  where admin_id = (select auth.uid())
    and notification_type = 'creator_signup'
    and creator_id = p_creator_id
    and read_at is null;
end;
$function$;
revoke all on function public.admin_review_creator(uuid, text, text, text) from public, anon;
grant execute on function public.admin_review_creator(uuid, text, text, text) to authenticated;

commit;
