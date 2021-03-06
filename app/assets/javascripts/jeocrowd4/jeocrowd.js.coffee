# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# to do:
# - zoom map to include all tile (some tiles with high degree)
# - fix: Uncaught TypeError: Cannot set property 'timeInServer' of undefined in first benchmark call
# check difference between initial rf when using multible browsers
# remove browser spawner on reloading pages when waiting
# add waiting time for reloadin in profiles == XP timeout () -- server use only

MAX_LEVEL = 6

window.Jeocrowd = 
  BASE_GRID_STEP: 0.0005
  ACTUAL_SIZE_OF_BASE_GRID_IN_METERS: 50
  LEVEL_MULTIPLIER: 5
  COORDINATE_SEPARATOR: '^'
  MAX_XP_PAGES: 16
  FULL_SEARCH_TIMES: 1 # DO NOT SET THIS TO ZERO
  MAX_NEIGHBORS_FOR_CORE: 7
  THRESHOLD_FOR_REMOVAL: 0.02
  HOT_TILES_COUNT_AVERAGE: 5
  DETECT_SPARSE_GRIDS: true
  TILES_APART_FOR_SPARSE_GRIDS: 10
  VISUALIZE_CLEARING_TIME: 2000 # in ms
  BENCHMARK_PUBLISH_INTERVAL: 30000 # in ms
  FINISH_LEVEL: 0
  WAITING_ON_RELOAD: 10000 #in ms
  
  config: {}
  
  featureOpts: {
    "pale_down" : [{"featureType":"water","stylers":[{"visibility":"on"},{"color":"#acbcc9"}]},{"featureType":"landscape","stylers":[{"color":"#f2e5d4"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#c5c6c6"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#e4d7c6"}]},{"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#fbfaf7"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#c5dac6"}]},{"featureType":"administrative","stylers":[{"visibility":"on"},{"lightness":33}]},{"featureType":"road"},{"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"on"},{"lightness":20}]},{},{"featureType":"road","stylers":[{"lightness":20}]}];
    "subtle_grayscale" : [{"featureType":"landscape","stylers":[{"saturation":-100},{"lightness":65},{"visibility":"on"}]},{"featureType":"poi","stylers":[{"saturation":-100},{"lightness":51},{"visibility":"simplified"}]},{"featureType":"road.highway","stylers":[{"saturation":-100},{"visibility":"simplified"}]},{"featureType":"road.arterial","stylers":[{"saturation":-100},{"lightness":30},{"visibility":"on"}]},{"featureType":"road.local","stylers":[{"saturation":-100},{"lightness":40},{"visibility":"on"}]},{"featureType":"transit","stylers":[{"saturation":-100},{"visibility":"simplified"}]},{"featureType":"administrative.province","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"labels","stylers":[{"visibility":"on"},{"lightness":-25},{"saturation":-100}]},{"featureType":"water","elementType":"geometry","stylers":[{"hue":"#ffff00"},{"lightness":-25},{"saturation":-97}]}]
  }
    
  _grids: null
  grids: (level) ->
    @_grids ?= [0..MAX_LEVEL].map (i) ->
      new Grid(i)
    if level == undefined
      @_grids
    else
      @_grids[level] ? (@_grids[level] = new Grid(level))
  
  _provider : null
  provider: ->
    @_provider ?= new window.Provider 'Flickr', window.location.href, @config.search, @config.timestamp
  
  _visibleLayer: 'degree'
  visibleLayer: (layer) ->
    if layer
      $('#layer').val(layer)
      @_visibleLayer = layer
      @visibleGrid().draw()
    @_visibleLayer

  _visibleLevel: 0
  visibleLevel: (level) ->
    if level != undefined
      level = parseInt(level) if typeof level == 'string'
      $('#level').val(level)
      @grids(@_visibleLevel).undraw()
      @_visibleLevel = level
      @grids(@_visibleLevel).draw()
      $('#visible_points_value').text(@grids(@_visibleLevel).visiblePointsCounter)
      $('#visible_tiles_value').text(@grids(@_visibleLevel).visibleTilesCounter)
      if @grids(@_visibleLevel).hottestTile
        $('#hottest_tiles_value').html(@grids(@_visibleLevel).hottestTile.linkTo())
        $('#hottest_tiles_degree_value').text(@grids(@_visibleLevel).hottestTile.degree)
    @_visibleLevel
      
  visibleGrid: ->
    @grids(@visibleLevel())

  setMinVisibleDegree: (d) ->
    grid.setMinVisibleDegree(d) for grid in @grids()
    @visibleGrid().draw()
  
  setMinVisibleNeighborCount: (n) ->
    grid.setMinVisibleNeighborCount(n) for grid in @grids()
    @visibleGrid().draw()
  
  # calculating when we have to search everything or when to keep full areas based on FULL_SEARCH_TIMES
  searchEverything: (level) ->
    @maxLevel - level < Jeocrowd.FULL_SEARCH_TIMES
  
  buildMap: (div) ->
    initialOptions = { zoom: 10, mapTypeId: "subtle_grayscale", disableDoubleClickZoom: true }
    initialLocation = new google.maps.LatLng 37.97918, 23.716647
    if placeholder = document.getElementById div 
      @map = new google.maps.Map placeholder, initialOptions 
      @changeToSimpleStyle("subtle_grayscale")
      @map.setCenter initialLocation 
      return @map
  
  changeToSimpleStyle: (styleName) ->
    console.log @featureOpts[styleName]
    customMapType = new google.maps.StyledMapType(@featureOpts[styleName], {name: styleName});
    @map.mapTypes.set(styleName, customMapType);
  
  loadConfiguration: ->
    c = $('#jeocrowd_config')
    if c.length
      @config.timestamp = c.data('timestamp')
      @config.search = JSON.parse c.html()
    if @config.search
      if @config.search.profile
        for profileKey, profileValue of @config.search.profile
          Jeocrowd[profileKey.toUpperCase()] = profileValue if Jeocrowd[profileKey.toUpperCase()]?
          
      $('#available_points_value').text(@config.search.statistics.total_available_points)
      $('#exploratory_pages_value').text(JSON.stringify @config.search.pages)
      @visibleLayer('neighbors')
      if @config.search.phase == 'exploratory'
        @grids(0).addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
        @visibleLevel(0)
      else if @config.search.phase == 'refinement'
        @levels = @config.search.levels
        @maxLevel = @levels.length - 1
        @refinementLevel = Util.lastMissingFromRange(@levels)
        if @refinementLevel == null
          @markAsCompleted()
          return
        for level in [(@maxLevel - 1)..@refinementLevel]
          @reloadTiles(level) 
          @grids(level).clearBeforeRefinement(false) if @maxLevel > level > @refinementLevel
        if @config.search.rfTiles[@refinementLevel] == null          
          @gotoBelowLevel()
        else
          @provider().updateAssignedTiles @config.search.startingBlock, @refinementLevel
          @visibleLevel(@refinementLevel)          
        $('#refinement_boxes_value').text((@grids(level).refinementPercent() * 100).toFixed(2) + '%') if @grids(level)
        $('#level_label label').text('max: ' + @maxLevel)
      Benchmark.reportURL = window.location.pathname
      Benchmark.setupPublishing Jeocrowd.BENCHMARK_PUBLISH_INTERVAL
      Benchmark.create 'exploratoryServerProcessing'
      Benchmark.create 'refinementServerProcessing'
    @config
    
  loadConfigIntoTree: ->
    g = new Grid(0)
    g.addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
    xp = g.tiles.map('getIdAndDegree')
    rf = []
    for i in [0..(@maxLevel - 1)]
      rf[i] = {'data': i + '', 'children': @grids(i).tiles.map('getIdAndDegree')}
    @treedata = [
      {'data': 'xpTiles', 'children': xp},
      {'data': 'levels', 'children': (@levels ? []).map( (x) -> x + '')},
      {'data': 'rfTiles', 'children': rf}
    ]
    $('#jeocrowd_tree').jstree({
      'core' : {  },
      'plugins' : [ "json_data", "themes", "ui" ],
      'json_data': {
        'data': @treedata
      }
    })
    
  countDiscardedTiles: ->
    counts = {}
    for level in [(@maxLevel - 1)..Jeocrowd.FINISH_LEVEL]
      counts[level] = []
      @reloadTiles(level)
      counts[level].push @grids(level).size()
      @grids(level).clearBeforeRefinement(false)
      counts[level].push @grids(level).size()
      counts[level].push @grids(level).count('notFull')
    @buildRefinementStartGrid()
    counts[@maxLevel] = []
    counts[@maxLevel].push @grids(@maxLevel).size()
    @grids(@maxLevel).clearBeforeRefinement(false)
    counts[@maxLevel].push @grids(@maxLevel).size()
    counts[@maxLevel].push @grids(@maxLevel).count('notFull')
    counts
    
  submitDiscardedTiles: ->
    @provider().storeSimpleKeyValue({'counts': @countDiscardedTiles(), 'multiplier': Jeocrowd.LEVEL_MULTIPLIER})
  
  autoStart: ->
    @config.autoStart || true
    
  running: ->
    $('#running:checked').length > 0
    
  completed: ->
    @config.search.phase == 'completed'
    
  resumeSearch: ->
    return if !@running()
    if @config.search.phase == 'exploratory'
      Benchmark.start('exploratoryLoading')
      next = @provider().exploratorySearch @config.search, @receiveResults
      if next == null
        Benchmark.finish('exploratoryLoading')
        @switchToRefinementPhase()
    else if @config.search.phase == 'refinement'
      Benchmark.start('refinementLoading')
      next = @provider().refinementSearch @config.search, @refinementLevel, @receiveResults
      if next == null
        Benchmark.finish('refinementLoading')
        @gotoBelowLevel()
    
  receiveResults: (data, pageOrLevel, box) ->
    if @config.search.phase == 'exploratory'
      Benchmark.finish('exploratoryLoading')
      Benchmark.start('exploratoryClientProcessing')
      page = pageOrLevel
      tempgrid = new Grid(0)
      tempgrid.temp = true
      tempgrid.addPoints(data)
      @grids(0).addPoints(data)
      @visibleGrid().draw()
      @map.panTo @visibleGrid().hottestTile.getCenter() if $('#pan_map:checked[value=hottest]').length > 0
      Benchmark.finish('exploratoryClientProcessing')
      Benchmark.start('exploratorySaving')
      @provider().saveExploratoryResults tempgrid.tiles.toJSON(['degree', 'points']), page, Jeocrowd.syncWithServer
    else if @config.search.phase == 'refinement'
      Benchmark.finish('refinementLoading')
      Benchmark.start('refinementClientProcessing')
      level = pageOrLevel
      if box
        if box.degree > 0
          box.drawNeighborhood() if level == @visibleLevel()
        else
          box.undraw() if level == @visibleLevel()
          @grids(level).removeTile box.id
      Benchmark.finish('refinementClientProcessing')
      if @provider().continueRefinementBlock()
        @resumeSearch()
      else
        console.log 'saving...'
        Benchmark.start('refinementSaving')
        @provider().saveRefinementResults @provider().assignedTilesCollection.toSimpleJSON(['degree']), 
                                          level, Jeocrowd.syncWithServer
      
  switchToRefinementPhase: ->
    if @grids(0).size() == 0
      console.log 'empty search'
      return
    @config.search.phase = 'refinement'
    $('#phase').text('refinement')
    Benchmark.start('refinementClientProcessing')
    @maxLevel = @calculateMaxLevel()
    @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    if (@grids(@maxLevel).isSparse() && Jeocrowd.DETECT_SPARSE_GRIDS) || (@maxLevel == Jeocrowd.FINISH_LEVEL)
      console.log 'sparse grid detected...'
      @sparseGrid = true
      @maxLevel += 1
      @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    Benchmark.finish('refinementClientProcessing')
    $('#level_label label').text('max: ' + @maxLevel)
    @visibleLevel(@maxLevel)
    @map.panTo @visibleGrid().hottestTile.getCenter() if @visibleGrid().hottestTile
    for grid in @_grids
      delete(@_grids[grid.level]) if grid.level != @maxLevel
    @levels = []
    @levels[i] = null for i in [0..@maxLevel]
    @refinementLevel = @maxLevel
    @gotoBelowLevel()
    
  buildRefinementStartGrid: ->
    delete(@_grids)
    @grids(0).addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
    @maxLevel = @calculateMaxLevel()
    @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    if @grids(@maxLevel).isSparse() && Jeocrowd.DETECT_SPARSE_GRIDS
      console.log 'sparse grid detected...'
      @maxLevel += 1
      @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    @grids
  
  # maximum level is not stored on the server
  # it can be computed by calling 'switchToRefinementPhase' from the exploratory search final results
  # each lower level is stored once hollow-calculated and then individually for each tile
  # this means that eventually when a grid is complete it will be stored before it got refined.
  # this is good because it allows us to view the before-after refinement-clearing of each level.
  gotoBelowLevel: ->
    Benchmark.start('refinementClientProcessing')
    if @refinementLevel == Jeocrowd.FINISH_LEVEL
      @grids(@refinementLevel).clearBeforeRefinement true
      @markAsCompleted()
      return
    @levels[@refinementLevel] = @refinementLevel  # mark current level as complete before going down
    @grids(@refinementLevel).clearBeforeRefinement(true, -> Jeocrowd.continueGotoBelowLevel())
    
  continueGotoBelowLevel: ->
    @refinementLevel -= 1
    @grids(@refinementLevel).growDown(Tile.prototype.notFull)
    @visibleLevel(@refinementLevel)
    Benchmark.finish('refinementClientProcessing', true, Jeocrowd.VISUALIZE_CLEARING_TIME)
    Benchmark.start('refinementSaving')
    @provider().saveRefinementResults @grids(@refinementLevel).tiles.toSimpleJSON('degree'),
                                      @refinementLevel, Jeocrowd.syncWithServer
  
  reloadTiles: (level) ->
    @grids(level).addTile(id, degree) for own id, degree of @config.search.rfTiles[level]
  
  syncWithServer: (newData) ->
    console.log 'syncing...'
    @config.timestamp = @provider().timestamp = newData.timestamp
    if @config.search.phase == 'exploratory'
      Benchmark.finish('exploratorySaving')
      console.log 'exploring...'
      Benchmark.start('exploratoryClientProcessing')
      @provider().updatePages(newData.pages) if newData.pages
      # if provider has 16 pages AND all calculated get all the xpTiles data from the server
      # and resume to switch to refinement
      @grids(0).addTile(id, info.degree, info.points) for own id, info of newData.xpTiles if newData.xpTiles
      # if provider has 16 pages but not all calculated wait a few minutes the reload the page (without ?x=y....)
      @waitAndReload() if !@provider().allPagesCompleted() && @provider().noPagesForMe()
      Benchmark.finish('exploratoryClientProcessing')
    else if @config.search.phase == 'refinement'
      Benchmark.finish('refinementSaving')
      console.log 'refining...'
      Benchmark.start('refinementClientProcessing')
      @provider().updateAssignedTiles(newData.boxes, newData.level) # boxes can be either an array of ids to search for or null/undefined
      @waitAndReload() if !@provider().allBoxesCompleted(@refinementLevel) && @provider().noBoxForMe(@refinementLevel);
      Benchmark.finish('refinementClientProcessing')
    @resumeSearch() unless @exitNow
  
  waitAndReload: ->
    $('#phase').text('waiting')
    @exitNow = true
    Benchmark.publish()
    setTimeout(Jeocrowd.reloadWithoutParams, Jeocrowd.WAITING_ON_RELOAD)
    
  reloadWithoutParams: ->
    window.location = window.location.pathname
  
  markAsCompleted: ->
    @config.search.phase = 'completed'
    $('#phase').text(@config.search.phase)
    Benchmark.publish()
    @provider().storeSimpleKeyValue({'completed': 'completed'})
  
  calculateMaxLevel: ->
    @visibleGrid().undraw()
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @grids(MAX_LEVEL).growUp Tile.prototype.atLeastTwo
    i = MAX_LEVEL
    i-- while @grids(i).tiles.size() == 0
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @maxLevel = i
    


    





