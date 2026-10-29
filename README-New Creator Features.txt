VIDFLUENCER — CREATOR PROFILE, FILTERS, EARNINGS AND ACCOUNT DELETION

This package extends the existing Vidfluencer static site and existing Supabase project. It does not replace the authentication system or delete existing campaigns or creator records. The campaign table shown in your screenshot was empty. Any old demo campaign was local browser preview data, not a database row; the admin preview now starts with no campaign demos.

WHAT IS INCLUDED
- Admin campaign editing and admin-only campaign/category management, using the existing admin role and campaign RLS.
- Creator-only application submission and existing application status flow.
- Persistent campaign filter categories and options, plus campaign assignments.
- Creator profile display name and bio, profile picture source selection, private uploads (JPG/PNG/WebP up to 2 MB), social links, and earnings display in USD.
- Admin USD amount at application approval (the existing campaign payout field is descriptive text, CPM or Pay Per Video, and has no numeric amount).
- Admin-only paid status/date recording.
- Recent-auth account deletion; OAuth-only accounts reauthenticate through an already-linked provider. Earnings records remain, with the creator identity anonymized.
- English, German and Spanish interface strings.

SET UP THE DATABASE (one-time)
1. Open the existing Vidfluencer project in Supabase and open SQL Editor.
2. Open the complete file supabase-creator-profile-earnings-migration.sql from this package, copy all of it into a new SQL query, and click Run once.
3. If you already ran the larger earnings migration, do not rerun it. To add the editable display name and bio, open supabase-creator-profile-customization-migration.sql in a separate query and click Run once.
4. Do not run these on a different project. The migrations preserve existing campaign, application and creator records.

DEPLOY THE ACCOUNT-DELETION FUNCTION
Use PowerShell on a computer with Node.js/npm and internet access. From the folder that contains this package, run these commands in order:

  npx supabase@latest login
  Set-Location "C:\Users\Aryan\Documents\Codex\2026-10-23\m\outputs\Vidfluencer Website Package"
  npx supabase@latest link --project-ref etzzzhbfeokhtzdwjyhn
  npx supabase@latest functions deploy delete-creator-account

The Supabase login and project-link steps are interactive. Sign in through the browser and choose the existing Vidfluencer project. Do not paste a service-role key into website files or GitHub Pages.

AUTH REDIRECT ALLOWLIST
In Supabase Authentication → URL Configuration, add this redirect URL so OAuth reauthentication can return to the profile deletion confirmation:
  https://vidfluencer.io/campaigns/?profile-delete-reauth=1
Keep the existing sign-in and OAuth callback URLs already in the project.

PUBLISH THE WEBSITE FILES
Your repository's current Pages workflow uploads the repository root (`path: '.'`). Extract the GitHub Pages export ZIP and upload/replace its contents at the repository root, keeping folders such as `assets` and `campaigns` in place and keeping `CNAME` at the root. Do not put everything inside an extra nested folder or inside `docs` unless you also change the workflow upload path. Publish the updated static files only after the database migration is applied; until then, the new profile fields will not load. The public Supabase publishable key in supabase-config.js is designed for browser use; never add a secret/service-role key to the static website.

DATABASE AND PRIVACY NOTES
- Campaign editing, category management, campaign approval, and payment marking are admin-only under the existing admin role/RLS and the new protected functions.
- Creators can read their own profile/earnings and edit their own profile fields; their avatar files are private to their account.
- Account deletion requires a recent session. Email/password accounts verify the password in Supabase Auth. Accounts without a password reauthenticate with an already-linked provider. The backend rejects admin deletion.
- Financial records remain for accounting; creator name/email/account links are removed. Creator profile and applications are removed through the existing Auth-user cascade. The function first removes the creator's private agreement, portfolio, and avatar files.
- No payment is sent by the site; earnings are a record only.

MANUAL CHECKLIST AFTER SETUP
1. Sign in as admin; confirm Campaigns shows “No campaigns yet.”
2. Add a filter category and options, create a campaign, assign options, and save.
3. Sign in as an approved creator; check rounded filter menus and filtering, then apply once.
4. Confirm a second application is blocked and the creator sees the current application status.
5. Approve the application as admin with a USD amount; confirm the creator sees Pending earnings.
6. Mark it Paid as admin; confirm the creator's Paid and Total earned values update and the admin sees a paid date.
7. Set your display name and bio, save, reopen the profile to confirm they persist, then set an avatar and add/edit/remove social links.
8. Use a test creator account to verify password-based and linked-provider deletion flows. Confirm uploaded files are removed and the earning entry remains anonymized.

The SQL and function are supplied but intentionally have not been run or deployed to your live project.
