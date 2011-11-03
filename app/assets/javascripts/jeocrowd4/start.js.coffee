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
  
