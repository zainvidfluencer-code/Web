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
  let language = 'en';
  try { language = localStorage.getItem('vidfluencer-language') || 'en'; } catch (_) {}
  if (!choices[language]) language = 'en';
  const textNodes = [], attrs = [], pickers = [], dictionaryLoads = new Map();
  const scriptUrl = document.currentScript && document.currentScript.src
    ? document.currentScript.src : new URL('assets/language-switcher.js', location.href).href;
  const dict = () => (window.VidfluencerTranslations || {})[language] || {};
  const t = value => language === 'en' ? value : (dict()[value] || value);

  function addStyles() {
    if (document.querySelector('[data-vf-language-styles]')) return;
    const style = document.createElement('style');
    style.dataset.vfLanguageStyles = '';
    style.textContent = [
      '.lang-switcher .lang-menu{display:flex;flex-direction:column;width:min(372px,calc(100vw - 24px));max-height:min(70vh,540px);overflow:hidden;padding:14px;border-radius:22px;overscroll-behavior:contain}',
      '.lang-menu-head{display:grid;flex:0 0 auto;gap:10px;padding:3px 3px 12px}',
      '.lang-menu-title{margin:0;color:#11182d;font-size:16px;font-weight:750;line-height:1.25}',
      '.lang-search{width:100%;min-height:42px;box-sizing:border-box;padding:0 13px;border:1px solid #e2e6f0;border-radius:13px;background:#f8f9fc;color:#18213a;font:inherit;font-size:14px;outline:none}',
      '.lang-search:focus{border-color:#5968e8;box-shadow:0 0 0 3px rgb(64 85 214 / .12);background:#fff}',
      '.lang-option-groups{display:block;flex:1 1 auto;min-height:0;overflow-y:auto;overscroll-behavior:contain;padding:1px 3px 2px 1px;scrollbar-width:thin;scrollbar-color:#c5cad5 transparent}',
      '.lang-group{display:block}',
      '.lang-option-grid{display:grid;grid-template-columns:minmax(0,1fr);gap:6px}',
      '.lang-switcher .lang-option{display:grid!important;grid-template-columns:26px minmax(0,1fr) auto 12px!important;gap:10px!important;align-items:center!important;width:100%;min-height:44px;padding:0 11px!important;border:1px solid #e1e4ec!important;border-radius:12px!important;background:#fff;color:#25304a;font:inherit;font-size:13px;font-weight:600;line-height:1.25;text-align:left;cursor:pointer;box-sizing:border-box}',
      '.lang-switcher .lang-option:hover,.lang-switcher .lang-option:focus-visible{background:#f8f9fd;border-color:#c9ceda!important;outline:none}',
      '.lang-switcher .lang-option[aria-selected=true]{background:#f2f4fb;border-color:#c9ceda!important;color:#4055d6}',
      '.lang-option .lang-name{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
      '.lang-code{color:#8690a6;font-size:10px;font-weight:800;letter-spacing:.04em}',
      '.lang-option[aria-selected=true] .lang-code{color:#4055d6}',
      '.lang-check{opacity:0;color:#4055d6;font-size:14px;font-weight:900}',
      '.lang-option[aria-selected=true] .lang-check{opacity:1}',
      '.lang-empty{margin:0;padding:13px 8px;color:#737d91;font-size:13px}',
      '.lang-flag{display:inline-flex!important;align-items:center;justify-content:center;width:23px!important;height:21px!important;border-radius:0!important;box-shadow:none!important;font-size:19px;line-height:1}',
      '.lang-option .lang-flag{width:24px!important;height:19px!important;overflow:hidden;border:1px solid #d8dce5;border-radius:4px!important;background:#fff;font-size:15px;line-height:1;box-sizing:border-box}',
      '.lang-native-select{position:absolute!important;width:1px!important;height:1px!important;padding:0!important;margin:-1px!important;overflow:hidden!important;clip:rect(0,0,0,0)!important;white-space:nowrap!important;border:0!important;opacity:0!important}',
      '.lang-switcher [hidden]{display:none!important}',
      '@media(max-width:520px){.lang-switcher .lang-menu{width:min(352px,calc(100vw - 20px));max-height:min(70vh,520px);padding:12px}.lang-option-grid{gap:6px}.lang-switcher .lang-option{min-height:44px;padding:0 9px!important}}'
    ].join('');
    document.head.append(style);
  }

  function makeFlag(code) {
    const flag = document.createElement('span');
    flag.className = 'lang-flag';
    flag.setAttribute('aria-hidden','true');
    flag.textContent = choices[code]?.flag || choices.en.flag;
    return flag;
  }

  function collect() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (!node.parentElement.closest('script,style,noscript,[data-translation-ignore]')) textNodes.push({node,source:node.nodeValue});
    }
    document.querySelectorAll('[aria-label],[title],[placeholder]').forEach(el =>
      ['aria-label','title','placeholder'].forEach(name => {
        if (el.hasAttribute(name)) attrs.push({el,name,source:el.getAttribute(name)});
      })
    );
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
    const languageChoices = Object.entries(choices).sort(([aCode,a],[bCode,b]) => {
      if (aCode === 'en') return -1;
      if (bCode === 'en') return 1;
      return a.search.localeCompare(b.search);
    });
    languageChoices.forEach(([value,choice]) => {
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
      const query = clean(search.value || '').toLocaleLowerCase();
      options.forEach(option => { option.hidden = Boolean(query) && !option.dataset.search.includes(query); });
      const matches = options.filter(option => !option.hidden);
      optionGrid.replaceChildren();
      matches.forEach(option => optionGrid.append(option));
      languageGroup.hidden = false;
      empty.hidden = Boolean(matches.length);
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
    textNodes.forEach(({node,source}) => {
      const leading = (source.match(/^\s*/) || [''])[0];
      const trailing = (source.match(/\s*$/) || [''])[0];
      const key = clean(source);
      node.nodeValue = leading + (language === 'en' ? key : (words[key] || key)) + trailing;
    });
    attrs.forEach(({el,name,source}) => {
      const key = clean(source);
      el.setAttribute(name,language === 'en' ? key : (words[key] || key));
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
      script.src = new URL('translations-' + next + '.js',scriptUrl).href;
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
    try { localStorage.setItem('vidfluencer-language',language); } catch (_) {}
    translate();
    pickers.forEach(picker => picker.closeMenu(returnFocus));
    document.dispatchEvent(new CustomEvent('vidfluencer:languagechange',{detail:{language}}));
    return true;
  }

  addStyles();
  collect();
  [...document.querySelectorAll('[data-language-picker]')].forEach(enhancePicker);
  window.VidfluencerLanguage = {
    t,
    get language() { return language; },
    setLanguage
  };
  if (language === 'en') translate();
  else ensureDictionary(language).then(loaded => {
    if (!loaded) { language = 'en'; try { localStorage.setItem('vidfluencer-language','en'); } catch (_) {} }
    translate();
    document.dispatchEvent(new CustomEvent('vidfluencer:languagechange',{detail:{language}}));
  });
})();
