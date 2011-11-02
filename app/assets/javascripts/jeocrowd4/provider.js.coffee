# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.Provider
  
  constructor: (@name, url, search) ->
    @apiURL = window.Providers[@name].apiURL
    @params = jQuery.extend {}, window.Providers[@name].params
    @serverURL = if (q = url.indexOf '?') == -1
      url + ".js"
    else
      url.substring(0, q) + ".js" + url.substring(q)
    @pages = search.pages
    @className = 'Provider'
    
  callbacks: {}
    
  # Jeocrowd -> provider -> fetchNextPage -> <exploratory, refinement>Callback ->
  # Jeocrowd -> save<Exploratory, Refinement>Results -> 
  #             

  computeNextPage: ->
    Util.firstMissingFromRange @pages, @maxPage
    
  computeNextBox: (level) ->
    Util.firstWithZeroDegree Jeocrowd.grids(level).tiles

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
    data = @convertData(data)
    @pages[page] = page
    $('#exploratory_pages_value').text(JSON.stringify @pages)
    callback.apply Jeocrowd, [data, page]

  refinementCallback: (data, level, box, callback) ->
    total = data.photos.total
    total = parseInt total if typeof total == 'string'
    box.setDegree(total)
    $('#refinement_boxes_value').text($('#refinement_boxes_value').text() + '.')
    callback.apply Jeocrowd, [data, level, box]

  saveExploratoryResults: (results, page, callback) ->
    data = {}
    data['xpTiles'] = results
    data['page'] = page
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': data,
      'success': (data, xmlhttp, textStatus) ->
        callback.apply Jeocrowd, [data]
    }
    
  saveRefinementResults: (results, level, callback) ->
    data = {}
    data['rfTiles'] = results
    data['level'] = level
    data['phase'] = 'refinement' if level == Jeocrowd.maxLevel
    data['maxLevel'] = Jeocrowd.maxLevel if level == Jeocrowd.maxLevel
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': data,
      'success': (data, xmlhttp, textStatus) ->
        callback.apply Jeocrowd, [data]
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