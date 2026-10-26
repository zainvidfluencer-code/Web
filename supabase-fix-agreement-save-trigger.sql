-- Fix shared admin audit trigger to read only columns on the affected table.
begin;
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
commit;
