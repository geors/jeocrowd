# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.Provider
  
  constructor: (@name, url, search, @timestamp) ->
    @apiURL = window.Providers[@name].apiURL
    @params = jQuery.extend {}, window.Providers[@name].params
    @serverURL = if (q = url.indexOf '?') == -1
      url + '.js'
    else
      url.substring(0, q) + '.js' + url.substring(q)
    @pages = search.pages
    @className = 'Provider'
    
  callbacks: {}
    
  # Jeocrowd -> provider -> fetchNextPage -> <exploratory, refinement>Callback ->
  # Jeocrowd -> save<Exploratory, Refinement>Results -> 

  updatePages: (page) ->
    if typeof page == 'number'
      @pages[page] = page
    else if typeof page == 'object'
      @pages = page
    $('#exploratory_pages_value').text(JSON.stringify @pages)
    
  allPagesCompleted: ->
    @pages.length == Jeocrowd.MAX_XP_PAGES && @pages.every((page) -> page < Jeocrowd.MAX_XP_PAGES)

  noPagesForMe: ->
    t = @timestamp
    @pages.length == Jeocrowd.MAX_XP_PAGES &&
      @pages.filter((page) -> page > Jeocrowd.MAX_XP_PAGES).every((page) -> page != t)

  computeNextPage: ->
    Util.firstWithTimestamp @pages, @timestamp
  
  updateAssignedTiles: (tiles, level) ->
    t = @timestamp
    @assignedTiles = (if tiles? then tiles else null) # makes undefined -> null
    if tiles?
      @assignedTilesCollection = new TileCollection()
      @assignedTilesCollection.copyFrom @assignedTiles, Jeocrowd.grids(level).tiles
      @assignedTilesCollection.each(-> @degree = -t)
    @assingedTiles
    
  allBoxesCompleted: (level) ->
    Jeocrowd.grids(level).tiles.filter(-> @degree < 0).size() == 0
    
  noBoxForMe: (level) ->
    t = @timestamp
    console.log 'no box...'
    console.log Jeocrowd.grids(level).tiles.filter(-> @degree == -t)
    Jeocrowd.grids(level).tiles.filter(-> @degree == -t).size() == 0
  
  continueRefinementBlock: ->
    @assignedTiles.length > 0
  
  computeNextBox: (level) ->
    # returns the first element of the array and removes it from the assignedTiles list
    result = if @assignedTiles? then @assignedTiles.splice(0, 1) else null

  exploratorySearch: (keywords, callback) ->
    return null if (page = @computeNextPage()) == null
    @params.page = page + 1
    @params.text = keywords
    @params.jsoncallback = 'Jeocrowd._provider.callbacks.exploratory_page_' + page
    @callbacks['exploratory_page_' + page] = (data) -> # called from the global namespace
      Jeocrowd.provider().exploratoryCallback data, page, callback
    try
      jQuery.getScript @apiURL + "?" + jQuery.param(@params)
      true
    catch error
      console.log error
      @exploratorySearch keywords, callback
    
  refinementSearch: (keywords, level, callback) ->
    return null if (box = @computeNextBox(level)) == null
    if box.length == 0
      callback.apply Jeocrowd, [null, level, null]
    else
      box = Jeocrowd.grids(level).getTile box[0] # returned array from computeNextBox
    $('#current_input_tile_value').html(box.linkTo())
    Jeocrowd.map.panTo box.getCenter() if $('#pan_map:checked[value=input]').length > 0
    @params.bbox = box.getBoundingBoxString()
    @params.text = keywords
    @params.per_page = 1
    @params.jsoncallback = 'Jeocrowd._provider.callbacks.refinement_level_' + level + '_box_' + box.sanitizedId()
    @callbacks['refinement_level_' + level + '_box_' + box.sanitizedId()] = (data) -> # called from the global namespace
      Jeocrowd.provider().refinementCallback data, level, box, callback
    try
      jQuery.getScript @apiURL + "?" + jQuery.param(@params)
      true
    catch error
      console.log error
      @exploratorySearch keywords, callback

  exploratoryCallback: (data, page, callback) ->
    newData = @convertData(data)
    @updatePages(page)
    $('#available_points_value').text(data.photos.total)
    @saveTotalAvailablePoints(data.photos.total) if page == 0   # change this to save if not already saved
    callback.apply Jeocrowd, [newData, page]

  refinementCallback: (data, level, box, callback) ->
    total = data.photos.total
    total = parseInt total if typeof total == 'string'
    box.setDegree total
    $('#refinement_boxes_value').text((Jeocrowd.grids(level).refinementPercent() * 100).toFixed(2) + '%')
    callback.apply Jeocrowd, [data, level, box]

  saveExploratoryResults: (results, page, callback) ->
    data = {}
    data['xpTiles'] = results
    data['page'] = page
    data['timestamp'] = @timestamp
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': data,
      'dataType': 'json',
      'success': (data, xmlhttp, textStatus) ->
        callback.apply Jeocrowd, [data]
      'complete': (jqXHR, textStatus) ->
        console.log textStatus if textStatus != 'success'
    }
    
  saveRefinementResults: (results, level, callback) ->
    data = {}
    data['rfTiles'] = results
    data['level'] = level
    if level + 1 == Jeocrowd.maxLevel
      data['phase'] = 'refinement' 
      data['maxLevel'] = Jeocrowd.maxLevel
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': data,
      'dataType': 'json',
      'success': (data, xmlhttp, textStatus) ->
        callback.apply Jeocrowd, [data]
      'complete': (jqXHR, textStatus) ->
        console.log textStatus if textStatus != 'success'
    }

  saveTotalAvailablePoints: (total) ->
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': {'total_available_points': total}
    }
  
  convertData: (data) ->
    points = data.photos.photo.map (p) ->
      point = {}
      point.latitude = p.latitude
      point.longitude = p.longitude
      point.title = p.title
      point.url = "http://farm" + p.farm + ".static.flickr.com/" + p.server + "/" + p.id + "_" + p.secret + ".jpg"
      point
    
# different providers for later expansion
    
window.Providers =
  Flickr: {
    apiURL: "http://api.flickr.com/services/rest/",
    params: {
      method:   "flickr.photos.search",
      api_key:  "656222a441d1f6305791eeee478796d0",
      has_geo:  true,
      accuracy: 12,
      extras:   "geo",
      sort:     "date-posted-desc",
      format:   "json"
    }
  }