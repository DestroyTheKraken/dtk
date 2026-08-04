// Shared contact modal (Phase 1)
(function () {
  document.getElementById("y") && (document.getElementById("y").textContent = new Date().getFullYear());
  var backdrop = document.getElementById("contact-modal");
  var form = document.getElementById("contact-form");
  if (!backdrop || !form) return;
  var statusEl = document.getElementById("form-status");
  var submitBtn = document.getElementById("contact-submit");
  var mathA = 0, mathB = 0, mathAns = 0;
  var openedAt = 0;
  var MIN_MS = 2500;

  function newMath() {
    mathA = 2 + Math.floor(Math.random() * 7);
    mathB = 1 + Math.floor(Math.random() * 8);
    mathAns = mathA + mathB;
    var q = document.getElementById("math-q");
    if (q) q.textContent = mathA + " + " + mathB;
    var input = document.getElementById("human_check");
    if (input) input.value = "";
  }

  function openModal(e) {
    if (e) e.preventDefault();
    newMath();
    openedAt = Date.now();
    if (statusEl) { statusEl.textContent = ""; statusEl.className = "form-status"; }
    backdrop.hidden = false;
    void backdrop.offsetWidth;
    backdrop.classList.add("open");
    document.body.style.overflow = "hidden";
    setTimeout(function () {
      var n = document.getElementById("name");
      if (n) n.focus();
    }, 50);
  }

  function closeModal() {
    backdrop.classList.remove("open");
    document.body.style.overflow = "";
    setTimeout(function () {
      if (!backdrop.classList.contains("open")) backdrop.hidden = true;
    }, 200);
  }

  document.querySelectorAll("[data-open-contact]").forEach(function (el) {
    el.addEventListener("click", openModal);
  });
  document.querySelectorAll("[data-close-contact]").forEach(function (el) {
    el.addEventListener("click", closeModal);
  });
  backdrop.addEventListener("click", function (e) {
    if (e.target === backdrop) closeModal();
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && backdrop.classList.contains("open")) closeModal();
  });

  form.addEventListener("submit", async function (e) {
    e.preventDefault();
    if (statusEl) { statusEl.textContent = ""; statusEl.className = "form-status"; }
    var hp = form.querySelector('[name="_gotcha"]');
    if (hp && hp.value) {
      if (statusEl) { statusEl.textContent = "Thanks."; statusEl.className = "form-status ok"; }
      return;
    }
    if (Date.now() - openedAt < MIN_MS) {
      if (statusEl) { statusEl.textContent = "Please wait a moment and try again."; statusEl.className = "form-status err"; }
      return;
    }
    var given = String(form.human_check.value || "").trim();
    if (String(mathAns) !== given) {
      if (statusEl) { statusEl.textContent = "Spam check wrong — try the sum again."; statusEl.className = "form-status err"; }
      newMath();
      return;
    }
    var phone = String(form.phone.value || "").replace(/\D/g, "");
    if (phone.length < 7) {
      if (statusEl) { statusEl.textContent = "Please enter a real callback number."; statusEl.className = "form-status err"; }
      return;
    }
    if (submitBtn) { submitBtn.disabled = true; submitBtn.textContent = "Sending…"; }
    var data = new FormData(form);
    data.set("source", "destroythekraken.com");
    data.set("intent", "callback_please");
    try {
      var res = await fetch(form.action, {
        method: "POST",
        body: data,
        headers: { Accept: "application/json" },
      });
      if (res.ok) {
        if (statusEl) { statusEl.textContent = "Sent. I’ll call you back."; statusEl.className = "form-status ok"; }
        form.reset();
        newMath();
        setTimeout(closeModal, 1600);
      } else {
        var body = {};
        try { body = await res.json(); } catch (_) {}
        if (statusEl) {
          statusEl.textContent = (body && body.error) || "Could not send — try again or call 509.557.7298.";
          statusEl.className = "form-status err";
        }
      }
    } catch (_) {
      if (statusEl) {
        statusEl.textContent = "Network error — call or text 509.557.7298.";
        statusEl.className = "form-status err";
      }
    } finally {
      if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = "Send message"; }
    }
  });
})();
