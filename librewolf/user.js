// LibreWolf user.js — tweaks para máquinas con pocos recursos
// Aplicar: copiar o symlinkear al perfil de LibreWolf
//   ~/.librewolf/<profile>/user.js
// Las preferencias acá pisany cualquier valor por defecto de LibreWolf.

// === Procesos ===
// Reduce la cantidad de procesos hijos. Por defecto Firefox usa 8+.
// En 4-8GB de RAM con 2-4 cores es el cambio que más memoria libera.
user_pref("dom.ipc.processCount", 2);

// === Descarga automática de pestañas ===
// Descarga pestañas inactivas de la RAM (no las cierra, solo libera memoria).
user_pref("browser.tabs.unloadOnLowMemory", true);
// Una pestaña no tocada por 10 minutos se descarga automáticamente.
user_pref("browser.tabs.min_inactive_duration_interval_ms", 600000);

// === Cache en RAM (no en disco) ===
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 2048);
user_pref("media.memory_cache_max_size", 65536);

// === Precarga predictiva (desactivada — gasta CPU y RAM al pedo) ===
user_pref("network.predictor.enabled", false);
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("browser.places.speculativeConnect.enabled", false);

// === Aceleración por hardware ===
user_pref("layers.acceleration.force-enabled", true);

// === Scroll ===
// Desactiva scroll animado — se siente más seco pero más rápido en hardware lento.
user_pref("browser.smoothScroll", false);

// === Limpieza al cerrar (reforzar LibreWolf) ===
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
