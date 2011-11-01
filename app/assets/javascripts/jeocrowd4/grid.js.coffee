# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005
LEVEL_MULTIPLIER = 5
COORDINATE_SEPARATOR = '^'

class window.Grid
    
  constructor: (@level) ->
    @tiles = new window.TileCollection()
    @dirty = @level != 0
    @tilesCounter = 0
    @visibleTilesCounter = 0
    @pointsCounter = 0
    @visiblePointsCounter = 0
    @hottestTile = null
    @className = 'Grid'
  
  step: ->
    @_step ||= Math.pow(LEVEL_MULTIPLIER, @level) * BASE_GRID_STEP
  
  digitizeCoordinate: (c) ->
    c = parseFloat(c) if typeof c == 'string'
    return Math.floor((c + @step() / 1000) / @step()) / (1 / @step())

  digitizeCoordinates: (lat, lon) ->
    return @digitizeCoordinate(lat).toFixed(4) + COORDINATE_SEPARATOR + @digitizeCoordinate(lon).toFixed(4)
  
  addTile: (id, degree, points) ->
    tile = @tiles.get(id) || new Tile(@level, id)
    tile.grid = this
    tile.degree = degree if degree
    tile.points = points if points
    @hottestTile = tile if @hottestTile == null || @hottestTile.degree < degree
    if @tiles.add tile
      @tilesCounter += 1
      @visibleTilesCounter += 1 if tile.shouldDisplay()
      @pointsCounter += tile.points.length
      @visiblePointsCounter += tile.points.length if tile.shouldDisplay()
      tile.isNew = true
    tile
  
  removeTile: (id) ->
    @tiles.remove(id)
    
  getTile: (id...) ->
    if id.length == 1
      [gridLat, gridLon] = id[0].split COORDINATE_SEPARATOR
      @tiles.get @digitizeCoordinates(parseFloat(gridLat), parseFloat(gridLon))
    else if id.length == 2
      @tiles.get @digitizeCoordinates(id[0], id[1])
  
  addPoints: (data) ->
    @addTile(@digitizeCoordinates(point.latitude, point.longitude)).addPoint(point) for point in data
    grid.dirty = true for grid in Jeocrowd.grids()
  
  draw: ->
    if @dirty
      if Jeocrowd.config.search.phase == 'exploratory'
        @growUp Tile.prototype.atLeastTwo
      else if Jeocrowd.config.search.phase == 'refinement'
        true
    @tiles.each 'draw'
    $('#visible_points_value').text(@visiblePointsCounter)
    $('#visible_tiles_value').text(@visibleTilesCounter)
  
  undraw: ->
    @tiles.each 'undraw'
  
  growUp: (algorithm) ->
    belowGrid = Jeocrowd.grids(@level - 1)
    belowGrid.growUp(algorithm) if belowGrid.dirty
    @tiles = belowGrid.tiles.mapCollection 'toParent', algorithm
  
