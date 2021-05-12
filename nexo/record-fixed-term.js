$(document).ready(function () {
  var coin = location.href.match(/fixed-terms\/(\w+)/)[1];
  if (!coin) return;
  coin = coin.toUpperCase();
  var wait = setInterval(function () {
    if ($('.AssetBalance').length == 0) return;
    var amount = $($('.AssetBalance')[1]).text().replace(coin + ' ', '');
    if (!amount) return;
    $.getJSON("https://money.home.michaelpc.com:9443/nexo/transaction/add?coin=" + coin + "&amount=" + amount);
    return clearInterval(wait);
  }, 1000);
});
