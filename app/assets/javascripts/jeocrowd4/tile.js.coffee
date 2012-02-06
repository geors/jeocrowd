# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.Tile
    
  constructor: (@level, id...) ->
    @grid = Jeocrowd.grids(@level)
    if id.length == 1
      @id = id[0]
      [@gridLat, @gridLon] = id[0].split Jeocrowd.COORDINATE_SEPARATOR
      @gridLat = @grid.digitizeCoordinate(parseFloat @gridLat)
      @gridLon = @grid.digitizeCoordinate(parseFloat @gridLon)
    else if id.length == 2
      @id = id[0] + '^' + id[1]
      @gridLat = @grid.digitizeCoordinate(if typeof id[0] == 'string' then parseFloat id[0] else id[0])
      @gridLon = @grid.digitizeCoordinate(if typeof id[1] == 'string' then parseFloat id[1] else id[1])
    @degree = 0
    @points = []
    @className = 'Tile'
  
  getId: ->
    @id
    
  getIdAndDegree: ->
    @id + ': ' + @degree
  
  sanitizedId: ->
    @id.replace(/[^0-9A-Za-z]/g, '_')
    
  linkTo: ->
    '<a href="#' + @id + '" class="pan_map_to_href">' + @id + '</a>'
    
  toJSON: (keys) ->
    json = {}
    for own key in keys
      json[key] = this[key]
    json
    
  toSimpleJSON: (keys) ->
    json = {}
    if keys.length == 1
      json[@id] = this[keys[0]]
    else
      json[@id] = @toJSON(keys)
    json
      
  addPoint: (point) ->
    if @points.indexOf point.url == -1
      @points.push point.url
      @setDegree @degree + 1
      true
    else
      false
      
  getDegree: ->
    @degree
        
  setDegree: (degree) ->
    if @grid.hottestTile == null || @grid.hottestTile.degree < degree
      @grid.hottestTile = this 
      $('#hottest_tiles_value').html(@linkTo())
      $('#hottest_tiles_degree_value').text(degree)
      @grid.getHottestTilesAverageDegree(true)
    @degree = degree
    
  refined: ->
    @degree > 0
  
  #
  # ---- ---- VISUAL DESIGN ---- ----
  #
  getBoundingBox: ->
    if !@boundingBox
      addMe = @grid.step() + @grid.step() / 2;
      @boundingBox = {
        top:    @grid.digitizeCoordinate(@gridLat + addMe),
        bottom: @gridLat,
        left:   @gridLon,
        right:  @grid.digitizeCoordinate(@gridLon + addMe)
      }
    @boundingBox;

  getBoundingBoxString: ->
    box = @getBoundingBox();
    [box.left, box.bottom, box.right, box.top].join()
  
  getCenter: ->
    box = @getBoundingBox();
    new google.maps.LatLng(box.bottom + this.grid.step() / 2, box.left + this.grid.step() / 2)
  
  draw: ->
    if @visual
      @visual.setOptions {
        strokeColor: @getColor(),
        strokeWeight: if @willBeDrawnFromHigherLevel() then 0 else 1,
        fillColor: @getColor(),
        fillOpacity: @getOpacity()
      }
    else
      pathPoints = [
        new google.maps.LatLng @getBoundingBox().top,     @getBoundingBox().left
        new google.maps.LatLng @getBoundingBox().top,     @getBoundingBox().right
        new google.maps.LatLng @getBoundingBox().bottom,  @getBoundingBox().right
        new google.maps.LatLng @getBoundingBox().bottom,  @getBoundingBox().left
      ]
      @visual = new google.maps.Polygon {
        paths: pathPoints,
        strokeColor: @getColor(),
        strokeOpacity: 0.8,
        strokeWeight: if @willBeDrawnFromHigherLevel() then 0 else 1,
        fillColor: @getColor(),
        fillOpacity: @getOpacity(),
        zIndex: 10
      }
      google.maps.event.addListener(@visual, 'click', Util.createDelegate(this, Tile.prototype.visualClicked));
    if @shouldDisplay()
      @visual.setMap Jeocrowd.map
    else
      @visual.setMap null
      
  drawNeighborhood: ->
    @draw()
    @getNeighbors().each 'draw'
    
  visualClicked: ->
    @grid.selectedTile = this
    $('#selected_tile_value').html(@linkTo())
    $('#selected_tile_degree_value').text(@degree)
    $('#selected_tile_neighbors_value').text(@getNeighborCount())

    
  highlight: (display) ->
    return if @isHighlighted1 == display
    @visualBounds = @visualBounds ? new google.maps.Rectangle({
      bounds: new google.maps.LatLngBounds(
        new google.maps.LatLng(@getBoundingBox().bottom, @getBoundingBox().left),
        new google.maps.LatLng(@getBoundingBox().top, @getBoundingBox().right)
      ),
      fillOpacity: 0,
      zIndex: 20
    })
    @visualBounds.setMap(if display then Jeocrowd.map else null)
    @isHighlighted1 = display

    
  highlight2: (display) ->
    return if @isHighlighted2 == display
    @visualCross1 = @visualCross1 ? new google.maps.Polygon({
      paths: [
        new google.maps.LatLng(@getBoundingBox().top, @getBoundingBox().left),
        new google.maps.LatLng(@getBoundingBox().bottom, @getBoundingBox().right)
      ],
      strokeOpacity: 0.8,
      strokeWeight: 1,
      fillOpacity: 0,
      zIndex: 20
    })
    @visualCross2 = @visualCross2 ? new google.maps.Polygon({
      paths: [
        new google.maps.LatLng(this.getBoundingBox().top, this.getBoundingBox().right),
        new google.maps.LatLng(this.getBoundingBox().bottom, this.getBoundingBox().left)
      ],
      strokeOpacity: 0.8,
      strokeWeight: 1,
      fillOpacity: 0,
      zIndex: 20
    })
    if display
      @visualCross1.setMap Jeocrowd.map
      @visualCross2.setMap Jeocrowd.map
    else
      @visualCross1.setMap null
      @visualCross2.setMap null
    @isHighlighted2 = display
    

  undraw: ->
    @visual.setMap(null) if @visual


  getColor: ->
    if @willBeDrawnFromHigherLevel()
      '#1E719F'
    else if @degree < 0
      '#BBBBBB'
    else if Jeocrowd.visibleLayer() == 'degree'
      '#FF0000'
    else
      switch @getNeighborCount()
        when 0 then return '#CCFFFF'
        when 1 then return '#66FFCC'
        when 2 then return '#66FF66'
        when 3 then return '#FFFF66'
        when 4 then return '#FFCC00'
        when 5 then return '#FF9900'
        when 6 then return '#FF3300'
        when 7 then return '#FF0000'
        when 8 then return '#CC0000'
    
  getOpacity: ->
    if @degree < 0
      0.5
    else if Jeocrowd.visibleLayer() == 'degree'
      if @degree > 500
        1
      else
        @degree / 500.0
    else
      0.75

  shouldDisplay: ->
    @degree < 0 || (@grid.minVisibleDegree <= @degree && @grid.minVisibleNeighborCount <= @getNeighborCount())
  
  #
  # ---- ---- NEIGHBORS ---- ----
  #

  getNeighborIds: ->
    if @neighborIds == undefined
      addMe = @grid.step() + (@grid.step() / 2)
      subMe = @grid.step() / 2
      topLeft      = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon - subMe
      top          = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon     
      topRight     = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon + addMe
      right        = @grid.digitizeCoordinates @gridLat,          @gridLon + addMe
      bottomRight  = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon + addMe
      bottom       = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon
      bottomLeft   = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon - subMe
      left         = @grid.digitizeCoordinates @gridLat,          @gridLon - subMe
      @neighborIds = [topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left]
    @neighborIds


  getSquareNeighborIds: ->
    if @squareNeighborIds == undefined
      n = @getNeighborIds()
      @squareNeighborIds = [n[1], n[3], n[5], n[7]]
    @squareNeighborIds

  getNeighbors: (force) ->
    @neighbors = new TileCollection()
    @neighbors.copyFrom @getNeighborIds(), @grid.tiles, if force then @grid.level else null
    @neighbors = @neighbors.filter 'refined'           # do not include neighbors with zero degree

  getSquareNeighbors: (force) ->
    @squareNeighbors = new TileCollection()
    @squareNeighbors.copyFrom @getSquareNeighborIds(), @grid.tiles, if force then @grid.level else null
    @squareNeighbors.filter 'refined'     # do not include neighbors with zero degree


  getNeighborCount: ->
    s = @getNeighbors().size()
    # since during refinement we do NOT copy fully occupied tiles to the level below
    # but we keep them only in the above levels we have to account for that fact when
    # we count the neighbors!    # 
    if Jeocrowd.config.search.phase == 'refinement'
      existingNeighborIds = @getNeighbors().map('getId')
      missingNeighborIds = @getNeighborIds().filter((x) -> existingNeighborIds.indexOf(x) == -1)
      for ct in missingNeighborIds
        # console.log ct
        if @grid.level + 1 <= Jeocrowd.maxLevel - 1 
          for i in [(@grid.level + 1)..(Jeocrowd.maxLevel - 1)]
            if t = Jeocrowd.grids(i).getTile(ct)
              s += 1 if t.willBeDrawnFromHigherLevel()
              # console.log s
              break
    s

  isLoner: ->
    @getNeighbors().size() == 0
    
  willBeRemoved: ->
    # we cannot eliminate a tile just because it is alone, this might discard some small areas or point features
    # that even at a high level only one tile was left, or even multi clusters, ie. a few loner tiles were left
    @degree > 0 && ((@isLoner() && @degree < 0.5 * @grid.hottestTilesAverageDegree) || 
      @degree < Jeocrowd.THRESHOLD_FOR_REMOVAL * @grid.hottestTilesAverageDegree)
    
  fullyOccupied: ->
    @getNeighborCount() >= Jeocrowd.MAX_NEIGHBORS
    
  willBeDrawnFromHigherLevel: ->
    !@willBeRemoved() && @fullyOccupied() && !Jeocrowd.searchEverything(@grid.level) && @level > Jeocrowd.visibleLevel()
  
  # 
  # ---- ---- PARENTS, CHILDREN and SIBLINGS ---- ----
  # 
  
  # functions that allow transition either when grow up -> make parents
  # or when growing down -> make children
  # available functions:
  # always:
  # notFull: neighbors are beign counted after the parent grid has been refined
  # atLeastOne:
  # atLeastTwo:
  
  always: ->
    true
  
  notFull: ->
    Jeocrowd.searchEverything(@grid.level) ||
        (!Jeocrowd.searchEverything(@grid.level) && !@fullyOccupied())
  
  atLeastOne: ->
    @getSiblings().size() >= 1

  atLeastTwo: ->
    @getSiblings().size() >= 2

  toParent: (algorithm) ->
    if algorithm.apply this # algorithm used to decide growing up or not, eg atLeastOne, atLeastTwo... etc...
      degree = 0
      points = []
      @getSiblings().each (child) ->
        degree += child.degree;
        points.push point for point in child.points
      aboveGrid = Jeocrowd.grids(@grid.level + 1)
      aboveGrid.addTile aboveGrid.digitizeCoordinates(@gridLat, @gridLon), degree, points
    else
      null
  
  toChildren: (algorithm) ->
    childDegree = -1        # use this fake degree for tiles that
    if algorithm.apply this # algorithm used to decide growing down or not, eg always...
      belowGrid = Jeocrowd.grids @grid.level - 1
      # children given -parentNeighborCount as initial degree
      belowGrid.addTile child.id, childDegree for child in @getChildren(true).values
    else
      null
  
  getParent: (force) ->
    aboveGrid = Jeocrowd.grids @grid.level + 1
    parentId = aboveGrid.digitizeCoordinates(@gridLat, @gridLon)
    parent = aboveGrid.getTile parentId
    if force && parent == null
      parent = new Tile aboveGrid.level, parentId
    parent
    
  getChildrenIds: (force) ->
    return null if @grid.level == 0
    belowGrid = Jeocrowd.grids @grid.level - 1
    if @allChildrenIds == undefined
      @allChildrenIds = []
      vChild = new Tile belowGrid.level, @gridLat, @gridLon
      for vChildId in vChild.getVerticalNeighborIds Jeocrowd.LEVEL_MULTIPLIER - 1
        [lat, lon] = vChildId.split Jeocrowd.COORDINATE_SEPARATOR
        hChild = new Tile belowGrid.level, lat, lon
        @allChildrenIds.push hChildId for hChildId in hChild.getHorizontalNeighborIds Jeocrowd.LEVEL_MULTIPLIER - 1
    @childrenIds = @allChildrenIds.map (id, index, ids) ->
      if belowGrid.getTile(id) || force then id else null
    
  getChildren: (force) ->
    @children = new TileCollection()
    @children.copyFrom @getChildrenIds(force), Jeocrowd.grids(@level - 1).tiles, if force then (@grid.level - 1) else null
    @children
    
  getSiblingsIds: (force) ->
    @getParent(true).getChildrenIds(force)
    
  getSiblings: (force) ->
    @siblings = new TileCollection()
    @siblings.copyFrom @getSiblingsIds(force), @grid.tiles, if force then @grid.level else null
    @siblings
    
  getVerticalNeighborIds: (afar) ->
    @grid.digitizeCoordinates(@gridLat + @grid.step() * i + @grid.step() / 2, @gridLon) for i in [0..afar]
  
  getHorizontalNeighborIds: (afar) ->
    @grid.digitizeCoordinates(@gridLat, @grid.step() * i + @grid.step() / 2 + @gridLon) for i in [0..afar]

  








