# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


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

  getValues: ->
    $.extend([], @values)
  
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
    for id in ids
      t = collection.collection[id]
      t = t ? new Tile(levelForNonExisting, id) if levelForNonExisting?
      @add(t)
    
  each: (func, params...) ->
    if typeof func == 'string'
      Tile.prototype[func].apply tile, params for tile in @values
    else if typeof func == 'function'
      (
        params.splice 0, 0, tile
        func.apply(tile, params)
      ) for tile in @values

  map: (func, params...) ->
    container = []
    if typeof func == 'string'
      container.push Tile.prototype[func].apply(tile, params) for tile in @values
    else if typeof func == 'function'
      container.push func.apply(tile, params) for tile in @values
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
        r = func.apply(tile, params)
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
        r = func.apply(tile, params)
        container.push tile if r
      ) for tile in @values
    container
    
  valuesOrderedBy: (func, params...) ->
    copiedValues = @getValues()
    copiedValues.sort(func)
    return copiedValues

  reject: (func, params...) ->
    container = new TileCollection()
    if typeof func == 'string'
      (
        r = Tile.prototype[func].apply(tile, params)
        container.push tile if !r
      ) for tile in @values
    else if typeof func == 'function'
      (
        r = func.apply(testTile, params)
        container.push tile if !r
      ) for tile in @values
    container

  toJSON: (keys) ->
    json = {}
    json[tile.id] = tile.toJSON(keys) for tile in @values
    json
  
  toSimpleJSON: (key) ->
    json = {}
    json[tile.id] = tile[key] for tile in @values
    json
