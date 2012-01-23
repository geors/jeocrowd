# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.Benchmark = 
  
  list: {}          # where all different benchmarks are stored
  reportURL: null
      
  create: (name) ->
    @list[name] = new Benchmarker(name)
      
  start: (name) ->
    @list[name] ?= new Benchmarker(name)
    @list[name].start()
  
  finish: (name) ->
    @list[name].finish() if @list[name]?
  
  retrieve: (name) ->
    name = name.replace(/Time$/, '')
    name = name.replace(/^E/, 'e')
    name = name.replace(/^R/, 'r')
    @list[name]
  
  publish: ->
    return if !Jeocrowd.running()
    times = {}
    for key, b of @list
      times[b.serverName] = b.unpublishedDuration() unless b.serverName.indexOf('server') >= 0
      b.clearClientTimes()
    console.log 'publish benchmarks...'
    jQuery.ajax {
      'url': Benchmark.reportURL,
      'type': 'PUT',
      'data': {'benchmarks': times},
      'dataType': 'json',
      'success': (data, xmlhttp, textStatus) =>
        if data.benchmarks
          for name, duration of data.benchmarks
            b = @retrieve(name)
            b.timeInServer = duration
            b.display()
      'complete': (jqXHR, textStatus) =>
        console.log textStatus if textStatus != 'success'
    }
    
  setupPublishing: (interval) ->
    setInterval =>
      @publish()
    , interval
    
class window.Benchmarker
      
  constructor: (@name) ->
    @running = false
    @duration = 0
    @timesInClient = []
    @timeInServer = 0
    @serverName = @name.replace(/([A-Z])/g, '_$1').toLowerCase() + '_time'
    @placeholder = @serverName.replace(/(?:exploratory|refinement)_/, '') + '_value'
  
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
    @display()
    @duration
    
  display: ->
    $('#' + @placeholder).text("#{@duration}/#{@timeInServer}")
    
  unpublishedDuration: ->
    sum = 0
    sum += d for d in @timesInClient
    sum
    
  clearClientTimes: ->
    @timesInClient = []
    
  now: ->
    new Date().getTime()
  
