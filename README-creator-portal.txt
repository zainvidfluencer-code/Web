VIDFLUENCER CREATOR + CAMPAIGNS PACKAGE
=============================================

Preview the website
- Open index.html for the public site.
- Open creator-portal.html?preview=agreement or ?preview=portfolio to inspect onboarding screens. The portfolio field accepts a link only.
- Open campaigns.html to see labelled sample campaigns while liveAuthReady is false.
- Open vf-admin-desk-k8m2q.html to preview sample admin screens while liveAuthReady is false. This sample mode is disabled as soon as liveAuthReady is set to true.
- The interface supports English, German and Spanish. The supplied agreement PDFs are English and German; no Spanish agreement was supplied.
- The creator sign-up screen shows separate Terms of Service and Privacy Policy links without an extra checkbox. Each opens the supplied English source document on its own reader page.
- Preview mode never creates accounts or saves creator/admin data.

Deploy the static site
1. Upload the contents of this folder to the site's static host, such as Cloudflare Pages. Keep the folder structure, including assets/ and assets/contracts/.
2. The homepage is index.html. The admin page names are intentionally obscure and are not linked publicly, but obscurity is not security.
3. After the files are deployed, add the exact deployed URLs to Supabase Authentication > URL Configuration > Redirect URLs. Include creator-portal.html, the configured admin login page, and the configured admin dashboard page. Set the Site URL to the deployed origin.
4. OAuth redirect URIs for Google, Microsoft and Discord remain the Supabase callback URL shown in Supabase Auth provider settings, not a website page. Configure client IDs and secrets only in Supabase.
5. Keep liveAuthReady false until all setup and deployment checks below are complete. Then edit only that flag in supabase-config.js. Do not add a Supabase secret/service-role key to any file.

Configure email verification
1. In Supabase Authentication > Email Templates > Confirm signup, set the subject to “Your Vidfluencer verification code” and replace the confirmation link with this body:
   <h2>Confirm your Vidfluencer account</h2>
   <p>Enter this six-digit code in the Vidfluencer sign-up window:</p>
   <p style="font-size:32px;font-weight:700;letter-spacing:8px">{{ .Token }}</p>
   <p>If you didn’t request this, you can ignore this email.</p>
   The creator portal now asks for the code directly.
2. Keep Confirm Email enabled. Supabase email OTPs default to six digits and expire after one hour; if an OTP length option is shown, set it to 6.
3. Email/password signups and resends use the code. If an unconfirmed creator tries to sign in, the portal requests a fresh code and returns them to the verification step.
4. Social sign-in providers continue to use their provider verification flow.
Configure the database
1. In Supabase SQL Editor, run supabase-setup.sql first if it has not already been applied.
2. Then run supabase-admin-setup.sql. This is an idempotent migration for account reviews, campaigns, applications, RLS, private file review access, thumbnail storage and admin auditing.
3. Check the SQL Editor result for errors before enabling liveAuthReady. The migration is provided for review; it has not been applied to your Supabase project from this package.
4. If signup verification reports permission denied for table creator_profiles, run supabase-fix-creator-profile-write.sql in SQL Editor, then retry the portal. It grants only the columns used by the creator profile upsert; existing owner-only RLS policies remain in force.
4. Bootstrap the first owner after creating their Supabase Auth account:
   - Create/sign up the intended owner account once using the creator portal, or create the Auth user in Supabase.
   - In Supabase Authentication > Users, copy that user's UUID.
   - Run this one-time SQL in SQL Editor, replacing the placeholder with the UUID:
     insert into public.admin_users (user_id, role)
     values ('PASTE-AUTH-USER-UUID-HERE'::uuid, 'owner')
     on conflict (user_id) do update set role = excluded.role;
   - The admin table is not exposed for public writes. No website form can bootstrap or promote the first owner.
5. Enable TOTP authenticator enrollment and verification in Supabase Authentication > Multi-Factor Authentication settings. First admin sign-in displays a QR code/setup key; subsequent sign-ins require the six-digit code. Database policies independently require an AAL2 session.
6. Admin login uses email and password only. Social sign-in is not offered there. Creator sign-in still uses the configured email/OAuth providers.
7. Add moderators or additional owners from the owner-only Admins tab by the email of an existing Supabase Auth user. At least one owner must remain.
8. Supabase MFA verification and password policies should be reviewed before going live. Admin sessions are held in sessionStorage (not localStorage) and sign out after 30 minutes without activity. The login screen applies a short in-memory retry pause; Supabase also applies server-side Auth rate limits.

