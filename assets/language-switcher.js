(() => {
  const clean = value => value.replace(/\s+/g, ' ').trim();
  const choices = {
    en:{flag:'🇺🇸',code:'EN',name:'English (US)',search:'English United States EN'},
    de:{flag:'🇩🇪',code:'DE',name:'Deutsch',search:'German Deutsch DE'},
    es:{flag:'🇪🇸',code:'ES',name:'Español',search:'Spanish Español ES'},
    bg:{flag:'🇧🇬',code:'BG',name:'Български',search:'Bulgarian Български BG'},
    hr:{flag:'🇭🇷',code:'HR',name:'Hrvatski',search:'Croatian Hrvatski HR'},
    cs:{flag:'🇨🇿',code:'CS',name:'Čeština',search:'Czech Čeština CS'},
    da:{flag:'🇩🇰',code:'DA',name:'Dansk',search:'Danish Dansk DA'},
    nl:{flag:'🇳🇱',code:'NL',name:'Nederlands',search:'Dutch Nederlands NL'},
    et:{flag:'🇪🇪',code:'ET',name:'Eesti',search:'Estonian Eesti ET'},
    fi:{flag:'🇫🇮',code:'FI',name:'Suomi',search:'Finnish Suomi FI'},
    fr:{flag:'🇫🇷',code:'FR',name:'Français',search:'French Français FR'},
    el:{flag:'🇬🇷',code:'EL',name:'Ελληνικά',search:'Greek Ελληνικά EL'},
    hu:{flag:'🇭🇺',code:'HU',name:'Magyar',search:'Hungarian Magyar HU'},
    ga:{flag:'🇮🇪',code:'GA',name:'Gaeilge',search:'Irish Gaeilge GA'},
    it:{flag:'🇮🇹',code:'IT',name:'Italiano',search:'Italian Italiano IT'},
    lv:{flag:'🇱🇻',code:'LV',name:'Latviešu',search:'Latvian Latviešu LV'},
    lt:{flag:'🇱🇹',code:'LT',name:'Lietuvių',search:'Lithuanian Lietuvių LT'},
    mt:{flag:'🇲🇹',code:'MT',name:'Malti',search:'Maltese Malti MT'},
    pl:{flag:'🇵🇱',code:'PL',name:'Polski',search:'Polish Polski PL'},
    pt:{flag:'🇵🇹',code:'PT',name:'Português',search:'Portuguese Português PT'},
    ro:{flag:'🇷🇴',code:'RO',name:'Română',search:'Romanian Română RO'},
    sk:{flag:'🇸🇰',code:'SK',name:'Slovenčina',search:'Slovak Slovenčina SK'},
    sl:{flag:'🇸🇮',code:'SL',name:'Slovenščina',search:'Slovenian Slovenščina SL'},
    sv:{flag:'🇸🇪',code:'SV',name:'Svenska',search:'Swedish Svenska SV'}
  };
  const usStars = Array.from({length:9},(_,row) => {
    const count = row % 2 ? 5 : 6;
    const offset = row % 2 ? 2.2 : 1.2;
    return Array.from({length:count},(_,column) =>
      `<circle cx="${offset + column * 2}" cy="${0.7 + row * 1.2}" r=".31"/>`
    ).join('');
  }).join('');
  const flagArtwork = {
    en:'<rect width="30" height="20" fill="#fff"/><path fill="#b22234" d="M0 0h30v1.54H0zM0 3.08h30v1.54H0zM0 6.15h30v1.54H0zM0 9.23h30v1.54H0zM0 12.31h30v1.54H0zM0 15.38h30v1.54H0zM0 18.46h30V20H0z"/><rect width="12.5" height="10.77" fill="#3c3b6e"/><g fill="#fff">'+usStars+'</g>',
    de:'<rect width="30" height="6.67" fill="#111"/><rect y="6.67" width="30" height="6.66" fill="#d00"/><rect y="13.33" width="30" height="6.67" fill="#ffce00"/>',
    es:'<rect width="30" height="5" fill="#aa151b"/><rect y="5" width="30" height="10" fill="#f1bf00"/><rect y="15" width="30" height="5" fill="#aa151b"/>',
    bg:'<rect width="30" height="6.67" fill="#fff"/><rect y="6.67" width="30" height="6.66" fill="#00966e"/><rect y="13.33" width="30" height="6.67" fill="#d62612"/>',
    hr:'<rect width="30" height="6.67" fill="#ed1c24"/><rect y="6.67" width="30" height="6.66" fill="#fff"/><rect y="13.33" width="30" height="6.67" fill="#171796"/>',
    cs:'<rect width="30" height="10" fill="#fff"/><rect y="10" width="30" height="10" fill="#d7141a"/><path d="M0 0v20L15 10z" fill="#11457e"/>',
    da:'<rect width="30" height="20" fill="#c8102e"/><path d="M9 0h3v20H9zM0 8.5h30v3H0z" fill="#fff"/>',
    nl:'<rect width="30" height="6.67" fill="#ae1c28"/><rect y="6.67" width="30" height="6.66" fill="#fff"/><rect y="13.33" width="30" height="6.67" fill="#21468b"/>',
    et:'<rect width="30" height="6.67" fill="#4891d9"/><rect y="6.67" width="30" height="6.66" fill="#111"/><rect y="13.33" width="30" height="6.67" fill="#fff"/>',
    fi:'<rect width="30" height="20" fill="#fff"/><path d="M8 0h4v20H8zM0 8h30v4H0z" fill="#003580"/>',
    fr:'<rect width="10" height="20" fill="#0055a4"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#ef4135"/>',
    el:'<rect width="30" height="20" fill="#fff"/><path d="M0 0h30v2.2H0zm0 4.45h30v2.2H0zm0 4.45h30v2.2H0zm0 4.45h30v2.2H0zm0 4.45h30v2.2H0z" fill="#0d5eaf"/><rect width="12.2" height="11" fill="#0d5eaf"/><path d="M4.6 0h3v11h-3zM0 4h12.2v3H0z" fill="#fff"/>',
    hu:'<rect width="30" height="6.67" fill="#ce2939"/><rect y="6.67" width="30" height="6.66" fill="#fff"/><rect y="13.33" width="30" height="6.67" fill="#477050"/>',
    ga:'<rect width="10" height="20" fill="#169b62"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#ff883e"/>',
    it:'<rect width="10" height="20" fill="#009246"/><rect x="10" width="10" height="20" fill="#fff"/><rect x="20" width="10" height="20" fill="#ce2b37"/>',
    lv:'<rect width="30" height="8" fill="#9e3039"/><rect y="8" width="30" height="4" fill="#fff"/><rect y="12" width="30" height="8" fill="#9e3039"/>',
    lt:'<rect width="30" height="6.67" fill="#fdb913"/><rect y="6.67" width="30" height="6.66" fill="#006a44"/><rect y="13.33" width="30" height="6.67" fill="#c1272d"/>',
    mt:'<rect width="15" height="20" fill="#fff"/><rect x="15" width="15" height="20" fill="#cf142b"/><path d="M3 2h2v6H3zM1 4h6v2H1z" fill="#888"/>',
    pl:'<rect width="30" height="10" fill="#fff"/><rect y="10" width="30" height="10" fill="#dc143c"/>',
    pt:'<rect width="12" height="20" fill="#006600"/><rect x="12" width="18" height="20" fill="#ff0000"/><circle cx="12" cy="10" r="4.2" fill="#ffcc00"/><circle cx="12" cy="10" r="2.7" fill="#fff"/>',
    ro:'<rect width="10" height="20" fill="#002b7f"/><rect x="10" width="10" height="20" fill="#fcd116"/><rect x="20" width="10" height="20" fill="#ce1126"/>',
    sk:'<rect width="30" height="6.67" fill="#fff"/><rect y="6.67" width="30" height="6.66" fill="#0b4ea2"/><rect y="13.33" width="30" height="6.67" fill="#ee1c25"/>',
    sl:'<rect width="30" height="6.67" fill="#fff"/><rect y="6.67" width="30" height="6.66" fill="#005da4"/><rect y="13.33" width="30" height="6.67" fill="#ed1c24"/>',
    sv:'<rect width="30" height="20" fill="#006aa7"/><path d="M8 0h3v20H8zM0 8h30v3H0z" fill="#fecc00"/>'
  };
  let language = 'en';
  try { language = localStorage.getItem('vidfluencer-language') || 'en'; } catch (_) {}
  if (!choices[language]) language = 'en';
  const textNodes = new Set(), attrs = new Set(), textSources = new WeakMap(), lastTextValues = new WeakMap();
  const attributeSources = new WeakMap(), lastAttributeValues = new WeakMap();
  const reverseWords = new Map();
  const pickers = [], dictionaryLoads = new Map();
  let displayNamesLocale = '';
  let displayNames;
  const scriptUrl = document.currentScript && document.currentScript.src
    ? document.currentScript.src : new URL('assets/language-switcher.js', location.href).href;
  const dictionaryVersion = '20261029-language-refresh-2';
  const dict = () => (window.VidfluencerTranslations || {})[language] || {};
  const t = value => language === 'en' ? value : (dict()[value] || value);

  function refreshReverseWords() {
    reverseWords.clear();
    if (language === 'en') return;
    Object.entries(dict()).forEach(([source,translated]) => {
      const key=clean(translated);
      if (key && !reverseWords.has(key)) reverseWords.set(key,source);
    });
  }
  const canonicalSource = value => reverseWords.get(clean(value)) || value;

  function languageName(code) {
    if (code === 'en' && language === 'en') return choices.en.name;
    try {
      if (displayNamesLocale !== language) {
        displayNames = new Intl.DisplayNames([language],{type:'language'});
        displayNamesLocale = language;
      }
      return displayNames.of(code === 'en' ? 'en-US' : code) || choices[code].name;
    } catch (_) { return choices[code].name; }
  }

  function addStyles() {
    if (document.querySelector('[data-vf-language-styles]')) return;
    const style = document.createElement('style');
    style.dataset.vfLanguageStyles = '';
    style.textContent = [
      '.lang-switcher .lang-menu{display:flex;flex-direction:column;width:min(372px,calc(100vw - 24px));height:auto;max-height:min(70vh,540px);overflow:hidden;padding:10px 10px 2px;border-radius:22px;overscroll-behavior:contain}',
      '.lang-menu-head{display:grid;flex:0 0 auto;gap:8px;padding:2px 2px 2px}',
      '.lang-menu-title{margin:0;color:#11182d;font-size:16px;font-weight:750;line-height:1.25}',
      '.lang-search{width:100%;min-height:42px;box-sizing:border-box;padding:0 13px;border:1px solid #e2e6f0;border-radius:13px;background:#f8f9fc;color:#18213a;font:inherit;font-size:14px;outline:none}',
      '.lang-search:focus{border-color:#5968e8;box-shadow:0 0 0 3px rgb(64 85 214 / .12);background:#fff}',
      '.lang-option-groups{display:block;flex:0 1 auto;min-height:0;max-height:min(calc(70vh - 88px),440px);overflow-y:auto;overscroll-behavior:contain;padding:0 2px 0 1px;scrollbar-width:thin;scrollbar-color:#c5cad5 transparent}',
      '.lang-switcher [role=listbox]{display:block!important;height:auto!important;min-height:0!important;margin:0!important;padding:0!important}',
      '.lang-switcher .lang-group{display:block!important;height:auto!important;min-height:0!important;margin:0!important;padding:0!important}',
      '.lang-switcher .lang-option-grid{display:grid!important;grid-template-columns:minmax(0,1fr)!important;gap:4px!important;align-content:start!important;margin:0!important;padding:0!important}',
      '.lang-switcher .lang-option{display:grid!important;grid-template-columns:24px minmax(0,1fr) auto 10px!important;gap:8px!important;align-items:center!important;width:100%;min-height:40px;margin:0!important;padding:0 9px!important;border:1px solid #e1e4ec!important;border-radius:11px!important;background:#fff;color:#25304a;font:inherit;font-size:13px;font-weight:600;line-height:1.25;text-align:left;cursor:pointer;box-sizing:border-box}',
      '.lang-switcher .lang-option:hover,.lang-switcher .lang-option:focus-visible{background:#f8f9fd;border-color:#c9ceda!important;outline:none}',
      '.lang-switcher .lang-option[aria-selected=true]{background:#f2f4fb;border-color:#c9ceda!important;color:#4055d6}',
      '.lang-option .lang-name{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
      '.lang-code{color:#8690a6;font-size:10px;font-weight:800;letter-spacing:.04em}',
      '.lang-option[aria-selected=true] .lang-code{color:#4055d6}',
      '.lang-check{opacity:0;color:#4055d6;font-size:14px;font-weight:900}',
      '.lang-option[aria-selected=true] .lang-check{opacity:1}',
      '.lang-empty{margin:0;padding:13px 8px;color:#737d91;font-size:13px}',
      '.lang-flag{display:inline-flex!important;align-items:center;justify-content:center;width:23px!important;height:21px!important;border-radius:0!important;box-shadow:none!important;font-size:19px;line-height:1}',
      '.lang-flag svg{display:block;width:100%;height:100%;overflow:hidden}',
      '.lang-option .lang-flag{width:24px!important;height:16px!important;overflow:hidden;border:1px solid #d8dce5;border-radius:3px!important;background:#fff;font-size:15px;line-height:1;box-sizing:border-box}',
      '.lang-native-select{position:absolute!important;width:1px!important;height:1px!important;padding:0!important;margin:-1px!important;overflow:hidden!important;clip:rect(0,0,0,0)!important;white-space:nowrap!important;border:0!important;opacity:0!important}',
      '.lang-switcher [hidden]{display:none!important}',
      '@media(max-width:1100px){.site-header .nav a[href*=\"discord.gg\"]{display:none!important}.site-header .nav{gap:4px}.site-header .nav a:not(.button){padding-inline:8px}}',
      '@media(max-width:520px){.lang-switcher .lang-menu{width:min(352px,calc(100vw - 20px));max-height:min(70vh,520px);padding:9px 9px 2px}.lang-option-groups{max-height:min(calc(70vh - 84px),420px)}.lang-menu-head{gap:7px;padding:1px 1px 2px}.lang-switcher .lang-option-grid{gap:4px!important}.lang-switcher .lang-option{min-height:39px;padding:0 8px!important}}'
    ].join('');
    document.head.append(style);
  }

  function makeFlag(code) {
    const flag = document.createElement('span');
    flag.className = 'lang-flag';
    flag.setAttribute('aria-hidden','true');
    const art = document.createElementNS('http://www.w3.org/2000/svg','svg');
    art.setAttribute('viewBox','0 0 30 20');
    art.setAttribute('preserveAspectRatio','xMidYMid meet');
    art.innerHTML = flagArtwork[code] || flagArtwork.en;
    flag.append(art);
    return flag;
  }

  const translatableAttributes = ['aria-label','aria-description','title','placeholder','alt'];
  function isIgnored(element) {
    return !element || Boolean(element.closest('script,style,noscript,[data-translation-ignore]'));
  }

  function collect(root=document.body) {
    if (!root) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (isIgnored(node.parentElement)) continue;
      if (!textSources.has(node)) textSources.set(node,canonicalSource(node.nodeValue));
      textNodes.add(node);
    }
    const elements = [];
    if (root.nodeType === Node.ELEMENT_NODE) elements.push(root);
    if (root.querySelectorAll) elements.push(...root.querySelectorAll('*'));
    elements.forEach(el => {
      if (isIgnored(el)) return;
      let sources = attributeSources.get(el);
      if (!sources) { sources = new Map(); attributeSources.set(el,sources); }
      translatableAttributes.forEach(name => {
        if (!el.hasAttribute(name) || sources.has(name)) return;
        const item = {el,name,source:canonicalSource(el.getAttribute(name))};
        sources.set(name,item);
        attrs.add(item);
      });
      if (el.matches('input[type="button"],input[type="submit"],input[type="reset"]') && el.hasAttribute('value') && !sources.has('value')) {
        const item = {el,name:'value',source:el.getAttribute('value')};
        item.source=canonicalSource(item.source);
        sources.set('value',item);
        attrs.add(item);
      }
    });
  }

  function observeDynamicContent() {
    const observer = new MutationObserver(records => {
      let shouldTranslate = false;
      records.forEach(record => {
        if (record.type === 'childList') {
          record.addedNodes.forEach(node => {
            if (node.nodeType === Node.TEXT_NODE) {
              if (!isIgnored(node.parentElement)) {
                if (!textSources.has(node)) textSources.set(node,canonicalSource(node.nodeValue));
                textNodes.add(node);
                shouldTranslate = true;
              }
            } else if (node.nodeType === Node.ELEMENT_NODE && !isIgnored(node)) {
              collect(node);
              shouldTranslate = true;
            }
          });
        } else if (record.type === 'characterData') {
          const node = record.target;
          if (!isIgnored(node.parentElement) && lastTextValues.get(node) !== node.nodeValue) {
            textSources.set(node,canonicalSource(node.nodeValue));
            textNodes.add(node);
            shouldTranslate = true;
          }
        } else if (record.type === 'attributes') {
          const {target,name} = record;
          if (isIgnored(target)) return;
          if (name === 'value' && !target.matches('input[type="button"],input[type="submit"],input[type="reset"]')) return;
          let sources = attributeSources.get(target);
          if (!sources) { sources = new Map(); attributeSources.set(target,sources); }
          let item = sources.get(name);
          const current = target.getAttribute(name) || '';
          if (item && lastAttributeValues.get(item) === current) return;
          if (!item) {
            item = {el:target,name,source:canonicalSource(current)};
            sources.set(name,item);
            attrs.add(item);
          } else item.source = canonicalSource(current);
          shouldTranslate = true;
        }
      });
      if (shouldTranslate && language !== 'en') translate();
    });
    observer.observe(document.body,{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:translatableAttributes.concat('value')});
  }

  function syncNativeSelect(select) {
    const selected = choices[select.value] ? select.value : language;
    select.replaceChildren(...Object.entries(choices).map(([value,choice]) => {
      const option = document.createElement('option');
      option.value = value;
      option.textContent = choice.name;
      return option;
    }));
    select.value = selected;
  }

  function enhancePicker(select) {
    syncNativeSelect(select);
    const old = select.parentElement;
    const wrapper = document.createElement('div');
    wrapper.className = 'lang-switcher';
    wrapper.setAttribute('data-lang-switcher','');
    wrapper.setAttribute('data-translation-ignore','');
    old.replaceWith(wrapper);
    wrapper.append(select);
    select.classList.add('lang-native-select');
    select.setAttribute('aria-hidden','true');
    select.tabIndex = -1;

    const trigger = document.createElement('button');
    trigger.type = 'button';
    trigger.className = 'lang-trigger';
    trigger.setAttribute('aria-haspopup','dialog');
    trigger.setAttribute('aria-expanded','false');

    const menu = document.createElement('div');
    menu.className = 'lang-menu';
    menu.setAttribute('role','dialog');
    menu.setAttribute('aria-label',t('Choose a language'));
    menu.hidden = true;

    const menuHead = document.createElement('div');
    menuHead.className = 'lang-menu-head';
    const title = document.createElement('h2');
    title.className = 'lang-menu-title';
    title.textContent = t('Choose a language');
    const search = document.createElement('input');
    search.type = 'search';
    search.className = 'lang-search';
    search.setAttribute('aria-label',t('Search languages'));
    search.placeholder = t('Search languages');
    menuHead.append(title,search);

    const groups = document.createElement('div');
    groups.className = 'lang-option-groups';
    const listbox = document.createElement('div');
    listbox.setAttribute('role','listbox');
    listbox.setAttribute('aria-label',t('Choose a language'));

    const languageGroup = document.createElement('section');
    languageGroup.className = 'lang-group';
    languageGroup.setAttribute('role','group');
    const optionGrid = document.createElement('div');
    optionGrid.className = 'lang-option-grid';
    const empty = document.createElement('p');
    empty.className = 'lang-empty';
    empty.textContent = t('No languages found');
    empty.hidden = true;
    languageGroup.append(optionGrid,empty);
    listbox.append(languageGroup);
    groups.append(listbox);
    menu.append(menuHead,groups);

    const options = [];
    Object.entries(choices).forEach(([value,choice]) => {
      const option = document.createElement('button');
      option.type = 'button';
      option.className = 'lang-option';
      option.setAttribute('role','option');
      option.dataset.value = value;
      option.dataset.search = (choice.search + ' ' + choice.name + ' ' + value).toLowerCase();
      const flag = makeFlag(value);
      const name = document.createElement('span');
      name.className = 'lang-name';
      name.textContent = choice.name;
      const meta = document.createElement('span');
      meta.className = 'lang-code';
      meta.textContent = choice.code;
      const check = document.createElement('span');
      check.className = 'lang-check';
      check.setAttribute('aria-hidden','true');
      check.textContent = '✓';
      option.append(flag,name,meta,check);
      option.addEventListener('click',() => setLanguage(value,true));
      option.addEventListener('keydown',event => {
        const visible = options.filter(item => !item.hidden);
        const index = visible.indexOf(option);
        if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
          event.preventDefault();
          const step = event.key === 'ArrowDown' ? 1 : -1;
          visible[(index + step + visible.length) % visible.length]?.focus();
        } else if (event.key === 'Home' || event.key === 'End') {
          event.preventDefault();
          visible[event.key === 'Home' ? 0 : visible.length - 1]?.focus();
        } else if (event.key === 'Escape') {
          event.preventDefault();
          closeMenu(true);
        }
      });
      options.push(option);
    });

    function renderOptions() {
      const query = clean(search.value || '').toLocaleLowerCase(language);
      options.forEach(option => {
        const value = option.dataset.value;
        const choice = choices[value];
        const localizedName = languageName(value);
        option.querySelector('.lang-name').textContent = localizedName;
        option.dataset.search = (choice.search + ' ' + choice.name + ' ' + localizedName + ' ' + value).toLocaleLowerCase(language);
      });
      const visible = options.filter(option => !query || option.dataset.search.includes(query));
      visible.sort((a,b) => {
        const aCode = a.dataset.value, bCode = b.dataset.value;
        if (aCode === language) return -1;
        if (bCode === language) return 1;
        return languageName(aCode).localeCompare(languageName(bCode),language);
      });
      options.forEach(option => { option.hidden = !visible.includes(option); });
      optionGrid.replaceChildren(...visible);
      languageGroup.hidden = false;
      empty.hidden = Boolean(visible.length);
      title.textContent = t('Choose a language');
      empty.textContent = t('No languages found');
      search.placeholder = t('Search languages');
      search.setAttribute('aria-label',t('Search languages'));
      menu.setAttribute('aria-label',t('Choose a language'));
      listbox.setAttribute('aria-label',t('Choose a language'));
    }

    search.addEventListener('input',renderOptions);
    search.addEventListener('keydown',event => {
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        options.find(option => !option.hidden)?.focus();
      } else if (event.key === 'Escape') {
        event.preventDefault(); closeMenu(true);
      }
    });
    function closeMenu(returnFocus) {
      menu.hidden = true;
      trigger.setAttribute('aria-expanded','false');
      if (returnFocus) trigger.focus();
    }
    function openMenu() {
      menu.hidden = false;
      trigger.setAttribute('aria-expanded','true');
      renderOptions();
      groups.scrollTop = 0;
      search.focus({preventScroll:true});
    }
    trigger.addEventListener('click',() => menu.hidden ? openMenu() : closeMenu(false));
    trigger.addEventListener('keydown',event => {
      if (event.key === 'ArrowDown' || event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        if (menu.hidden) openMenu();
        else search.focus({preventScroll:true});
      }
    });
    document.addEventListener('click',event => {
      if (!wrapper.contains(event.target) && !menu.hidden) closeMenu(false);
    });

    wrapper.append(trigger,menu);
    const picker = {select,trigger,menu,options,search,renderOptions,closeMenu};
    pickers.push(picker);
    return picker;
  }

  function updatePickers() {
    const words = dict();
    pickers.forEach(({select,trigger,options,renderOptions}) => {
      const choice = choices[language] || choices.en;
      select.value = language;
      trigger.replaceChildren();
      const flag = makeFlag(language);
      const code = document.createElement('span');
      code.className = 'lang-code';
      code.textContent = choice.code;
      const chevron = document.createElement('span');
      chevron.className = 'lang-chevron';
      chevron.setAttribute('aria-hidden','true');
      trigger.append(flag,code,chevron);
      trigger.setAttribute('aria-label',words['Change language'] || 'Change language');
      options.forEach(option => option.setAttribute('aria-selected',String(option.dataset.value === language)));
      if (renderOptions) renderOptions();
    });
  }

  function translate() {
    const words = dict();
    textNodes.forEach(node => {
      const source = textSources.get(node);
      if (source == null) return;
      const leading = (source.match(/^\s*/) || [''])[0];
      const trailing = (source.match(/\s*$/) || [''])[0];
      const key = clean(source);
      const next = leading + (language === 'en' ? key : (words[key] || key)) + trailing;
      lastTextValues.set(node,next);
      if (node.nodeValue !== next) node.nodeValue = next;
    });
    attrs.forEach(item => {
      const {el,name,source} = item;
      if (!el.isConnected || !el.hasAttribute(name)) return;
      const key = clean(source);
      const next = language === 'en' ? key : (words[key] || key);
      lastAttributeValues.set(item,next);
      if (el.getAttribute(name) !== next) el.setAttribute(name,next);
    });
    const title = document.documentElement.dataset.englishTitle || document.title;
    document.documentElement.dataset.englishTitle = title;
    document.title = language === 'en' ? title : (words[title] || title);
    document.documentElement.lang = language;
    updatePickers();
  }

  function ensureDictionary(next) {
    if (next === 'en' || (window.VidfluencerTranslations || {})[next]) return Promise.resolve(true);
    if (dictionaryLoads.has(next)) return dictionaryLoads.get(next);
    const promise = new Promise(resolve => {
      const script = document.createElement('script');
      const dictionaryUrl = new URL('translations-' + next + '.js',scriptUrl);
      dictionaryUrl.searchParams.set('v',dictionaryVersion);
      script.src = dictionaryUrl.href;
      script.async = true;
      script.onload = () => { script.remove(); resolve(Boolean((window.VidfluencerTranslations || {})[next])); };
      script.onerror = () => { script.remove(); dictionaryLoads.delete(next); resolve(false); };
      document.head.append(script);
    });
    dictionaryLoads.set(next,promise);
    return promise;
  }

  let languageRequest = 0;
  async function setLanguage(next,returnFocus=false) {
    if (!choices[next]) return false;
    const request = ++languageRequest;
    const loaded = await ensureDictionary(next);
    if (request !== languageRequest) return false;
    if (!loaded) {
      pickers.forEach(picker => { picker.select.value = language; picker.closeMenu(false); });
      console.error('Vidfluencer language file could not be loaded:',next);
      return false;
    }
    language = next;
    refreshReverseWords();
    try { localStorage.setItem('vidfluencer-language',language); } catch (_) {}
    translate();
    pickers.forEach(picker => picker.closeMenu(returnFocus));
    document.dispatchEvent(new CustomEvent('vidfluencer:languagechange',{detail:{language}}));
    return true;
  }

  addStyles();
  collect();
  [...document.querySelectorAll('[data-language-picker]')].forEach(enhancePicker);
  observeDynamicContent();
  window.VidfluencerLanguage = {
    t,
    get language() { return language; },
    setLanguage
  };
  if (language === 'en') translate();
  else ensureDictionary(language).then(loaded => {
    if (!loaded) { language = 'en'; try { localStorage.setItem('vidfluencer-language','en'); } catch (_) {} }
    refreshReverseWords();
    translate();
    document.dispatchEvent(new CustomEvent('vidfluencer:languagechange',{detail:{language}}));
  });
})();
