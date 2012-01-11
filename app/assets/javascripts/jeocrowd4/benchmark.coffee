# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Benchmark = 
  
  list: []
  
  timesheet: null
    
  start: (name) ->
    @list[name] ?= new Benchmarker(name, @timesheet)
    @list[name].start()
  
  finish: (name) ->
    @list[name].finish() if @list[name]?
  
    
class window.Benchmarker
      
  constructor: (@name, @timesheet) ->
    @running = false
    @duration = 0
  
  start: (force) ->
    if !force && @running
      console.log "benchmark #{@name} is already started. start with force = true to force reset timer"
      return
    @running = true
    @startTime = @now()
  
  finish: (record = true) ->
    @finishTime = @now()
    @duration += @finishTime - @startTime
    @timesheet[@name] = @duration if record
    @running = false
    @duration
    
  now: ->
    new Date().getTime()
  
