# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

MAX_LEVEL = 6

window.Jeocrowd = 
  config: {search: {}, ui: {}}
  
  _grids: null
  grids: (level) ->
    @_grids ||= [0..MAX_LEVEL].map (i) ->
      new window.Grid(i)
    if level == undefined
      @_grids
    else
      @_grids[level]
  
  _provider : null
  provider: ->
    @_provider ||= new window.Provider 'Flickr', window.location.href, @config.search
  
  _visibleLayer: 'degree'
  visibleLayer: (layer) ->
    if layer
      $('#layer').val(layer)
      @_visibleLayer = layer
      @visibleGrid().draw()
    @_visibleLayer

  _visibleLevel: 0
  visibleLevel: (level) ->
    if level
      level = parseInt(level) if typeof level == 'string'
      $('#level').val(level)
      @grids(@_visibleLevel).undraw()
      @_visibleLevel = level
      @grids(@_visibleLevel).draw()
    @_visibleLevel
      
  visibleGrid: ->
    @grids(@visibleLevel())

  buildMap: (div) ->
    initialOptions = { zoom: 12, mapTypeId: google.maps.MapTypeId.ROADMAP }
    initialLocation = new google.maps.LatLng 37.97918, 23.716647
    if placeholder = document.getElementById div 
      @map = new google.maps.Map placeholder, initialOptions 
      @map.setCenter initialLocation 
      return @map
      
  loadConfiguration: ->
    configurationElement = document.getElementById 'jeocrowd_config'
    @config.search = JSON.parse configurationElement.innerHTML if configurationElement
    if @config.search.phase == 'exploratory'
      @grids(0).addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
      @visibleLayer('neighbors')
      @visibleLevel(0)
      $('#exploratory_pages_value').text(JSON.stringify @provider().pages)
    else if @config.search.phase == 'refinement'
      @levels = @config.search.levels
      @refinementLevel = Util.lastMissingFromRange(@levels)
      if @config.search.rfTiles[@refinementLevel] == null
        @grids(@refinementLevel + 1).addTile(id, info) for own id, degree of @config.search.rfTiles[@refinementLevel + 1]
        @grids(@refinementLevel).growDown(Tile.prototype.always)
      else
        @grids(@refinementLevel).addTile(id, info) for own id, degree of @config.search.rfTiles[@refinementLevel]
      @visibleLayer('neighbors')
      @visibleLevel(@refinementLevel)
  
  autoStart: ->
    @config.autoStart || true
    
  resumeSearch: ->
    if @config.search.phase == 'exploratory'
      next = @provider().exploratorySearch @config.search.keywords, @receiveResults
      @switchToRefinementPhase() if next == null
    else if @config.search.phase == 'refinement'
      next = @provider().refinementSearch @config.search.keywords, @refinementLevel, @receiveResults
      @gotoPreviousLevel() if next == null
    
  receiveResults: (data, page) ->
    console.log 'hi!'
    if @config.search.phase == 'exploratory'
      @grids(0).addPoints(data)
      @visibleGrid().draw()
      @provider().saveExploratoryResults @grids(0).tiles.toJSON({withoutID: true}), page, Jeocrowd.syncWithServer
    else if @config.search.phase == 'refinement'
      console.log "here?"
      true
      
  switchToRefinementPhase: ->
    @config.search.phase = 'refinement'
    $('#search_phase_value').text('refinement')
    @maxLevel = @calculateMaxLevel()
    @grids(@maxLevel).growUp Tile.prototype.atLeastOne
    @grids(@maxLevel).clearBeforeRefinement()
    @visibleLevel(@maxLevel)
    @levels = []
    @levels[i] = null for i in [0..@maxLevel]
    @levels[@maxLevel] = @maxLevel
    @provider().saveRefinementResults @visibleGrid().tiles.toSimpleJSON('degree'), 
                                      @visibleGrid().level, Jeocrowd.syncWithServer
  
  syncWithServer: (newData) ->
    @resumeSearch()
    
  calculateMaxLevel: ->
    @visibleGrid().undraw()
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @grids(MAX_LEVEL).growUp Tile.prototype.atLeastTwo
    i = MAX_LEVEL
    i-- while @grids(i).tiles.size() == 0
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
    @maxLevel = i









