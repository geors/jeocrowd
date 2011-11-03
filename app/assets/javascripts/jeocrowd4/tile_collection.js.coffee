# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005;
LEVEL_MULTIPLIER = 5;
COORDINATE_SEPARATOR = '^';

class window.TileCollection
    
  constructor: ->
    @collection = {}
    @keys = []
    @values = []
    @className = 'TileCollection'
  
  size: ->
    @values.length    
  
  get: (id) ->
    @collection[id] || null
  
  add: (tile) ->
    if tile && !@collection[tile.id]
      i = 0
      i++ while (@keys[i] != null && @keys[i] < tile.id)
      @keys.splice i, 0, tile.id
      @values.splice i, 0, tile
      @collection[tile.id] = @values[i]
      true
    else
      false
      
  push: TileCollection.prototype.add
  
  remove: (id) ->
    if @collection[id] != null 
      index = @keys.indexOf(id)
      @keys.splice index, 1
      @values.splice index, 1
      delete @collection[id]
      return true;
    else
      return false;
  
  # level for non existing is used when we want dummy tiles for all the ids supplied
  # some of them may not be found
  copyFrom: (ids, collection, levelForNonExisting) ->
    (
      if levelForNonExisting
        @add(collection.collection[id] || new Tile(levelForNonExisting, id))
      else
        @add(collection.collection[id])
    ) for id in ids
    
  each: (func, params...) ->
    if typeof func == 'string'
      Tile.prototype[func].apply tile, params for tile in @values
    else if typeof func == 'function'
      (
        params.splice 0, 0, tile
        func.apply(window, params)
      ) for tile in @values

  map: (func, params...) ->
    container = []
    if typeof func == 'string'
      container.push Tile.prototype[func].apply(tile, params) for tile in @values
    else if typeof func == 'function'
      container.push func.apply(testTile, params) for tile in @values
    container

  mapCollection: (func, params...) ->
    container = new TileCollection()
    if typeof func == 'string'
      (
        r = Tile.prototype[func].apply(tile, params)
        container.push r if r
      ) for tile in @values
    else if typeof func == 'function'
      (
        r = func.apply(testTile, params)
        container.push r if r
      ) for tile in @values
    container
    
  filter: (func, params...) ->
    container = new TileCollection()
    if typeof func == 'string'
      (
        r = Tile.prototype[func].apply(tile, params)
        container.push tile if r
      ) for tile in @values
    else if typeof func == 'function'
      (
        r = func.apply(testTile, params)
        container.push tile if r
      ) for tile in @values
    container
  
  toJSON: (options) ->
    json = {}
    json[tile.id] = tile.toJSON(options.withoutID, options.withoutPoints) for tile in @values
    json
  
  toSimpleJSON: (key) ->
    json = {}
    json[tile.id] = tile[key] for tile in @values
    json
