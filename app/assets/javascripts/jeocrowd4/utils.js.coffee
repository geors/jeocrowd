# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Util = 
      
  firstWithTimestamp: (range, timestamp) ->
    for element, index in range
      if element == timestamp
        return index
    null
  
  firstWithNegativeDegree: (tileCollection) ->
    for element in tileCollection.values
      if element.degree < 0
        return element
    null
      
  firstWithNegativeDegreeAndLessThanNeighbors: (tileCollection, n) ->
    for element in tileCollection.values
      if element.degree < 0 && -element.degree < n
        return element
    null
    
  lastMissingFromRange: (range) ->
    return null if range.length == 0
    for i in [(range.length - 1)..0]
      return i if range[i] == null
    null

  createDelegate: (object, method, params...) ->
    shim = ->
      method.apply object, params