Configuration and files
- supabase-config.js contains the browser-safe project URL and publishable key. It keeps liveAuthReady false, pendingCanBrowse false, and includes an editable reviewTimingText.
- To rename the obscure admin pages, change only adminPaths.login and adminPaths.dashboard in supabase-config.js, rename the two corresponding HTML files to match, then update the Supabase redirect allow-list and robots.txt paths. Keep robots noindex and Disallow entries in place.
- pendingCanBrowse defaults to false. Pending creators see the review state and cannot browse or apply. The review estimate is a configurable text value, not a service guarantee.
- Admin actions and campaign text are recorded in the database audit log. Campaign descriptions are stored in the language entered by the admin; they are not automatically translated.
- Signed agreement snapshots/PDF copies remain in the private creator-contracts bucket. Admin review uses a short-lived (60-second) signed URL. Creator portfolios are links only; no portfolio file upload UI is present.
- The campaign-thumbnails bucket is public-read for display, but upload, replacement and deletion are limited to AAL2 admins. It accepts JPEG, PNG or WebP up to 2 MB.
- The legacy creator_profiles contact_method constraint still permits the old value phone for existing records. The new site writes email only; there is no SMS/phone sign-up. This is retained for backward compatibility rather than rewriting historic rows.
- Rejection, suspension and portfolio change requests are shown in the creator's in-app state. Sending email notifications is optional future work and would require a Supabase Edge Function plus an email provider such as Resend.

Manual test checklist
1. With liveAuthReady false, preview both onboarding screens, campaign sample cards, detail modal, filters, and the admin sample dashboard.
2. Create a new creator account and verify email. Sign and save the agreement; submit only an HTTPS portfolio link. Confirm the portal hands off to campaigns.html and the campaign page shows the pending state with no Apply action.
3. Sign in as a bootstrapped admin. Enrol TOTP, confirm the first code, sign out, and sign in again with a fresh code. Confirm an AAL1 session cannot use admin database functions.
4. Open the creator queue. Confirm sensitive payout details are masked. Reveal them and check the audit log. Open the agreement using the signed link and inspect the user-supplied portfolio only after reviewing its destination.
5. Approve the agreement and portfolio components. Confirm the creator is approved only after both are approved and then sees published campaigns. Reject a creator with a reason and confirm the creator sees the reason. Request portfolio changes, resubmit a link, and confirm it returns to pending review. Suspend and reinstate a test creator.
6. Using a creator account, open both admin file paths and try admin RPCs and status updates directly. The page should show the generic not-found state; RLS, grants and MFA checks should reject admin data/actions.
7. Create a draft campaign and confirm creators cannot see it. Publish it and confirm an approved creator can see its card/detail. Test search, category/platform filters, deadline sorting, empty state, and keyboard modal controls.
8. Upload, replace and remove a valid thumbnail. Confirm wrong MIME types and files over 2 MB are rejected, alt text is required, and the old object is removed after replacement.
9. Apply with a short pitch, confirm the admin sees it, shortlist/decline it, and withdraw as creator. Confirm pending/rejected/suspended creators cannot apply.
10. At 360px viewport, use the pages and forms with keyboard navigation; verify visible focus, useful labels, and reduced-motion behavior.

Changelog
- creator-portal.html: routes completed onboarding to campaigns, loads review-change requests for editing, saves agreement review metadata, exposes Campaigns only to approved creators, and supports a direct sign-in URL.
- index.html: refreshed navigation and split hero with an illustrative creator-hub preview, benefit strip and campaign entry point, inspired by modern creator-platform layouts.
- campaigns.html: new responsive campaign board, filters, accessible detail dialog, approval gate, demo samples, apply/withdraw flow.
- vf-admin-gate-k8m2q.html: new email/password admin sign-in, required TOTP setup/challenge, generic denial, and retry throttling.
- vf-admin-desk-k8m2q.html: new review queue, approval tools, campaigns editor and thumbnail controls, applications, owner admin management, audit viewer and idle sign-out.
- supabase-admin-setup.sql: new idempotent RLS/MFA/admin/campaign/application/audit/storage migration.
- supabase-config.js: pinned Supabase JS URL, campaign/review/admin paths and policy flags.
- assets/translations-de.js and assets/translations-es.js: German and Spanish entries for new creator, campaign and admin interfaces.
- assets/language-switcher.js and all five HTML pages: accessible flag-and-code language menu with a styled dropdown, selected-language check, and keyboard controls.
- robots.txt: blocks indexing/crawling of admin page paths.
- README-creator-portal.txt: setup, deployment, owner bootstrap, MFA, redirects, limits and manual checklist.
- Existing coaching, creator growth, video, brand and agreement content, logo and brand assets are preserved within the refreshed layout.

Free-tier notes
- No SMS provider is configured or needed. Email and OAuth are configured in Supabase Auth.
- The campaign thumbnail limit is set to 2 MB per object. Monitor your project's free storage and bandwidth allowances in the current Supabase dashboard; quotas can change.
- Supabase Free projects can pause after inactivity. Check current plan limits before launch, and resume the project if it pauses.
- Email delivery and custom OAuth each have provider-specific setup and limits. Resend email notifications are optional and are not part of this v1.
- Supabase JS is pinned to 2.118.0 and loaded from esm.sh; the package version is documented at https://www.npmjs.com/package/@supabase/supabase-js.



