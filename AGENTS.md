# Vidfluencer Website Editing Rules

- Keep the public website available in English, German, and Spanish.
- Every new visible string must have matching entries in `assets/translations-de.js` and `assets/translations-es.js`. Include headings, links, buttons, filter and sort options, placeholders, accessibility labels, modal content, loading and empty states, errors, and confirmation messages.
- Translation keys must match the English source after whitespace is trimmed. Preserve the source capitalization and punctuation, especially for title-cased labels.
- For text created or updated by JavaScript, use `window.VidfluencerLanguage.t(key)` (or the page's `t(key)`) and refresh open or selected controls when the `vidfluencer:languagechange` event fires.
- Build custom select menus from the translated native options, and refresh their trigger labels when the language changes.
- Keep the language picker, dropdowns, buttons, and account initials consistent with the shared styling in the website pages.
- The standalone `../Campaign Listing Design Preview.html` uses the shared translation files too; add its new labels to the same dictionaries instead of keeping a separate translation map.
- When adding a feature, review it in all three languages, including its buttons and interactive states.