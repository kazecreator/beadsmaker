(function () {
  const supported = new Set(["zh", "en"]);
  const params = new URLSearchParams(window.location.search);
  const requested = params.get("lang");
  const stored = window.localStorage.getItem("beadsmaker-language");
  const initial = supported.has(requested) ? requested : supported.has(stored) ? stored : "zh";

  function applyLanguage(lang) {
    const next = supported.has(lang) ? lang : "zh";
    document.documentElement.dataset.lang = next;
    document.documentElement.lang = next === "zh" ? "zh-CN" : "en";
    window.localStorage.setItem("beadsmaker-language", next);

    document.querySelectorAll("[data-set-language]").forEach((button) => {
      const isActive = button.dataset.setLanguage === next;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", String(isActive));
    });
  }

  window.setBeadsMakerLanguage = applyLanguage;
  applyLanguage(initial);

  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll("[data-set-language]").forEach((button) => {
      button.addEventListener("click", () => applyLanguage(button.dataset.setLanguage));
    });
    applyLanguage(document.documentElement.dataset.lang || initial);
  });
})();
