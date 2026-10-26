-- Repair the narrowly scoped privileges needed by creator_profiles upsert.
-- Existing RLS policies remain enabled and continue to limit rows to the signed-in creator.
begin;
grant usage on schema public to authenticated;
grant select on public.creator_profiles to authenticated;
grant insert (id, full_name, contact_method) on public.creator_profiles to authenticated;
grant update (id, full_name, contact_method) on public.creator_profiles to authenticated;
commit;

-- After applying the grants, all values below should be true.
select
  has_table_privilege('authenticated', 'public.creator_profiles', 'select') as can_select,
  has_column_privilege('authenticated', 'public.creator_profiles', 'id', 'insert') as can_insert_id,
  has_column_privilege('authenticated', 'public.creator_profiles', 'id', 'update') as can_update_id,
  has_column_privilege('authenticated', 'public.creator_profiles', 'full_name', 'insert') as can_insert_name,
  has_column_privilege('authenticated', 'public.creator_profiles', 'full_name', 'update') as can_update_name,
  has_column_privilege('authenticated', 'public.creator_profiles', 'contact_method', 'insert') as can_insert_contact,
  has_column_privilege('authenticated', 'public.creator_profiles', 'contact_method', 'update') as can_update_contact;
