# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Benchmark = 
  
  list: []          # where all different benchmarks are stored
      
  start: (name) ->
    @list[name] ?= new Benchmarker(name)
    @list[name].start()
  
  finish: (name) ->
    @list[name].finish() if @list[name]?
  
    
class window.Benchmarker
      
  constructor: (@name) ->
    @running = false
    @duration = 0
    @timesInClient = []
    @timesInServer = []
    @placeholder = @name.replace(/([A-Z])/g, '_$1').toLowerCase().replace(/(exploratory|refinement)_/, '') + '_time_value'
  
  start: (force) ->
    if !force && @running
      console.log "benchmark #{@name} is already started. start with force = true to force reset timer"
      return
    @running = true
    @startTime = @now()
  
  finish: (record = true, display = true, remove = 0) ->
    @finishTime = @now()
    diff = @finishTime - @startTime - remove
    console.log 'Negative duration in benchmark! Incorrect remove time?' if diff < 0
    @timesInClient.push diff
    @duration += diff
    @running = false
    $('#' + @placeholder).text(@duration)
    @duration
    
  now: ->
    new Date().getTime()
  
