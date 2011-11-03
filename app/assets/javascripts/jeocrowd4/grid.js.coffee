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
    tile.degree = (if typeof degree == 'string' then parseInt(degree) else degree) if degree
    tile.status = 'unknown' if degree == -1
    tile.points = points if points
    if @hottestTile == null || @hottestTile.degree < degree
      @hottestTile = tile
      $('#hottest_tiles_value').text(@hottestTile.id)
    if @tiles.add tile
      @tilesCounter += 1
      @visibleTilesCounter += 1 if tile.shouldDisplay()
      @pointsCounter += tile.points.length
      @visiblePointsCounter += tile.points.length if tile.shouldDisplay()
    else
      tile.existing = true
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
    grid.dirty = grid.level > 0 for grid in Jeocrowd.grids()
  
  draw: ->
    if @dirty
      if Jeocrowd.config.search.phase == 'exploratory'
        @growUp Tile.prototype.atLeastTwo
      else if Jeocrowd.config.search.phase == 'refinement'
        @addTile(id, degree) for own id, degree of Jeocrowd.config.search.rfTiles[@level]
    @tiles.each 'draw'
    $('#visible_points_value').text(@visiblePointsCounter)
    $('#visible_tiles_value').text(@visibleTilesCounter)
  
  undraw: ->
    @tiles.each 'undraw'
  
  # fills current grid with the parent tiles of the grid below
  growUp: (algorithm) ->
    belowGrid = Jeocrowd.grids(@level - 1)
    belowGrid.growUp(algorithm) if (belowGrid.dirty || belowGrid.algorithm != algorithm) && belowGrid.level > 0
    belowGrid.tiles.each 'toParent', algorithm
    @dirty = false
    @algorithm = algorithm

  # fills current grid with the children tiles of the grid above
  growDown: (algorithm) ->
    aboveGrid = Jeocrowd.grids(@level + 1)
    aboveGrid.growDown(algorithm) if (aboveGrid.dirty || aboveGrid.algorithm != algorithm) && aboveGrid.level > Jeocrowd.maxLevel
    aboveGrid.tiles.each 'toChildren', algorithm
    @dirty = false
    @algorithm = algorithm

  clearBeforeRefinement: ->
    ids = @tiles.filter('isLoner').map('getId')
    @removeTile id for id in ids
    
  refinementPercent: ->
    s = @tiles.size()
    done = @tiles.filter('refined').size()
    done / s if s > 0








