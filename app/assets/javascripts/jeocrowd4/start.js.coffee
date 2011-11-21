jQuery ->
  giveLifeToPage()
  Jeocrowd.buildMap('map')
  Jeocrowd.loadConfiguration()
  Jeocrowd.resumeSearch() if Jeocrowd.autoStart()
                    

giveLifeToPage = ->
  $('#layer').change ->
    Jeocrowd.visibleLayer($(this).val())    
  $('#level').change ->
    Jeocrowd.visibleLevel($(this).val())
  $('#running').change ->
    if $(this).attr('checked')
      Jeocrowd.resumeSearch()
  $('.pan_map_to_href').live('click', ->
    href = $(this).attr('href')
    [lat, lon] = href.replace('#', '').split(Jeocrowd.COORDINATE_SEPARATOR)
    [lat, lon] = [parseFloat(lat), parseFloat(lon)]
    point = new google.maps.LatLng lat, lon
    Jeocrowd.map.panTo point
    false
  )
  

