# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005;
LEVEL_MULTIPLIER = 5;
COORDINATE_SEPARATOR = '^';

class window.TileCollection
    
  constructor: ->
    @collection = {}
    @keys = []
    @values = []
      
  add: (tile) ->
    if !@collection[tile.id]
      i = 0
      i++ while (@keys[i] != null && @keys[i] < tile.id)
      @keys.splice i, 0, tile.id
      @values.splice i, 0, tile
      @collection[tile.id] = @values[i]
    @collection[tile.id]
    
  each: (func, params...) ->
    if typeof func == 'string'
      tile[func](params) for tile in @values
    else if typeof func == 'function'
      func(tile, params) for tile in @values

  toJSON: ->
    json = {}
    json[tile.id] = tile.toJSON(true) for tile in @values # toJSON true, to remove the id
    json
    
