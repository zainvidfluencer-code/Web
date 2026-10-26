/*
  Browser-safe project settings. Keep Supabase secret/service-role keys out of this file.
  Live authentication is enabled for the configured Supabase project. Keep secret/service-role keys out of this browser file.
*/
window.VIDFLUENCER_CONFIG = {
  supabaseUrl: "https://etzzzhbfeokhtzdwjyhn.supabase.co",
  publishableKey: "sb_publishable_KT83dHO41ImPI5sDMTVT8w_H9tt5Xep",
  supabaseJsUrl: "https://esm.sh/@supabase/supabase-js@2.118.0",
  liveAuthReady: true,
  pendingCanBrowse: false,
  reviewTimingText: "We aim to review complete applications within 3–5 business days.",
  campaignsPage: "campaigns/",
  adminSessionMinutes: 30,
  adminPaths: { login: "admin-login/", dashboard: "admin/" },
  agreementDocs: {
    en: {
      title: "Vidfluencer Creator Partnership Agreement",
      version: "2026-10-23-en-f84bb3c66caba2f9",
      fileName: "creator-agreement-en.pdf",
      documentUrl: "assets/contracts/creator-agreement-en.pdf",
      sha256: "F84BB3C66CABA2F96043E3DB4067D5A40A7085BBF6288FB58A5BAABE14823F36"
    },
    de: {
      title: "Vidfluencer Creator-Partnerschaftsvereinbarung",
      version: "2026-10-23-de-f49446c855bce5bd",
      fileName: "creator-agreement-de.pdf",
      documentUrl: "assets/contracts/creator-agreement-de.pdf",
      sha256: "F49446C855BCE5BD3B7F15475A7FD100DCF5224C58A794AD6EEA5CFB5F412E7C"
    },
    es: {
      title: "Acuerdo de Colaboración con Creadores de Vidfluencer",
      version: "2026-10-24-es-69126e5d9d62d458",
      fileName: "creator-agreement-es.pdf",
      documentUrl: "assets/contracts/creator-agreement-es.pdf",
      sha256: "69126E5D9D62D458DCFA9F37B0F009D6EEED11C3E809F0AAB5F3DE1868068664"
    }
  }
};