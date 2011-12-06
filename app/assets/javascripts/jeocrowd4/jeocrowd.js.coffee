# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# to do:
# add parallelization to refinement like in exploratory but with batches of boxes
# zoom map to include all tile (some tiles with high degree)
# check how we can draw hybrid grids (with tiles from bigger levels!!)
# -- > check if possible again to not use negative degrees for the tiles

MAX_LEVEL = 6

window.Jeocrowd = 
  BASE_GRID_STEP: 0.0005
  LEVEL_MULTIPLIER: 5
  COORDINATE_SEPARATOR: '^'
  MAX_XP_PAGES: 16
  MAX_NEIGHBORS: 7
  FULL_SEARCH_TIMES: 1  # DO NOT SET THIS TO ZERO
  
  config: {}
    
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
  keepFullCells: (level, searchingOrComputing) ->
    if searchingOrComputing == 'computing'
      @maxLevel - level < Jeocrowd.FULL_SEARCH_TIMES
    else if searchingOrComputing == 'searching'
      @maxLevel - level < Jeocrowd.FULL_SEARCH_TIMES + 1
  
  buildMap: (div) ->
    initialOptions = { zoom: 10, mapTypeId: google.maps.MapTypeId.ROADMAP }
    initialLocation = new google.maps.LatLng 37.97918, 23.716647
    if placeholder = document.getElementById div 
      @map = new google.maps.Map placeholder, initialOptions 
      @map.setCenter initialLocation 
      return @map
      
  loadConfiguration: ->
    c = $('#jeocrowd_config')
    if c
      @config.timestamp = c.data('timestamp')
      @config.search = JSON.parse c.html()
    if @config.search
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
        @reloadTiles(level) for level in [(@maxLevel - 1)..@refinementLevel]
        if @config.search.rfTiles[@refinementLevel] == null
          @gotoBelowLevel()
        else
          @visibleLevel(@refinementLevel)
        $('#refinement_boxes_value').text((@grids(level).refinementPercent() * 100).toFixed(2) + '%') if @grids(level)
        $('#level_label label').text('max: ' + @maxLevel)
    @config
    
  loadConfigIntoTree: ->
    g = new Grid(0)
    g.addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
    xp = g.tiles.map('getIdAndDegree')
    rf = []
    for i in (@levels ? [])
      if parseInt(i) >= 0
        g = new Grid(0)
        g.addTile(id, degree) for own id, degree of @config.search.rfTiles[i]
        rf[i] = {'data': i + '', 'children': g.tiles.map('getIdAndDegree')}
    data = [
      {'data': 'xpTiles', 'children': xp},
      {'data': 'levels', 'children': (@levels ? []).map( (x) -> x + '')},
      {'data': 'rfTiles', 'children': rf}
    ]
    $('#jeocrowd_tree').jstree({
      'core' : {  },
      'plugins' : [ "json_data", "themes", "ui" ],
      'json_data': {
        'data': data
      }
    })
  
  autoStart: ->
    @config.autoStart || true
    
  resumeSearch: ->
    return if $('#running:checked').length == 0
    if @config.search.phase == 'exploratory'
      next = @provider().exploratorySearch @config.search.keywords, @receiveResults
      @switchToRefinementPhase() if next == null
    else if @config.search.phase == 'refinement'
      next = @provider().refinementSearch @config.search.keywords, @refinementLevel, @receiveResults
      @gotoBelowLevel(@refinementLevel = @refinementLevel - 1) if next == null
    
  receiveResults: (data, pageOrLevel, box) ->
    if @config.search.phase == 'exploratory'
      page = pageOrLevel
      @grids(0).addPoints(data)
      @visibleGrid().draw()
      @map.panTo @visibleGrid().hottestTile.getCenter() if $('#pan_map:checked[value=hottest]').length > 0
      @provider().saveExploratoryResults @grids(0).tiles.toJSON(['degree', 'points']), page, Jeocrowd.syncWithServer
    else if @config.search.phase == 'refinement'
      level = pageOrLevel
      if box.degree > 0
        box.drawNeighborhood() if level == @visibleLevel()
      else
        box.undraw() if level == @visibleLevel()
        @grids(level).removeTile box.id
      @provider().saveRefinementResults box.toSimpleJSON(['degree']), level, Jeocrowd.syncWithServer
      
  switchToRefinementPhase: ->
    if @grids(0).size() == 0
      console.log 'empty search'
      return
    @config.search.phase = 'refinement'
    $('#phase').text('refinement')
    @maxLevel = @calculateMaxLevel()
    @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    if @grids(@maxLevel).isSparse()
      @maxLevel += 1
      @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    $('#level_label label').text('max: ' + @maxLevel)
    @visibleLevel(@maxLevel)
    @map.panTo @visibleGrid().hottestTile.getCenter()
    @levels = []
    @levels[i] = null for i in [0..@maxLevel]
    @levels[@maxLevel] = @maxLevel
    (delete(@_grids[grid.level]) if grid.level != @maxLevel) for grid in @_grids
    @refinementLevel = @maxLevel - 1
    @gotoBelowLevel()
  
  # maximum level is not stored on the server
  # it can be computed by calling 'switchToRefinementPhase' from the exploratory search final results
  # each lower level is stored once hollow-calculated and then individually for each tile
  # this means that eventually when a grid is complete it will be stored before it got refined.
  # this is good because it allows us to view the before-after refinement-clearing of each level.
  gotoBelowLevel: ->
    if @refinementLevel == -1
      @grids(@refinementLevel).clearBeforeRefinement true
      @markAsCompleted()
      return
    @levels[@refinementLevel + 1] = @refinementLevel + 1  # mark above level as complete
    @grids(@refinementLevel + 1).clearBeforeRefinement true, ->
      Jeocrowd.continueGotoBelowLevel()
    
  continueGotoBelowLevel: ->
    @grids(@refinementLevel).growDown(Tile.prototype.always)
    @visibleLevel(@refinementLevel)
    @provider().saveRefinementResults @grids(@refinementLevel).tiles.toSimpleJSON('degree'), 
                                      @refinementLevel, Jeocrowd.syncWithServer
  
  reloadTiles: (level) ->
    @grids(level).addTile(id, degree) for own id, degree of @config.search.rfTiles[level]
  
  syncWithServer: (newData) ->
    if @config.search.phase == 'exploratory'
      @config.timestamp = @provider().timestamp = newData.timestamp
      @provider().updatePages(newData.pages) if newData.pages
      # if provider has 16 pages AND all calculated get all the xpTiles data from the server and resume to switch to refinement
      @grids(0).addTile(id, info.degree, info.points) for own id, info of newData.xpTiles if newData.xpTiles
      # if provider has 16 pages but not all calculated wait a few minutes the reload the page (without ?x=y....)
      @waitAndReload() if !@provider().allPagesCompleted() && @provider().noPagesForMe()
    @resumeSearch() unless @exitNow
  
  waitAndReload: ->
    $('#phase').text('waiting')
    @exitNow = true
    setTimeout(Jeocrowd.reloadWithoutParams, 10000)
    
  reloadWithoutParams: ->
    window.location = window.location.pathname
  
  markAsCompleted: ->
    $('#phase').text('completed')
  
  calculateMaxLevel: ->
    @visibleGrid().undraw()
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @grids(MAX_LEVEL).growUp Tile.prototype.atLeastTwo
    i = MAX_LEVEL
    i-- while @grids(i).tiles.size() == 0
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @maxLevel = i

    





