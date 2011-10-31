# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.Provider
  
  constructor: (@name) ->
    @apiURL = window.Providers[@name].apiURL
    @params = jQuery.extend {}, window.Providers[@name].params
    
  callbacks: {}
  
  pages: {}
  
  fetchNextPage: (keywords, page, callback) ->
    @callbacks['exploratory_page_' + page] = (data) -> # called from the global namespace
      Jeocrowd.provider().exploratoryCallback data, page, callback
    @params.jsoncallback = "Jeocrowd._provider.callbacks.exploratory_page_" + page
    @params.text = keywords
    @params.page = page + 1
    try
      jQuery.getScript @apiURL + "?" + jQuery.param(@params)
    catch error
      console.log error
      @fetchNextPage keywords, page
    
  exploratoryCallback: (data, page, callback) ->
    @pages[page] = @convertData(data)
    callback.apply Jeocrowd, [@pages[page], page]
    
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