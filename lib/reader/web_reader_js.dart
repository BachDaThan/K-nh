import 'reader_settings.dart';

String buildWebReaderJs() {
  final bg = '#${readerSettings.backgroundColor.value.toRadixString(16).substring(2)}';
  final fg = '#${readerSettings.textColor.value.toRadixString(16).substring(2)}';
  final fs = readerSettings.fontSize;
  final lh = readerSettings.lineHeight;
  return '''
(function(){
  if (document.getElementById('kinh-reader-root')) {
    document.getElementById('kinh-reader-root').remove();
  }
  var article = document.querySelector('article') || document.querySelector('[role=main]') || document.body;
  var title = document.title || '';
  var paras = Array.from(article.querySelectorAll('p, h1, h2, h3, li'))
    .map(function(el){ return el.innerText.trim(); })
    .filter(function(t){ return t.length > 30; })
    .slice(0, 100);
  if (paras.length < 2) paras = [article.innerText.slice(0, 15000)];
  var root = document.createElement('div');
  root.id = 'kinh-reader-root';
  root.setAttribute('style',
    'position:fixed;inset:0;z-index:2147483647;overflow:auto;' +
    'background:$bg;color:$fg;padding:24px 18px 80px;' +
    'font:${fs}px/${lh} Georgia,serif;');
  var h = document.createElement('h1');
  h.textContent = title;
  h.style.cssText = 'font-size:1.35rem;margin:0 0 12px;';
  root.appendChild(h);
  var bar = document.createElement('button');
  bar.textContent = 'Dong Reader';
  bar.style.cssText = 'margin-bottom:16px;padding:8px 12px;border-radius:8px;border:0;background:#6C8CFF;color:#fff;';
  bar.onclick = function(){ root.remove(); };
  root.appendChild(bar);
  paras.forEach(function(t){
    var p = document.createElement('p');
    p.textContent = t;
    p.style.margin = '0 0 1em';
    root.appendChild(p);
  });
  document.documentElement.appendChild(root);
  window.__kinhReaderText = paras.join('\\n\\n');
})();
''';
}

/// Tìm link "chương sau / next" phổ biến trên webnovel.
const findNextChapterJs = r'''
(function(){
  var texts = ['next', 'tiếp', 'sau', 'chương sau', 'next chapter', '›', '»'];
  var links = Array.from(document.querySelectorAll('a'));
  for (var i = 0; i < links.length; i++) {
    var t = (links[i].innerText || '').trim().toLowerCase();
    for (var j = 0; j < texts.length; j++) {
      if (t === texts[j] || t.indexOf(texts[j]) === 0) {
        return links[i].href || '';
      }
    }
  }
  var rel = document.querySelector('a[rel=next]');
  return rel ? (rel.href || '') : '';
})();
''';
