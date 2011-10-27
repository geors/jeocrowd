# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Jeocrowd = 
  buildMap: (div) ->
    initialOptions = { zoom: 12, mapTypeId: google.maps.MapTypeId.ROADMAP }
    initialLocation = new google.maps.LatLng(37.97918, 23.716647)
    if placeholder = document.getElementById(div)
      map = new google.maps.Map(placeholder, initialOptions);
      map.setCenter(initialLocation)
      return map
    else
      return null