VIDFLUENCER CREATOR APPROVAL FIX

This update keeps the creator-side required-field checks and removes the rule
that prevented admins from approving an already submitted, incomplete profile.
The creator name/channel, legal name, contact details, country, address, social
handles, age and applicable payment/guardian details remain required to submit
a new signed agreement. VAT remains optional.

INSTALL

1. In GitHub, replace these four files with the matching files in this package:
   - vf-admin-desk-k8m2q.html  -> repository root
   - admin/index.html          -> repository admin folder
   - creator-portal.html       -> repository root
   - creator-portal/index.html -> repository creator-portal folder
2. In Supabase, open SQL Editor, paste and run:
   supabase/creator-approval-admin-override.sql
3. Wait for the GitHub Pages deployment to finish, then refresh the admin page.

Admins can then approve an existing incomplete profile after reviewing it. The
server still requires admin authorization, a saved signed agreement, and a
saved portfolio when approving both components. If a required record is
missing, select the component that actually exists or ask the creator to submit
the missing item. Creators cannot directly change review statuses.
