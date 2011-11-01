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
    @results = []
    
  callbacks: {}
    
  # Jeocrowd -> provider -> fetchNextPage -> 
  #             <exploratory, refinement>Callback -> save<Exploratory, Refinement>Results ->
  #             

  computeNextPage: ->
    window.Util.firstMissingFromRange(@pages, @maxPage)

  fetchNextPage: (keywords, callback) ->
    return null if (page = @computeNextPage()) == null
    @params.page = page + 1
    @params.text = keywords
    @params.jsoncallback = "Jeocrowd._provider.callbacks.exploratory_page_" + page
    @callbacks['exploratory_page_' + page] = (data) -> # called from the global namespace
      Jeocrowd.provider().exploratoryCallback data, page, callback
    try
      jQuery.getScript @apiURL + "?" + jQuery.param(@params)
    catch error
      console.log error
      @fetchNextPage keywords, callback
    
  exploratoryCallback: (data, page, callback) ->
    @results[page] = @convertData(data)
    @pages[page] = page
    callback.apply Jeocrowd, [@results[page], page]
    
  saveExploratoryResults: (results, page, callback) ->
    data = {}
    data['xpTiles'] = results
    data['page'] = page
    jQuery.ajax {
      'url': @serverURL,
      'type': 'PUT',
      'data': data,
      'success': (data, xmlhttp, textStatus) ->
        callback.apply Jeocrowd
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