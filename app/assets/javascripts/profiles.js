$(document).ready(function() {
  $('.reload_on_change').change(function() {
    var key = $(this).attr('name');
    var params = {};
    var search = unescape(location.search.substring(1));
    // console.log(search);
    if (search.length > 0) {
      var kv = search.split('&');
      // console.log(kv)
      for (var p in kv) {
        var data = kv[p].split('=');
        // console.log(data);
        if (data[0].indexOf('[]') == -1) {
          params[data[0]] = data[1];
        } else {
          params[data[0]] == null ? params[data[0]] = [] : false
          params[data[0]].push(data[1]);
        }
      }
    }
    // console.log(key);
    params[key] = $(this).val();
    location.search = '?' + jQuery.param(params);
  });
});