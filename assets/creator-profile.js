(() => {
  const cfg = window.VIDFLUENCER_CONFIG || {}
  const t = value => window.VidfluencerLanguage?.t(value) || value
  const button = document.querySelector('#account-avatar')
  if (!button || !cfg.supabaseUrl || !cfg.publishableKey) return

  const style = document.createElement('style')
  style.textContent = `
    #account-avatar{padding:0;overflow:hidden;cursor:pointer}#account-avatar img{width:100%;height:100%;display:block;object-fit:cover;border-radius:50%}
    .vf-profile-overlay{position:fixed;inset:0;z-index:120;display:grid;place-items:center;padding:18px;background:rgb(17 24 45 / .38);backdrop-filter:blur(8px)}.vf-profile-overlay[hidden]{display:none!important}
    .vf-profile-dialog{width:min(760px,100%);max-height:min(90vh,900px);overflow:auto;padding:24px;border:1px solid #e3e7f2;border-radius:25px;background:#fff;box-shadow:0 24px 80px rgb(17 24 45 / .24);color:#11182d}
    .vf-profile-head{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:18px}.vf-profile-head h2{margin:0;font-size:24px;letter-spacing:-.04em}.vf-profile-close{width:40px;height:40px;border:0;border-radius:50%;background:#f3f5fb;color:#34405a;font-size:24px;cursor:pointer}
    .vf-profile-section{margin:16px 0;padding:18px;border:1px solid #e5e8f1;border-radius:18px;background:linear-gradient(145deg,#fff,#fbfcff)}.vf-profile-section h3{margin:0 0 12px;font-size:17px;letter-spacing:-.025em}.vf-profile-muted{margin:5px 0;color:#667089;font-size:13px;line-height:1.5}.vf-profile-fields{display:grid;grid-template-columns:1fr 1fr;gap:10px}.vf-profile-field{display:grid;gap:6px;min-width:0;margin:8px 0}.vf-profile-field label{font-size:12px;font-weight:700;color:#46516a}.vf-profile-field input,.vf-profile-field select{width:100%;min-height:44px;padding:10px 13px;border:1px solid #dfe4f0;border-radius:14px;background:#fff;color:#172039;font:inherit}.vf-profile-field input:focus,.vf-profile-field select:focus{outline:none;border-color:#9aa8ef;box-shadow:0 0 0 3px rgb(64 85 214 / .12)}
    .vf-profile-photo-row{display:flex;align-items:center;gap:16px;margin:10px 0}.vf-profile-photo{width:76px;height:76px;display:grid;place-items:center;flex:none;overflow:hidden;border:1px solid #dfe4f7;border-radius:50%;background:#eef0ff;color:#4055d6;font-weight:800}.vf-profile-photo img{width:100%;height:100%;object-fit:cover}.vf-profile-note{min-height:18px;margin:9px 0;color:#667089;font-size:12px}.vf-profile-note.error{color:#a3323c}.vf-social-list{display:grid;gap:10px}.vf-social-row{display:grid;grid-template-columns:minmax(110px,.7fr) minmax(120px,1fr) minmax(180px,1.4fr) auto;gap:8px;align-items:center;padding:10px;border:1px solid #e7eaf2;border-radius:15px;background:#fff}.vf-social-row input,.vf-social-row select{width:100%;min-width:0;min-height:40px;padding:9px 10px;border:1px solid #e2e6f0;border-radius:12px;background:#fff;color:#172039;font:inherit}.vf-earnings-summary{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:9px;margin:12px 0}.vf-earning-total{padding:13px;border:1px solid #e7eaf2;border-radius:15px;background:#f9faff}.vf-earning-total span{display:block;color:#68738b;font-size:11px;font-weight:700}.vf-earning-total strong{display:block;margin-top:5px;font-size:18px;letter-spacing:-.03em}.vf-earning-list{display:grid;gap:8px}.vf-earning-row{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:11px 12px;border:1px solid #e8eaf2;border-radius:13px}.vf-earning-row strong{display:block}.vf-earning-row small{color:#6b758c}.vf-profile-danger{border-color:#f0dfe2;background:#fffafb}.vf-profile-warning{padding:12px 13px;border-radius:14px;background:#fff3f3;color:#87323c;font-size:13px;line-height:1.5}.vf-profile-actions{display:flex;align-items:center;gap:9px;flex-wrap:wrap;margin-top:13px}.vf-profile-btn{min-height:42px;padding:10px 16px;border:1px solid #dfe4f0;border-radius:999px;background:#fff;color:#26324d;font-family:inherit;font-size:13px;line-height:1.2;font-weight:700;cursor:pointer}.vf-profile-btn.primary{border-color:#4055d6;background:#4055d6;color:#fff}.vf-profile-btn.danger{border-color:#efcdd2;background:#fff3f4;color:#a3323c}.vf-profile-btn:disabled{opacity:.55;cursor:not-allowed}.vf-profile-check{display:flex;align-items:flex-start;gap:9px;margin:12px 0;color:#793039;font-size:13px;line-height:1.5}.vf-profile-check input{margin-top:3px}
    @media(max-width:620px){.vf-profile-dialog{padding:17px;border-radius:20px}.vf-profile-fields{grid-template-columns:1fr}.vf-social-row{grid-template-columns:1fr 1fr}.vf-social-row input[type=url]{grid-column:1/-1}.vf-earnings-summary{grid-template-columns:1fr}.vf-earning-total{display:flex;justify-content:space-between;align-items:center}.vf-earning-total strong{margin:0}}
  `
  document.head.append(style)

  const overlay = document.createElement('div')
  overlay.className = 'vf-profile-overlay'
  overlay.hidden = true
  overlay.innerHTML = `<section class="vf-profile-dialog" role="dialog" aria-modal="true" aria-labelledby="vf-profile-title">
    <header class="vf-profile-head"><h2 id="vf-profile-title" data-vf-i18n="Creator profile">${t('Creator profile')}</h2><button type="button" class="vf-profile-close" aria-label="${t('Close')}" data-vf-aria="Close">×</button></header>
    <section class="vf-profile-section"><h3 data-vf-i18n="Profile picture">${t('Profile picture')}</h3><div class="vf-profile-photo-row"><div class="vf-profile-photo" id="vf-photo-preview"></div><p class="vf-profile-muted" data-vf-i18n="Choose initials, a photo returned by a linked account, or upload an image. No extra provider permissions are requested.">${t('Choose initials, a photo returned by a linked account, or upload an image. No extra provider permissions are requested.')}</p></div>
      <div class="vf-profile-field"><label for="vf-photo-source" data-vf-i18n="Picture source">${t('Picture source')}</label><select id="vf-photo-source"></select></div>
      <div class="vf-profile-field" id="vf-photo-upload-field" hidden><label for="vf-photo-upload" data-vf-i18n="Upload profile picture - JPG, PNG or WebP - max 2 MB">${t('Upload profile picture - JPG, PNG or WebP - max 2 MB')}</label><input id="vf-photo-upload" type="file" accept="image/jpeg,image/png,image/webp"></div><p class="vf-profile-note" id="vf-photo-note" role="status"></p>
    </section>
    <section class="vf-profile-section"><h3 data-vf-i18n="Social media links">${t('Social media links')}</h3><p class="vf-profile-muted" data-vf-i18n="Add a channel, handle and profile link. You can edit or remove these any time.">${t('Add a channel, handle and profile link. You can edit or remove these any time.')}</p><div class="vf-social-list" id="vf-social-list"></div><div class="vf-profile-actions"><button type="button" class="vf-profile-btn" id="vf-add-social" data-vf-i18n="Add social link">${t('Add social link')}</button></div>
    </section>
    <section class="vf-profile-section"><h3 data-vf-i18n="Earnings">${t('Earnings')}</h3><p class="vf-profile-muted" data-vf-i18n="Payments are tracked in USD. Total earned combines pending and paid amounts.">${t('Payments are tracked in USD. Total earned combines pending and paid amounts.')}</p><div class="vf-earnings-summary" id="vf-earnings-summary"></div><div class="vf-earning-list" id="vf-earnings-list"></div>
    </section>
    <section class="vf-profile-section vf-profile-danger"><h3 data-vf-i18n="Delete account and data">${t('Delete account and data')}</h3><p class="vf-profile-muted" data-vf-i18n="Your creator profile, applications, uploaded files, profile picture and social links will be permanently deleted. Financial records will be kept for admin accounting and anonymized.">${t('Your creator profile, applications, uploaded files, profile picture and social links will be permanently deleted. Financial records will be kept for admin accounting and anonymized.')}</p>
      <div id="vf-delete-password-step"><div class="vf-profile-field" id="vf-delete-password-field"><label for="vf-delete-password" data-vf-i18n="Confirm your password">${t('Confirm your password')}</label><input id="vf-delete-password" type="password" autocomplete="current-password"></div><p class="vf-profile-muted" id="vf-oauth-delete-note" data-vf-i18n="This account has no password sign-in. Reauthenticate with one of your linked providers to continue." hidden>${t('This account has no password sign-in. Reauthenticate with one of your linked providers to continue.')}</p><div class="vf-profile-actions" id="vf-reauth-actions"></div><button type="button" class="vf-profile-btn danger" id="vf-verify-delete" data-vf-i18n="Verify and continue">${t('Verify and continue')}</button></div>
      <div id="vf-delete-final-step" hidden><p class="vf-profile-warning" data-vf-i18n="Permanent warning: account deletion cannot be undone. Your creator profile and applications will be removed. Existing earnings records will remain without your name or email.">${t('Permanent warning: account deletion cannot be undone. Your creator profile and applications will be removed. Existing earnings records will remain without your name or email.')}</p><label class="vf-profile-check"><input id="vf-delete-check" type="checkbox"><span data-vf-i18n="I understand this permanently deletes my creator account and data.">${t('I understand this permanently deletes my creator account and data.')}</span></label><button type="button" class="vf-profile-btn danger" id="vf-delete-final" data-vf-i18n="Delete account permanently">${t('Delete account permanently')}</button></div><p class="vf-profile-note" id="vf-delete-note" role="status"></p>
    </section>
    <footer class="vf-profile-actions"><button type="button" class="vf-profile-btn primary" id="vf-profile-save" data-vf-i18n="Save profile">${t('Save profile')}</button></footer>
  </section>`
  document.body.append(overlay)

  let client, user, profile, profileExists = false, identityPhotos = {}, socialRows = [], earningsRows = [], uploadFile = null, lastFocus = null
  let currentAvatarUrl = ''
  const $ = selector => overlay.querySelector(selector)
  const locale = () => ({de:'de-DE',es:'es-ES'})[window.VidfluencerLanguage?.language] || 'en-GB'
  const initialsFor = name => { const parts = String(name || 'Creator').trim().split(/\s+/).filter(Boolean); return (parts.length > 1 ? parts[0][0] + parts.at(-1)[0] : (parts[0] || 'C').slice(0,2)).toUpperCase() }
  const say = (el, message, error = false) => { el.textContent = t(message); el.classList.toggle('error', error) }
  const safeImage = value => { try { const url = new URL(value); return ['https:','http:'].includes(url.protocol) ? url.href : '' } catch { return '' } }
  const identitySource = provider => user?.identities?.find(identity => identity.provider === provider || identity.identity_data?.provider === provider)
  function collectProviderPhotos() {
    identityPhotos = {}
    for (const provider of ['google','azure','discord']) {
      const identity = identitySource(provider)
      const data = identity?.identity_data || {}
      const url = safeImage(data.avatar_url || data.picture || data.photo_url || data.profile_image_url || '')
      if (identity && url) identityPhotos[provider] = url
    }
  }
  function renderAvatar(url = '') {
    currentAvatarUrl = url || ''
    const name = profile?.full_name || user?.user_metadata?.full_name || user?.user_metadata?.name || user?.email || 'Creator'
    button.replaceChildren()
    if (url) {
      const img = document.createElement('img'); img.src = url; img.alt = ''; img.referrerPolicy = 'no-referrer'; img.onerror = () => { currentAvatarUrl = ''; renderAvatar('') }; button.append(img)
    } else button.textContent = initialsFor(name)
    button.title = name
    button.setAttribute('aria-label', t('Open creator profile for') + ' ' + name)
    button.hidden = false
  }
  async function resolveAvatar(source, path) {
    if (source === 'upload' && path) {
      const result = await client.storage.from('creator-avatars').createSignedUrl(path, 3600)
      if (result.error) throw result.error
      return result.data.signedUrl
    }
    return identityPhotos[source] || ''
  }
  function renderPhotoSource() {
    const select = $('#vf-photo-source'); const keep = select.value || profile?.profile_picture_source || 'initials'; select.replaceChildren()
    const items = [['initials','Initials'],['google','Google photo'],['azure','Microsoft photo'],['discord','Discord photo'],['upload','Upload a picture']]
    for (const [value,label] of items) {
      const option = document.createElement('option'); option.value = value; option.textContent = t(label)
      const provider = value === 'azure' ? 'azure' : value
      if (['google','azure','discord'].includes(value) && !identitySource(provider)) option.disabled = true
      select.append(option)
    }
    select.value = [...select.options].some(option => option.value === keep && !option.disabled) ? keep : 'initials'
    $('#vf-photo-upload-field').hidden = select.value !== 'upload'
  }
  async function updatePhotoPreview() {
    const source = $('#vf-photo-source').value; $('#vf-photo-upload-field').hidden = source !== 'upload'
    try {
      if (source === 'upload' && uploadFile) {
        const url = URL.createObjectURL(uploadFile); $('#vf-photo-preview').replaceChildren(Object.assign(document.createElement('img'),{src:url,alt:''})); say($('#vf-photo-note'),''); return
      }
      const url = await resolveAvatar(source, source === profile?.profile_picture_source ? profile?.profile_picture_path : null)
      const box = $('#vf-photo-preview'); box.replaceChildren()
      if (url) { const img=document.createElement('img');img.src=url;img.alt='';box.append(img);say($('#vf-photo-note'),'') }
      else { box.textContent=initialsFor(profile?.full_name||user?.email); say($('#vf-photo-note'),source==='initials'?'Your account initials will be shown.':'This linked account does not provide a profile photo, so initials will be shown instead.') }
    } catch (error) { say($('#vf-photo-note'),error.message||'Profile picture could not be loaded.',true) }
  }
  const platforms = ['YouTube','TikTok','Instagram','X','Twitch','Discord']
  function addSocialRow(value = {}) {
    const row = document.createElement('div'); row.className='vf-social-row'
    const select=document.createElement('select');select.setAttribute('aria-label',t('Social platform'));select.dataset.vfAria='Social platform';for(const platform of platforms){const option=document.createElement('option');option.value=platform;option.textContent=platform;select.append(option)}
    const handle=document.createElement('input');handle.type='text';handle.maxLength=100;handle.placeholder=t('Handle');handle.dataset.vfPlaceholder='Handle';handle.setAttribute('aria-label',t('Handle'));handle.dataset.vfAria='Handle';handle.value=value.handle||''
    const url=document.createElement('input');url.type='url';url.maxLength=500;url.placeholder='https://';url.setAttribute('aria-label',t('Profile link'));url.dataset.vfAria='Profile link';url.value=value.url||''
    const remove=document.createElement('button');remove.type='button';remove.className='vf-profile-btn danger';remove.textContent=t('Remove');remove.setAttribute('aria-label',t('Remove social link'));remove.dataset.vfI18n='Remove';remove.dataset.vfAria='Remove social link';remove.onclick=()=>{row.remove();socialRows=socialRows.filter(item=>item.row!==row)}
    if(value.platform&&platforms.includes(value.platform))select.value=value.platform
    row.append(select,handle,url,remove);$('#vf-social-list').append(row);socialRows.push({row,select,handle,url,remove})
  }
  function renderEarnings(rows) {
    rows=rows||[]
    const pending=rows.filter(row=>row.status==='pending').reduce((sum,row)=>sum+Number(row.amount_usd||0),0)
    const paid=rows.filter(row=>row.status==='paid').reduce((sum,row)=>sum+Number(row.amount_usd||0),0)
    const summary=$('#vf-earnings-summary');summary.replaceChildren()
    for(const [label,value] of [['Pending',pending],['Paid',paid],['Total earned',pending+paid]]){const card=document.createElement('div');card.className='vf-earning-total';const name=document.createElement('span');name.textContent=t(label);const amount=document.createElement('strong');amount.textContent=new Intl.NumberFormat(locale(),{style:'currency',currency:'USD'}).format(value);card.append(name,amount);summary.append(card)}
    const list=$('#vf-earnings-list');list.replaceChildren()
    const visible=rows.filter(row=>row.status==='pending'||row.status==='paid')
    if(!visible.length){const empty=document.createElement('p');empty.className='vf-profile-muted';empty.textContent=t('No earnings have been recorded yet.');list.append(empty);return}
    for(const earning of visible){const row=document.createElement('div');row.className='vf-earning-row';const info=document.createElement('div');const title=document.createElement('strong');title.textContent=earning.campaign_title_snapshot||t('Campaign');const meta=document.createElement('small');meta.textContent=t(earning.status==='paid'?'Paid':'Pending')+(earning.paid_at?' · '+new Date(earning.paid_at).toLocaleDateString(locale()):'');info.append(title,meta);const amount=document.createElement('strong');amount.textContent=new Intl.NumberFormat(locale(),{style:'currency',currency:'USD'}).format(Number(earning.amount_usd)||0);row.append(info,amount);list.append(row)}
  }
  async function loadProfile() {
    collectProviderPhotos()
    const result=await client.from('creator_profiles').select('full_name,profile_picture_source,profile_picture_path,social_links').eq('id',user.id).maybeSingle()
    if(result.error)throw result.error
    profile=result.data;profileExists=Boolean(profile)
    if(!profile){profile={full_name:user.user_metadata?.full_name||user.user_metadata?.name||user.email||'Creator',contact_method:'email',profile_picture_source:'initials',profile_picture_path:null,social_links:[]};say($('#vf-delete-note'),'Your creator profile has not been created yet. Complete setup before changing profile details.')}
    const source=profile.profile_picture_source||'initials';renderAvatar(await resolveAvatar(source,profile.profile_picture_path));renderPhotoSource();await updatePhotoPreview()
    $('#vf-social-list').replaceChildren();socialRows=[]
    const saved=Array.isArray(profile.social_links)?profile.social_links:[]
    if(saved.length)saved.forEach(addSocialRow);else addSocialRow()
    const earnings=await client.from('creator_earnings').select('campaign_title_snapshot,amount_usd,status,paid_at,created_at').eq('creator_id',user.id).order('created_at',{ascending:false})
    if(earnings.error)throw earnings.error
    earningsRows=earnings.data||[];renderEarnings(earningsRows)
    const hasPassword=(user.identities||[]).some(identity=>identity.provider==='email')
    $('#vf-delete-password-field').hidden=!hasPassword;$('#vf-verify-delete').hidden=!hasPassword;$('#vf-oauth-delete-note').hidden=hasPassword
    const oauthActions=$('#vf-reauth-actions');oauthActions.replaceChildren()
    if(!hasPassword){for(const provider of ['google','azure','discord']){if(!identitySource(provider))continue;const reauth=document.createElement('button');reauth.type='button';reauth.className='vf-profile-btn';reauth.textContent=t('Reauthenticate with')+' '+t(provider==='azure'?'Microsoft':provider==='google'?'Google':'Discord');reauth.onclick=()=>reauthWithProvider(provider);oauthActions.append(reauth)}}
    $('#vf-delete-final-step').hidden=true;$('#vf-delete-password-step').hidden=false;$('#vf-delete-check').checked=false
    const query=new URLSearchParams(location.search)
    const intent=sessionStorage.getItem('vidfluencer-delete-account-user')
    if(query.get('profile-delete-reauth')==='1'&&intent===user.id){const fresh=await isRecentAuth();if(fresh){$('#vf-delete-password-step').hidden=true;$('#vf-delete-final-step').hidden=false;say($('#vf-delete-note'),'Your sign-in was refreshed. Review the warning and confirm deletion below.')}else say($('#vf-delete-note'),'Reauthentication did not finish. Please try again.',true)}
  }
  async function isRecentAuth() {
    const claims=await client.auth.getClaims();const authTime=Number(claims.data?.claims?.auth_time)
    return Number.isFinite(authTime)&&Math.floor(Date.now()/1000)-authTime<=600&&authTime<=Math.floor(Date.now()/1000)
  }
  async function reauthWithProvider(provider) {
    sessionStorage.setItem('vidfluencer-delete-account-user',user.id)
    const redirect=new URL(location.pathname,location.origin);redirect.search='?profile-delete-reauth=1'
    const result=await client.auth.signInWithOAuth({provider,options:{redirectTo:redirect.href}})
    if(result.error)say($('#vf-delete-note'),result.error.message,true)
  }
  async function openProfile() {
    lastFocus=document.activeElement;overlay.hidden=false;document.body.style.overflow='hidden';$('#vf-profile-close').focus()
    try{await loadProfile()}catch(error){say($('#vf-delete-note'),error.message||'Profile could not be loaded.',true)}
  }
  function closeProfile(){overlay.hidden=true;document.body.style.overflow='';button.focus()}
  function refreshProfileTranslations(){
    overlay.querySelectorAll('[data-vf-i18n]').forEach(el=>{el.textContent=t(el.dataset.vfI18n)})
    overlay.querySelectorAll('[data-vf-aria]').forEach(el=>{el.setAttribute('aria-label',t(el.dataset.vfAria))})
    overlay.querySelectorAll('[data-vf-placeholder]').forEach(el=>{el.setAttribute('placeholder',t(el.dataset.vfPlaceholder))})
    if(user){renderPhotoSource();renderAvatar(currentAvatarUrl);renderEarnings(earningsRows);socialRows.forEach(({remove})=>{remove.textContent=t('Remove');remove.setAttribute('aria-label',t('Remove social link'))})}
  }
  async function saveProfile() {
    if(!profile){say($('#vf-delete-note'),'Your creator profile has not been created yet. Complete setup before changing profile details.',true);return}
    const source=$('#vf-photo-source').value;let path=source==='upload'?profile.profile_picture_path:null;let newPath=null
    if(source==='upload'&&!uploadFile&&profile.profile_picture_source!=='upload'){say($('#vf-photo-note'),'Choose an image file before using upload.',true);return}
    if(source==='upload'&&uploadFile){if(!['image/jpeg','image/png','image/webp'].includes(uploadFile.type)||uploadFile.size>2*1024*1024){say($('#vf-photo-note'),'Choose a JPG, PNG or WebP image no larger than 2 MB.',true);return}newPath=`${user.id}/${crypto.randomUUID()}.${uploadFile.type==='image/png'?'png':uploadFile.type==='image/webp'?'webp':'jpg'}`;const uploaded=await client.storage.from('creator-avatars').upload(newPath,uploadFile,{contentType:uploadFile.type,upsert:false});if(uploaded.error){say($('#vf-photo-note'),uploaded.error.message,true);return}path=newPath}
    const links=[]
    for(const item of socialRows){const platform=item.select.value,handle=item.handle.value.trim(),rawUrl=item.url.value.trim();if(!handle&&!rawUrl)continue;if(!handle||!rawUrl){say($('#vf-delete-note'),t('Add both a handle and a profile link, or remove the empty row.'),true);if(newPath)await client.storage.from('creator-avatars').remove([newPath]);return}let parsed;try{parsed=new URL(rawUrl)}catch{say($('#vf-delete-note'),'Enter a valid social profile link.',true);if(newPath)await client.storage.from('creator-avatars').remove([newPath]);return}if(parsed.protocol!=='https:'){say($('#vf-delete-note'),'Social profile links must begin with https://.',true);if(newPath)await client.storage.from('creator-avatars').remove([newPath]);return}links.push({platform,handle,url:parsed.href})}
    const oldPath=profile.profile_picture_path
    const payload={profile_picture_source:source,profile_picture_path:source==='upload'?path:null,social_links:links}
    const result=profileExists?await client.from('creator_profiles').update(payload).eq('id',user.id):await client.from('creator_profiles').upsert({id:user.id,full_name:profile.full_name||user.user_metadata?.full_name||user.user_metadata?.name||user.email||'Creator',contact_method:'email',...payload},{onConflict:'id'})
    if(result.error){if(newPath)await client.storage.from('creator-avatars').remove([newPath]);say($('#vf-delete-note'),result.error.message,true);return}
    profile={...profile,...payload};profileExists=true;uploadFile=null;$('#vf-photo-upload').value='';say($('#vf-delete-note'),'Profile saved.');
    if(oldPath&&oldPath!==payload.profile_picture_path){const removed=await client.storage.from('creator-avatars').remove([oldPath]);if(removed.error)say($('#vf-photo-note'),removed.error.message,true)}
    try{currentAvatarUrl=await resolveAvatar(source,payload.profile_picture_path);renderAvatar(currentAvatarUrl)}catch{currentAvatarUrl='';renderAvatar('')}
    await updatePhotoPreview()
  }
  async function verifyDelete() {
    const password=$('#vf-delete-password').value
    if(!password){say($('#vf-delete-note'),'Enter your password to continue.',true);return}
    const result=await client.auth.signInWithPassword({email:user.email,password})
    $('#vf-delete-password').value=''
    if(result.error){say($('#vf-delete-note'),'The password could not be verified. Check it and try again.',true);return}
    sessionStorage.setItem('vidfluencer-delete-account-user',user.id)
    if(!await isRecentAuth()){say($('#vf-delete-note'),'For your security, sign in again before deleting this account.',true);return}
    $('#vf-delete-password-step').hidden=true;$('#vf-delete-final-step').hidden=false;say($('#vf-delete-note'),'Password verified. Review the warning and confirm deletion below.')
  }
  async function deleteAccount() {
    if(!$('#vf-delete-check').checked){say($('#vf-delete-note'),'Confirm the permanent deletion warning before continuing.',true);return}
    if(sessionStorage.getItem('vidfluencer-delete-account-user')!==user.id||!await isRecentAuth()){say($('#vf-delete-note'),'For your security, sign in again before deleting this account.',true);$('#vf-delete-final-step').hidden=true;$('#vf-delete-password-step').hidden=false;return}
    if(!window.confirm(t('This permanently deletes your creator account and uploaded data. Financial records will remain anonymized. Continue?')))return
    const action=$('#vf-delete-final');action.disabled=true;say($('#vf-delete-note'),'Deleting your account and files…')
    const response=await client.functions.invoke('delete-creator-account',{method:'POST'})
    if(response.error||response.data?.error){action.disabled=false;say($('#vf-delete-note'),response.data?.error||response.error?.message||'Account deletion could not be completed.',true);return}
    sessionStorage.removeItem('vidfluencer-delete-account-user')
    await client.auth.signOut({scope:'local'}).catch(()=>{})
    location.replace(new URL('index.html',document.baseURI).href)
  }
  async function init() {
    try {
      const module=await import(cfg.supabaseJsUrl||'https://esm.sh/@supabase/supabase-js@2.118.0')
      client=module.createClient(cfg.supabaseUrl,cfg.publishableKey,{auth:{storage:window.localStorage,persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}})
      const session=await client.auth.getSession();user=session.data.session?.user
      if(!user)return
      const current=await client.from('creator_profiles').select('full_name,profile_picture_source,profile_picture_path').eq('id',user.id).maybeSingle()
      if(!current.error){profile=current.data;renderAvatar(current.data?await resolveAvatar(current.data.profile_picture_source||'initials',current.data.profile_picture_path):'')}
      button.addEventListener('click',openProfile);$('#vf-profile-close').addEventListener('click',closeProfile);overlay.addEventListener('click',event=>{if(event.target===overlay)closeProfile()});document.addEventListener('keydown',event=>{if(!overlay.hidden&&event.key==='Escape')closeProfile()})
      $('#vf-photo-source').addEventListener('change',updatePhotoPreview);$('#vf-photo-upload').addEventListener('change',()=>{const file=$('#vf-photo-upload').files?.[0];if(!file)return;if(!['image/jpeg','image/png','image/webp'].includes(file.type)||file.size>2*1024*1024){$('#vf-photo-upload').value='';uploadFile=null;say($('#vf-photo-note'),'Choose a JPG, PNG or WebP image no larger than 2 MB.',true);return}uploadFile=file;updatePhotoPreview()})
      $('#vf-add-social').addEventListener('click',()=>addSocialRow());$('#vf-profile-save').addEventListener('click',saveProfile);$('#vf-verify-delete').addEventListener('click',verifyDelete);$('#vf-delete-final').addEventListener('click',deleteAccount)
      if(new URLSearchParams(location.search).get('profile-delete-reauth')==='1'&&sessionStorage.getItem('vidfluencer-delete-account-user'))openProfile()
    } catch (error) { console.error('Creator profile could not start.',error) }
  }
  document.addEventListener('vidfluencer:languagechange',()=>{refreshProfileTranslations()})
  init()
})()
