// Общее для публичной страницы и админки: силуэты, запросы к Supabase, подготовка фото.
(function () {
  var SIL = {
    b: ['Птица', '<ellipse cx="46" cy="58" rx="24" ry="15" transform="rotate(-18 46 58)" fill="currentColor"/><circle cx="66" cy="40" r="11" fill="currentColor"/><path d="M75 37L90 41L75 45Z" fill="currentColor"/><path d="M28 64L8 78L14 84L36 70Z" fill="currentColor"/><rect x="44" y="70" width="3" height="16" fill="currentColor"/><rect x="52" y="68" width="3" height="18" fill="currentColor"/><circle cx="69" cy="38" r="2.2" style="fill:var(--cut)"/>'],
    o: ['Сова', '<path d="M26 44L30 14L42 30Q50 27 58 30L70 14L74 44Q80 82 50 90Q20 82 26 44Z" fill="currentColor"/><circle cx="40" cy="45" r="8.5" style="fill:var(--cut)"/><circle cx="60" cy="45" r="8.5" style="fill:var(--cut)"/><circle cx="40" cy="45" r="3.8" fill="currentColor"/><circle cx="60" cy="45" r="3.8" fill="currentColor"/><path d="M46.5 54L53.5 54L50 61Z" style="fill:var(--cut)"/>'],
    c: ['Кошачьи', '<ellipse cx="48" cy="68" rx="20" ry="22" fill="currentColor"/><circle cx="50" cy="38" r="14" fill="currentColor"/><path d="M37 32L38 15L48 26ZM63 32L62 15L52 26Z" fill="currentColor"/><path d="M66 86C86 88 92 66 80 58" fill="none" stroke="currentColor" stroke-width="6" stroke-linecap="round"/><ellipse cx="45" cy="38" rx="2" ry="3" style="fill:var(--cut)"/><ellipse cx="55" cy="38" rx="2" ry="3" style="fill:var(--cut)"/>'],
    d: ['Псовые', '<path d="M50 88L30 56L24 14L42 33L58 33L76 14L70 56Z" fill="currentColor"/><circle cx="41" cy="51" r="3" style="fill:var(--cut)"/><circle cx="59" cy="51" r="3" style="fill:var(--cut)"/><path d="M34 26L38 31M66 26L62 31" stroke="var(--cut)" stroke-width="2.5" stroke-linecap="round"/>'],
    br: ['Медведь', '<circle cx="27" cy="30" r="11" fill="currentColor"/><circle cx="73" cy="30" r="11" fill="currentColor"/><circle cx="50" cy="55" r="28" fill="currentColor"/><ellipse cx="50" cy="67" rx="12" ry="9" style="fill:var(--cut)"/><ellipse cx="50" cy="63" rx="5" ry="3.5" fill="currentColor"/><circle cx="40" cy="48" r="3" style="fill:var(--cut)"/><circle cx="60" cy="48" r="3" style="fill:var(--cut)"/>'],
    m: ['Зверёк', '<ellipse cx="50" cy="64" rx="14" ry="24" fill="currentColor"/><ellipse cx="50" cy="30" rx="11" ry="12" fill="currentColor"/><circle cx="40" cy="21" r="4.5" fill="currentColor"/><circle cx="60" cy="21" r="4.5" fill="currentColor"/><path d="M60 84Q78 92 82 72" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round"/><ellipse cx="43" cy="88" rx="6" ry="3" fill="currentColor"/><ellipse cx="57" cy="88" rx="6" ry="3" fill="currentColor"/><circle cx="46" cy="29" r="2" style="fill:var(--cut)"/><circle cx="54" cy="29" r="2" style="fill:var(--cut)"/>'],
    s: ['Морские', '<path d="M8 62C24 40 58 32 80 44L94 42L86 50C70 66 42 70 24 64L12 76L14 64Z" fill="currentColor"/><path d="M46 39L56 22L62 41Z" fill="currentColor"/><circle cx="76" cy="47" r="2" style="fill:var(--cut)"/>'],
    h: ['Копытные', '<path d="M42 37L30 13L48 30ZM58 37L70 13L52 30Z" fill="currentColor"/><path d="M50 90C44 80 38 66 38 54L26 44L38 40L44 34L56 34L62 40L74 44L62 54C62 66 56 80 50 90Z" fill="currentColor"/><circle cx="44" cy="50" r="2.5" style="fill:var(--cut)"/><circle cx="56" cy="50" r="2.5" style="fill:var(--cut)"/>'],
    p: ['Приматы', '<circle cx="24" cy="50" r="9" fill="currentColor"/><circle cx="76" cy="50" r="9" fill="currentColor"/><circle cx="50" cy="48" r="25" fill="currentColor"/><ellipse cx="50" cy="56" rx="16" ry="14" style="fill:var(--cut)"/><circle cx="44" cy="52" r="3.2" fill="currentColor"/><circle cx="56" cy="52" r="3.2" fill="currentColor"/><ellipse cx="50" cy="62" rx="3" ry="2" fill="currentColor"/>'],
    f: ['Сказочные', '<path d="M48 10C51 40 60 49 90 52C60 55 51 64 48 94C45 64 36 55 6 52C36 49 45 40 48 10Z" fill="currentColor"/><path d="M80 10C81 18 84 21 92 22C84 23 81 26 80 34C79 26 76 23 68 22C76 21 79 18 80 10Z" fill="currentColor"/>'],
    l: ['Растение', '<path d="M50 94L50 80C20 70 18 34 50 8C82 34 80 70 50 80Z" fill="currentColor"/><path d="M50 76L50 22M50 46L38 36M50 58L62 48M50 66L38 58" stroke="var(--cut)" stroke-width="2.5" stroke-linecap="round"/>'],
    i: ['Насекомое', '<ellipse cx="34" cy="38" rx="18" ry="10" transform="rotate(32 34 38)" fill="currentColor" opacity=".5"/><ellipse cx="66" cy="38" rx="18" ry="10" transform="rotate(-32 66 38)" fill="currentColor" opacity=".5"/><ellipse cx="50" cy="62" rx="11" ry="21" fill="currentColor"/><circle cx="50" cy="36" r="9" fill="currentColor"/><path d="M40 60L26 66M40 70L28 80M60 60L74 66M60 70L72 80" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>'],
    w: ['Лапка', '<ellipse cx="50" cy="65" rx="19" ry="16" fill="currentColor"/><ellipse cx="25" cy="45" rx="7.5" ry="9.5" fill="currentColor"/><ellipse cx="40" cy="30" rx="7.5" ry="9.5" fill="currentColor"/><ellipse cx="60" cy="30" rx="7.5" ry="9.5" fill="currentColor"/><ellipse cx="75" cy="45" rx="7.5" ry="9.5" fill="currentColor"/>'],
    q: ['?', '<path d="M36 38C36 26 44 20 52 20C62 20 68 27 68 35C68 46 54 48 54 60" fill="none" stroke="currentColor" stroke-width="9" stroke-linecap="round"/><circle cx="54" cy="78" r="6" fill="currentColor"/>']
  };
  var TINT = {b: 'c-n', o: 'c-s', c: 'c-o', d: 'c-o', br: 'c-s', m: 'c-g', s: 'c-n', h: 'c-s', p: 'c-g', f: 'c-o', l: 'c-g', i: 'c-n', w: 'c-g', q: 'c-o'};

  // символы силуэтов один раз в документ
  var defs = Object.keys(SIL).map(function (k) { return '<symbol id="s-' + k + '" viewBox="0 0 100 100">' + SIL[k][1] + '</symbol>'; }).join('');
  function addDefs() {
    var d = document.createElement('div');
    d.innerHTML = '<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>' + defs + '</defs></svg>';
    document.body.insertBefore(d.firstChild, document.body.firstChild);
  }
  if (document.body) addDefs(); else document.addEventListener('DOMContentLoaded', addDefs);

  var C = window.LI_CONFIG || {};
  var configured = C.url && C.key && C.url.indexOf('ВАШ-ПРОЕКТ') < 0 && C.key.indexOf('ВСТАВЬТЕ') < 0;
  var base = (C.url || '').replace(/\/+$/, '');

  // Старый anon key — это JWT, его нужно передавать и в Authorization. Новый publishable — только в apikey.
  function headers(extra) {
    var h = {apikey: C.key};
    if (/^eyJ/.test(C.key || '')) h.Authorization = 'Bearer ' + C.key;
    for (var k in extra) h[k] = extra[k];
    return h;
  }
  function fail(r) {
    return r.text().then(function (t) { var e = new Error('HTTP ' + r.status + ': ' + t.slice(0, 300)); e.status = r.status; throw e; });
  }

  // Уменьшает фото и перекодирует в JPEG: меньше трафика и стираются метаданные (в т.ч. геометка).
  function prepPhoto(file, maxSide) {
    maxSide = maxSide || 1200;
    return new Promise(function (resolve, reject) {
      var img = new Image(), url = URL.createObjectURL(file);
      img.onload = function () {
        var k = Math.min(1, maxSide / Math.max(img.naturalWidth, img.naturalHeight));
        var w = Math.round(img.naturalWidth * k), h = Math.round(img.naturalHeight * k);
        var cv = document.createElement('canvas'); cv.width = w; cv.height = h;
        var cx = cv.getContext('2d'); cx.fillStyle = '#fff'; cx.fillRect(0, 0, w, h); cx.drawImage(img, 0, 0, w, h);
        URL.revokeObjectURL(url);
        cv.toBlob(function (b) { b ? resolve(b) : reject(new Error('Не удалось обработать фото')); }, 'image/jpeg', 0.86);
      };
      img.onerror = function () { URL.revokeObjectURL(url); reject(new Error('Этот файл не открывается как картинка')); };
      img.src = url;
    });
  }
  function uuid() {
    if (crypto.randomUUID) return crypto.randomUUID();
    var b = crypto.getRandomValues(new Uint8Array(16)); b[6] = b[6] & 15 | 64; b[8] = b[8] & 63 | 128;
    var h = [].map.call(b, function (x) { return (x + 256).toString(16).slice(1); }).join('');
    return h.slice(0, 8) + '-' + h.slice(8, 12) + '-' + h.slice(12, 16) + '-' + h.slice(16, 20) + '-' + h.slice(20);
  }

  window.LI = {
    SIL: SIL, TINT: TINT, configured: configured, base: base, headers: headers, prepPhoto: prepPhoto, uuid: uuid,
    esc: function (t) { return String(t == null ? '' : t).replace(/[&<>"']/g, function (c) { return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]; }); },
    norm: function (t) { return String(t == null ? '' : t).toLowerCase().replace(/ё/g, 'е').trim(); },
    photoUrl: function (path) { return path ? base + '/storage/v1/object/public/photos/' + encodeURI(path) : ''; },
    fetchNames: function () {
      return fetch(base + '/rest/v1/names?select=id,fio,otryad,forest_name,year,silhouette,photo_path,updated_at&order=forest_name.asc', {headers: headers()})
        .then(function (r) { return r.ok ? r.json() : fail(r); });
    },
    uploadRequestPhoto: function (blob) {
      var path = uuid() + '.jpg';
      return fetch(base + '/storage/v1/object/uploads/' + path, {method: 'POST', headers: headers({'Content-Type': 'image/jpeg', 'x-upsert': 'false'}), body: blob})
        .then(function (r) { return r.ok ? path : fail(r); });
    },
    sendRequest: function (row) {
      return fetch(base + '/rest/v1/requests', {method: 'POST', headers: headers({'Content-Type': 'application/json', Prefer: 'return=minimal'}), body: JSON.stringify(row)})
        .then(function (r) { return r.ok ? true : fail(r); });
    }
  };
})();
