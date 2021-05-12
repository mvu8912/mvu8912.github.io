var refresh = location.href.match(/refresh=(\d+)/);
if (refresh && refresh[1]) {
  console.log("Refresh the page after " + refresh[1] + " seconds");
  setTimeout(() => {
    location.reload(true);
  }, refresh[1]*1000);
}
