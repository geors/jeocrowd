# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Util = 
  firstMissingFromRange: (range, bound = 16) ->
    i = 0
    i++ while(i < range.length && range[i] != null)
    if i < bound
      i
    else
      null
    