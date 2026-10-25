(() => {
  const clean = value => value.replace(/\s+/g, ' ').trim();
  const choices = {
    en: {flag:'us', code:'EN', name:'English (US)'},
    de: {flag:'de', code:'DE', name:'Deutsch'},
    es: {flag:'es', code:'ES', name:'Español'}
  };
  let language = 'en';
  try { language = localStorage.getItem('vidfluencer-language') || 'en'; } catch (_) {}
  if (!choices[language]) language = 'en';
  const textNodes = [], attrs = [], pickers = [];
  const dict = () => (window.VidfluencerTranslations || {})[language] || {};
  let flagSequence = 0;
  function makeFlag(country) {
    const ns = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns,'svg');
    svg.setAttribute('viewBox','0 0 24 16');
    svg.setAttribute('class','lang-flag');
    svg.setAttribute('aria-hidden','true');
    const id = 'vf-flag-clip-' + (++flagSequence);
    const defs = document.createElementNS(ns,'defs');
    const clip = document.createElementNS(ns,'clipPath');
    clip.setAttribute('id',id);
    const clipRect = document.createElementNS(ns,'rect');
    clipRect.setAttribute('width','24');clipRect.setAttribute('height','16');clipRect.setAttribute('rx','2');
    clip.append(clipRect);defs.append(clip);svg.append(defs);
    const group = document.createElementNS(ns,'g');
    group.setAttribute('clip-path','url(#' + id + ')');
    const rect = (x,y,w,h,fill) => {
      const el=document.createElementNS(ns,'rect');
      el.setAttribute('x',x);el.setAttribute('y',y);el.setAttribute('width',w);el.setAttribute('height',h);el.setAttribute('fill',fill);
      group.append(el);
    };
    if (country==='de') {
      rect(0,0,24,16,'#ffce00');rect(0,0,24,5.34,'#111111');rect(0,5.33,24,5.34,'#dd0000');
    } else if (country==='es') {
      rect(0,0,24,16,'#aa151b');rect(0,4,24,8,'#f1bf00');
    } else {
      rect(0,0,24,16,'#ffffff');
      for(let row=0;row<13;row+=2) rect(0,row*16/13,24,16/13,'#b22234');
      rect(0,0,10.5,8.7,'#3c3b6e');
      for(let row=0;row<5;row++) for(let col=0;col<5;col++) {
        if((row%2===0&&col===4)||(row%2===1&&col===0)) continue;
        const dot=document.createElementNS(ns,'circle');
        dot.setAttribute('cx',1.1+col*1.85+(row%2?0.9:0));dot.setAttribute('cy',0.9+row*1.65);
        dot.setAttribute('r','0.34');dot.setAttribute('fill','#ffffff');group.append(dot);
      }
    }
    svg.append(group);
    const outline=document.createElementNS(ns,'rect');
    outline.setAttribute('x','.5');outline.setAttribute('y','.5');outline.setAttribute('width','23');outline.setAttribute('height','15');
    outline.setAttribute('rx','1.7');outline.setAttribute('fill','none');outline.setAttribute('stroke','#e2e5ed');
    outline.setAttribute('stroke-width','0.55');svg.append(outline);
    return svg;
  }

  function collect() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) if (!node.parentElement.closest('script,style,noscript,[data-translation-ignore]')) textNodes.push({node, source:node.nodeValue});
    document.querySelectorAll('[aria-label],[title],[placeholder]').forEach(el =>
      ['aria-label','title','placeholder'].forEach(name => {
        if (el.hasAttribute(name)) attrs.push({el,name,source:el.getAttribute(name)});
      })
    );
  }

  function enhancePicker(select) {
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
    trigger.setAttribute('aria-haspopup','listbox');
    trigger.setAttribute('aria-expanded','false');

    const chevron = document.createElement('span');
    chevron.className = 'lang-chevron';
    chevron.setAttribute('aria-hidden','true');

    const menu = document.createElement('div');
    menu.className = 'lang-menu';
    menu.setAttribute('role','listbox');
    menu.hidden = true;

    const options = [];
    Object.entries(choices).forEach(([value, choice]) => {
      const option = document.createElement('button');
      option.type = 'button';
      option.className = 'lang-option';
      option.setAttribute('role','option');
      option.dataset.value = value;
      const flag = makeFlag(value);
      const name = document.createElement('span');
      name.className = 'lang-name';
      name.textContent = choice.name;
      const check = document.createElement('span');
      check.className = 'lang-check';
      check.setAttribute('aria-hidden','true');
      check.textContent = '✓';
      option.append(flag,name,check);
      option.addEventListener('click', () => {
        select.value = value;
        select.dispatchEvent(new Event('change',{bubbles:true}));
        closeMenu(true);
      });
      option.addEventListener('keydown', event => {
        const index = options.indexOf(option);
        if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
          event.preventDefault();
          const step = event.key === 'ArrowDown' ? 1 : -1;
          options[(index + step + options.length) % options.length].focus();
        } else if (event.key === 'Home' || event.key === 'End') {
          event.preventDefault();
          options[event.key === 'Home' ? 0 : options.length - 1].focus();
        } else if (event.key === 'Escape') {
          event.preventDefault();
          closeMenu(true);
        }
      });
      options.push(option);
      menu.append(option);
    });

    function closeMenu(returnFocus) {
      menu.hidden = true;
      trigger.setAttribute('aria-expanded','false');
      if (returnFocus) trigger.focus();
    }
    function openMenu() {
      menu.hidden = false;
      trigger.setAttribute('aria-expanded','true');
      const selected = options.find(option => option.dataset.value === select.value) || options[0];
      if (selected) selected.focus();
    }
    trigger.addEventListener('click', () => menu.hidden ? openMenu() : closeMenu(false));
    trigger.addEventListener('keydown', event => {
      if (event.key === 'ArrowDown' || event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        openMenu();
      }
    });
    document.addEventListener('click', event => {
      if (!wrapper.contains(event.target) && !menu.hidden) closeMenu(false);
    });

    wrapper.append(trigger,menu);
    pickers.push({select,trigger,options});
  }

  function updatePickers() {
    const words = dict();
    pickers.forEach(({select,trigger,options}) => {
      const choice = choices[select.value] || choices.en;
      trigger.replaceChildren();
      const flag = makeFlag(select.value);
      const code = document.createElement('span');
      code.className = 'lang-code';
      code.textContent = choice.code;
      const chevron = document.createElement('span');
      chevron.className = 'lang-chevron';
      chevron.setAttribute('aria-hidden','true');
      trigger.append(flag,code,chevron);
      trigger.setAttribute('aria-label',words['Change language'] || 'Change language');
      options.forEach(option => {
        const selected = option.dataset.value === select.value;
        option.setAttribute('aria-selected',String(selected));
      });
    });
  }

  function translate() {
    const words = dict();
    textNodes.forEach(({node,source}) => {
      const leading = (source.match(/^\s*/) || [''])[0], trailing = (source.match(/\s*$/) || [''])[0], key = clean(source);
      node.nodeValue = leading + (language === 'en' ? key : (words[key] || key)) + trailing;
    });
    attrs.forEach(({el,name,source}) => {
      const key = clean(source);
      el.setAttribute(name, language === 'en' ? key : (words[key] || key));
    });
    const title = document.documentElement.dataset.englishTitle || document.title;
    document.documentElement.dataset.englishTitle = title;
    document.title = language === 'en' ? title : (words[title] || title);
    document.documentElement.lang = language;
    document.querySelectorAll('[data-language-picker]').forEach(select => { select.value = language; });
    updatePickers();
  }

  function setLanguage(next) {
    if (!choices[next]) return;
    language = next;
    try { localStorage.setItem('vidfluencer-language',language); } catch (_) {}
    translate();
    document.dispatchEvent(new CustomEvent('vidfluencer:languagechange',{detail:{language}}));
  }

  collect();
  const selects = [...document.querySelectorAll('[data-language-picker]')];
  selects.forEach(enhancePicker);
  selects.forEach(select => select.addEventListener('change',() => setLanguage(select.value)));
  translate();
  window.VidfluencerLanguage = {
    t:value => language === 'en' ? value : (dict()[value] || value),
    get language() { return language; },
    setLanguage
  };
})();