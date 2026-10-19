(function () {
  // Turns the browser's sound on at the first click, tap or key, and says on screen whether it worked (docs/AUDIO_DIAGNOSIS.md).
  var Real = window.AudioContext || window.webkitAudioContext;
  if (!Real) { return; }
  var ctxs = [];
  var Tracked = function (a) { var c = a === undefined ? new Real() : new Real(a); ctxs.push(c); c.addEventListener('statechange', show); show(); return c; };
  Tracked.prototype = Real.prototype;
  window.AudioContext = Tracked;
  if (window.webkitAudioContext) { window.webkitAudioContext = Tracked; }
  var silence = null, badge = null, hideAt = 0, tried = false;
  function el() {
    if (!badge && document.body) {
      badge = document.createElement('div');
      badge.id = 'sound-state';
      badge.setAttribute('role', 'status');
      badge.style.cssText = 'position:fixed;left:12px;bottom:12px;z-index:9;padding:6px 10px;border-radius:6px;background:rgba(20,20,24,.85);color:#e8e8e8;font:13px system-ui,sans-serif;pointer-events:none;max-width:80vw';
      document.body.appendChild(badge);
    }
    return badge;
  }
  function running() { return ctxs.length > 0 && ctxs.every(function (c) { return c.state === 'running'; }); }
  function show() {
    var b = el();
    if (!b) { return; }
    var state = ctxs.length === 0 ? 'waiting' : running() ? 'running' : tried ? 'blocked' : 'off';
    b.dataset.state = state;
    b.textContent = state === 'running' ? 'Sound on' : state === 'blocked'
      ? 'The browser kept the sound off. Check this tab is not muted, your volume, and on iPhone or iPad the silent switch. Then click or tap again.'
      : 'Click or tap anywhere to turn the sound on';
    b.style.display = state === 'waiting' ? 'none' : 'block';
    if (state === 'running') { hideAt = Date.now() + 2500; setTimeout(function () { if (Date.now() >= hideAt && running()) { b.style.display = 'none'; } }, 2600); }
  }
  function unlock() {
    tried = ctxs.length > 0;
    try { if (navigator.audioSession) { navigator.audioSession.type = 'playback'; } } catch (e) {}
    try {
      // A playing media element moves iPhones and iPads to playback audio, which the silent switch does not mute.
      if (!silence) { silence = new Audio('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAIA+AAACABAAZGF0YQAAAAA='); silence.loop = true; }
      var p = silence.play(); if (p && p.catch) { p.catch(function () {}); }
    } catch (e) {}
    ctxs.forEach(function (c) { if (c.state !== 'running' && c.state !== 'closed') { c.resume().then(show, show); } });
    setTimeout(show, 800);
  }
  ['pointerdown', 'touchend', 'keydown', 'click'].forEach(function (t) { window.addEventListener(t, unlock, true); });
  document.addEventListener('visibilitychange', function () { if (!document.hidden && tried) { unlock(); } });
  document.addEventListener('DOMContentLoaded', show);
}());
