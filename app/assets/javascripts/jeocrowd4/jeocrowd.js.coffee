# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Jeocrowd = 
  config: {search: {}, ui: {}}
  
  _grids: null
  grids: (level) ->
    @_grids ||= [0..6].map (i) ->
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
      @visibleLevel(0)
      @visibleLayer('neighbors')
      @grids(0).addTile(id, info.degree, info.points) for own id, info of @config.search.xpTiles
      @grids(0).draw()
    else if @config.search.phase == 'refinement'
      true
    
  autoStart: ->
    @config.autoStart || true
    
  resumeSearch: ->
    if @config.search.phase == 'exploratory'
      @grids(0).draw
      @provider().fetchNextPage @config.search.keywords, @receiveResults
    else if @config.search.phase == 'refinement'
      true
    
  receiveResults: (data, page) ->
    console.log 'hi!'
    if @config.search.phase == 'exploratory'
      @grids(0).addPoints(data)
      @grids(0).draw()
      @provider().saveExploratoryResults(@grids(0).tiles.toJSON(), page, Jeocrowd.resumeSearch)
    else if @config.search.phase == 'refinement'
      true
    









