# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Jeocrowd = 
  config: {'search': {}, 'ui': {}}
  
  _grids: null
  grids: (level) ->
    @_grids ||= [0..6].map (i) ->
      new window.Grid(i)
    if level != null
      @_grids[level]
    else
      @_grids
  
  _provider : null
  provider: ->
    @_provider ||= new window.Provider 'Flickr'
  
  _visibleLayer: 'degree'
  visibleLayer: (layer) ->
    if layer
      @_visibleLayer = layer
    else
      @_visibleLayer

  _visibleLevel: 0
  visibleLevel: (level) ->
    if level
      @_visibleLevel = level
    else
      @_visibleLevel

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
    
  autoStart: ->
    @config.autoStart || true
    
  resumeSearch: ->
    if @config.search.phase == 'exploratory'
      @grids(0).draw if @grids(0) && @grids(0).dirty
      @provider().fetchNextPage @config.search.keywords, window.Util.firstMissingFromRange(@config.search.pages), @receiveResults
    else if @config.search.phase == 'refinement'
      @grids(0)[@config.search.level].draw if @config.search.level && @grids(0)[@config.search.level]
      @provider().fetchNextBox @config.search.keywords
    
  receiveResults: (data, page) ->
    console.log 'hi!'
    if @config.search.phase == 'exploratory'
      @grids(0).addPoints(data)
      @grids(0).draw()
      #@resumeSearch() if @autoStart()
    else if @config.search.phase == 'refinement'
      'dfs'
    









