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

  sizeOfTile: ->
    @_sizeOfTile ?= Math.pow(Jeocrowd.LEVEL_MULTIPLIER, @level) * Jeocrowd.ACTUAL_SIZE_OF_BASE_GRID_IN_METERS
  
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
    if @dirty && Jeocrowd.config.search.phase == 'exploratory'
        @growUp Tile.prototype.atLeastTwo
    if Jeocrowd.config.search.phase == 'refinement'
      for i in [(@level + 1)..(Jeocrowd.maxLevel)]
        Jeocrowd.grids(i).tiles.filter('willBeDrawnFromHigherLevel').each('draw')
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
  # rejectWillBeRemoved parameter is used if the above grid is not refined yet
  # (usually not the case but just in case)
  growDown: (algorithm, rejectWillBeRemoved = true) ->
    aboveGrid = Jeocrowd.grids(@level + 1)
    if rejectWillBeRemoved
      aboveGrid.tiles.reject('willBeRemoved').each('toChildren', algorithm)
    else
      aboveGrid.tiles.each('toChildren', algorithm)

  clearBeforeRefinement: (showProgress = false, callback = null) ->
    if showProgress
      ids = @tiles.filter('willBeRemoved').each('highlight2', true)
      thisGrid = this
      continueFunc = -> thisGrid.clearBeforeRefinement(false, callback)
      setTimeout continueFunc, Jeocrowd.VISUALIZE_CLEARING_TIME
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
    # get the first Jeocrowd.HOT_TILES_COUNT_AVERAGE hottest tiles
    hottestTiles = @tiles.valuesOrderedBy((a, b) -> return b.degree - a.degree).splice(0, Jeocrowd.HOT_TILES_COUNT_AVERAGE)
    # calculate average distances
    averages = {}
    for i in [0..Jeocrowd.HOT_TILES_COUNT_AVERAGE - 1]
      if i + 1 < Jeocrowd.HOT_TILES_COUNT_AVERAGE
        for j in [i + 1..Jeocrowd.HOT_TILES_COUNT_AVERAGE - 1]
          averages[i + ',' + j] = google.maps.geometry.spherical.computeDistanceBetween(hottestTiles[i].getCenter(), hottestTiles[j].getCenter())
    sum = count = 0
    for id, d of averages
      sum += d
      count += 1
    avg = sum / count
    avg > Jeocrowd.TILES_APART_FOR_SPARSE_GRIDS * @sizeOfTile()
  
  isComplete: ->
    @tiles.map('getDegree').every( (t) -> t > 0 || Jeocrowd.MAX_NEIGHBORS_FOR_CORE <= -t <= 8)

  getHottestTilesAverageDegree: (force) ->
    # because hottest tile is usually off the grid in comparison to the rest, we compare the degree of a tile with the average of
    # the Jeocrowd.HOT_TILES_COUNT_AVERAGE hottest tiles in the same level
    @hottestTilesAverageDegree = null if force
    if !@hottestTilesAverageDegree?
      sortedDegrees = @tiles.map('getDegree').filter((x) -> x > 0).sort((a, b) -> return b - a)
      sum = 0
      for i in [0..Jeocrowd.HOT_TILES_COUNT_AVERAGE - 1]
        sum += sortedDegrees[i] if sortedDegrees[i]?
      @hottestTilesAverageDegree = sum / Jeocrowd.HOT_TILES_COUNT_AVERAGE
    @hottestTilesAverageDegree



