# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Util = 
  firstMissingFromRange: (range, bound = 16) ->
    i = 0
    i++ while(i < range.length && range[i] != null)
    if i < bound
      i
    else
      null
    
  lastMissingFromRange: (range) ->
    return null if range.length == 0
    i = range.length - 1
    i-- while(i >= 0 && range[i] != null)
    i
    
    
  firstWithZeroDegree: (tileCollection) ->
    i = 0
    i++ while tileCollection.values[i] != null && tileCollection.values[i].degree != 0
    tileCollection.values[i]