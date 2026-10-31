begin;

-- Vidfluencer admin review action fix
-- Run once in Supabase SQL Editor after the existing admin setup.
-- Keeps review writes behind the existing AAL2 admin check.
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
 if not exists(select 1 from public.creator_profiles where id=p_creator_id) then raise exception 'Creator record not found';end if;
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
 elsif p_action='request_changes' then
  if p_component in('all','contract') then
   if v_contract is null then raise exception 'No signed agreement exists';end if;
   update public.creator_contracts set contract_status='rejected',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_contract;
  end if;
  if p_component in('all','portfolio') then
   if v_portfolio is null then raise exception 'No portfolio link exists';end if;
   update public.creator_portfolios set portfolio_status='rejected',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=v_portfolio;
   update public.creator_profiles set needs_portfolio_update=true where id=p_creator_id;
  end if;
  update public.creator_profiles set account_status='active',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='suspend' then update public.creator_profiles set account_status='suspended',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;
 elsif p_action='reinstate' then update public.creator_profiles set account_status='active',review_note=v_reason,reviewed_by=(select auth.uid()),reviewed_at=now() where id=p_creator_id;end if;
 update public.admin_notifications set read_at=now() where admin_id=(select auth.uid()) and notification_type='creator_signup' and creator_id=p_creator_id and read_at is null;
end; $$;

revoke all on function public.admin_review_creator(uuid,text,text,text) from public,anon;
grant execute on function public.admin_review_creator(uuid,text,text,text) to authenticated;

commit;
