jQuery ->
  giveLifeToPage()
  Jeocrowd.buildMap('map')
  Jeocrowd.loadConfiguration()
  Jeocrowd.resumeSearch() if Jeocrowd.autoStart()

giveLifeToPage = ->
  $('.browsers_select').change ->
    searchId = $(this).attr('id').replace('browsers_', '')
    links = ['continue', 'show', 'restart_xp', 'restart_rf']
    links.every (x) =>
      $("##{x}_#{searchId}").attr 'href', $("##{x}_#{searchId}").attr('href') + "&browsers=" + $(this).val()
  $('#layer').change ->
    Jeocrowd.visibleLayer($(this).val())    
  $('#level').change ->
    Jeocrowd.visibleLevel($(this).val())
  $('#degree--').click ->
    placeholder = $('#degree')
    placeholder.val(parseInt(placeholder.val()) + 1)
    Jeocrowd.setMinVisibleDegree(placeholder.val())
    false
  $('#degree-').click ->
    placeholder = $('#degree')
    newValue = parseInt(placeholder.val()) - 1
    placeholder.val(if newValue < 0 then 0 else newValue)
    Jeocrowd.setMinVisibleDegree(placeholder.val())
    false
  $('#neighbor--').click ->
    placeholder = $('#neighbor')
    newValue = parseInt(placeholder.val()) + 1
    placeholder.val(if newValue > 8 then 8 else newValue)
    Jeocrowd.setMinVisibleNeighborCount(placeholder.val())
    false
  $('#neighbor-').click ->
    placeholder = $('#neighbor')
    newValue = parseInt(placeholder.val()) - 1
    placeholder.val(if newValue < 0 then 0 else newValue)
    Jeocrowd.setMinVisibleNeighborCount(placeholder.val())
    false
  $('#running').change ->
    if $(this).attr('checked')
      Jeocrowd.resumeSearch()
  $(document).on('click', '.pan_map_to_href', ->
    href = $(this).attr('href')
    [lat, lon] = href.replace('#', '').split(Jeocrowd.COORDINATE_SEPARATOR)
    [lat, lon] = [parseFloat(lat), parseFloat(lon)]
    point = new google.maps.LatLng lat, lon
    Jeocrowd.map.panTo point
    false
  )
  $('#hottest_tiles_label').click ->
    new Highcharts.Chart({
      chart: {
        renderTo: 'highchart_graph'
      },
      title: {
        text: 'Tile degree distribution of level ' + Jeocrowd.visibleLevel()
      },
      xAxis: {
        title: {
          text: 'tiles'
        }
      },
      yAxis: {
        title: {
          text: 'degree of tiles'
        }
      },
      tooltip: {
        formatter: -> @y
      }
      series: [{
        data: Jeocrowd.visibleGrid().tiles.map('getDegree').filter((x) -> x > 0).sort((a, b) -> return b - a)
      }]
    })
  $('#reload_tree_value').click ->
    Jeocrowd.loadConfigIntoTree()
  $('#refined').click ->
    ch = $('#refined:checked').length > 0
    if Jeocrowd.config.search.phase == 'refinement' && Jeocrowd.visibleGrid().isComplete()
      if ch
        Jeocrowd.visibleGrid().clearBeforeRefinement(false)
      else
        Jeocrowd.reloadTiles(Jeocrowd.visibleLevel())
        Jeocrowd.visibleGrid().draw()
  $('#link_to_submit_discarder_tiles_count').click ->
    Jeocrowd.submitDiscardedTiles()
  

