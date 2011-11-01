# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005
LEVEL_MULTIPLIER = 5
COORDINATE_SEPARATOR = '^'

class window.Grid
    
  constructor: (@level) ->
    @tiles = new window.TileCollection()
    @dirty = true
    
  step: ->
    @_step ||= Math.pow(LEVEL_MULTIPLIER, @level) * BASE_GRID_STEP
      
  digitizeCoordinate: (c) ->
    c = parseFloat(c) if typeof c == 'string'
    return Math.floor((c + @step() / 1000) / @step()) / (1 / @step())

  digitizeCoordinates: (lat, lon) ->
    return @digitizeCoordinate(lat).toFixed(4) + COORDINATE_SEPARATOR + @digitizeCoordinate(lon).toFixed(4)

  addTile: (id, degree, points) ->
    tile = new Tile(@level, id)
    tile.grid = this
    tile.degree = degree if degree
    tile.points = points if points
    @tiles.add(tile)
    
  removeTile: (id) ->
    @tiles.remove(id)
    
  addPoint: (point) ->
    tile = @addTile @digitizeCoordinates(point.latitude, point.longitude)
    tile.addPoint(point)
    tile
    
  addPoints: (data) ->
    @addPoint point for point in data
      
  draw: ->
    oldGrid = Jeocrowd.grids Jeocrowd.visibleLevel()
    oldGrid.undraw()
    @tiles.each 'draw'
      
  undraw: ->
    @tiles.each 'undraw'
      
