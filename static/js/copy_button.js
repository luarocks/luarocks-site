
export class CopyButton {
  static feedback_duration = 1500;

  constructor(el) {
    this.el = $(el);
    this.el.on("click", ".copy_button", (e) => {
      e.preventDefault();
      this.copy($(e.currentTarget));
    });
  }

  copy(button) {
    const value = button.attr("data-copy");
    if (!value) return;

    const done = (ok) => {
      const cls = ok ? "copied" : "copy_failed";
      button.addClass(cls);
      const orig = button.attr("aria-label");
      button.attr("aria-label", ok ? "Copied" : "Copy failed");
      setTimeout(() => {
        button.removeClass(cls);
        if (orig) button.attr("aria-label", orig);
      }, CopyButton.feedback_duration);
    };

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(value).then(() => done(true), () => done(false));
    } else {
      done(this.fallback_copy(value));
    }
  }

  fallback_copy(value) {
    const ta = document.createElement("textarea");
    ta.value = value;
    ta.setAttribute("readonly", "");
    ta.style.position = "absolute";
    ta.style.left = "-9999px";
    document.body.appendChild(ta);
    ta.select();
    let ok = false;
    try { ok = document.execCommand("copy"); } catch (e) { ok = false; }
    document.body.removeChild(ta);
    return ok;
  }
}
