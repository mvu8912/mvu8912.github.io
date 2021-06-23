(run => {
  if (!location.href.match(/split/)) return;

  if (document.body.innerHTML.match(/Log In/)) location.href = "https://accounts.binance.com/en/login";
  if (window.self !== window.top) return;
  
  var html = "<style>";
  html += "table {width: 100%; height: 100%; position: absolute; top: 0; bottom: 0; left: 0; right: 0;}";
  html += "iframe {width: 100%; height: 100%}";
  html += "</style><table>";

  pairs.forEach((pair) => {
         if (pair.match(/tr|td/)) html += pair;
    else if (pair) html += '<iframe src="https://www.binance.com/en/trade/'+pair+'?layout=pro&type=spot"></iframe>';
  });

  html += "</table>";
  
  document.body.innerHTML = html;
})();
