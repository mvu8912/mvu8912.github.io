(run => {
  if (window.self !== window.top)    return;
  if (!location.href.match(/split/)) return;
  if (document.body.innerHTML.match(/Log In/)) return location.href = "https://accounts.binance.com/en/login";
  if (!location.href.match(/my\/dashboard/))   return location.href = "https://binance.com/en/my/dashboard?split=1";
  
  var remove_support = setInterval(() => {
      var button = document.getElementById('pre-chat-container');
      if (!button) return;
      clearInterval(remove_support);
      button.remove();
  }, 1000);

  var retry = setInterval(() => {
      try {
        if (pairs()) {
          clearInterval(retry);
        }

        var html = "<style>";
        html += "table {width: 100%; height: 100%; position: absolute; top: 0; bottom: 0; left: 0; right: 0;}";
        html += "iframe {width: 100%; height: 100%}";
        html += "</style><table>";

        pairs().forEach((pair) => {
          if (pair.match(/tr|td/)) {
              html += pair;
          }
          else if (pair) {
              var encoded_name = escape(pair);
              var encoded_url  = escape('https://www.binance.com/en/trade/'+pair+'?layout=pro&type=spot');
              html += '<iframe src="https://mvu8912.github.io/js/split-screen/binance-spot.html?name='+encoded_name+'&url='+encoded_url+'"></iframe>';
          }
        });

        html += "</table>";
        
        document.body.innerHTML = html;
      }
      catch(e) {}
  }, 1000);
})();
