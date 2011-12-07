# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.Grid
    
  constructor: (@level) ->
    @tiles = new window.TileCollection()
    @dirty = @level != 0
    @tilesCounter = 0
    @visibleTilesCounter = 0
    @pointsCounter = 0
    @visiblePointsCounter = 0
    @hottestTile = null
    @minVisibleDegree = 0
    @minVisibleNeighborCount = 0
    @className = 'Grid'
  
  step: ->
    @_step ?= Math.pow(Jeocrowd.LEVEL_MULTIPLIER, @level) * Jeocrowd.BASE_GRID_STEP
  
  digitizeCoordinate: (c) ->
    c = parseFloat(c) if typeof c == 'string'
    return Math.floor((c + @step() / 1000) / @step()) / (1 / @step())

  digitizeCoordinates: (lat, lon) ->
    return @digitizeCoordinate(lat).toFixed(4) + Jeocrowd.COORDINATE_SEPARATOR + @digitizeCoordinate(lon).toFixed(4)
  
  size: ->
    @tiles.size()
    
  setMinVisibleDegree: (d) ->
    @minVisibleDegree = d
  
  setMinVisibleNeighborCount: (n) ->
    @minVisibleNeighborCount = n
  
  addTile: (id, degree, points) ->
    tile = @tiles.get(id) ? new Tile(@level, id)
    tile.grid = this
    tile.setDegree(if typeof degree == 'string' then parseInt(degree) else degree) if degree
    tile.points = points if points
    if @tiles.add tile
      @tilesCounter += 1
      @visibleTilesCounter += 1 if tile.shouldDisplay()
      @pointsCounter += tile.points.length
      @visiblePointsCounter += tile.points.length if tile.shouldDisplay()
    else
      tile.existing = true
    tile
  
  removeTile: (id) ->
    tile = @tiles.get(id) 
    if @tiles.remove(id)
      @tilesCounter -= 1
      @visibleTilesCounter -= 1 if tile && tile.shouldDisplay()
    if tile
      tile.undraw()
      $('#visible_points_value').text(@visiblePointsCounter)
      $('#visible_tiles_value').text(@visibleTilesCounter)
  
  getTile: (id...) ->
    if id.length == 1
      [gridLat, gridLon] = id[0].split Jeocrowd.COORDINATE_SEPARATOR
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
  growDown: (algorithm, rejectWillBeRemoved = true) ->
    aboveGrid = Jeocrowd.grids(@level + 1)
    if rejectWillBeRemoved
      aboveGrid.tiles.reject('willBeRemoved').each('toChildren', algorithm)
    else
      aboveGrid.tiles.each('toChildren', algorithm)
    @dirty = false
    @algorithm = algorithm

  clearBeforeRefinement: (showProgress = false, callback = null) ->
    if showProgress
      ids = @tiles.filter('willBeRemoved').each('highlight2', true)
      thisGrid = this
      continueFunc = -> thisGrid.clearBeforeRefinement(false, callback)
      setTimeout continueFunc, 2000
    else
      @tiles.filter('willBeRemoved').each('highlight2', false)
      ids = @tiles.filter('willBeRemoved').map('getId')
      @removeTile id for id in ids
      callback() unless callback == null
    
  refinementPercent: ->
    s = @tiles.size()
    done = @tiles.filter('refined').size()
    done / s if s > 0

  isSparse: ->
    lonelyTilesCount = @tiles.filter('isLoner').size()
    if @size() > 0 then lonelyTilesCount / @size() > 0.75 else false

  isComplete: ->
    @tiles.map('getDegree').every( (t) -> t > 0 || Jeocrowd.MAX_NEIGHBORS <= -t <= 8)






